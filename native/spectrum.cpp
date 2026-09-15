#include <algorithm>
#include <array>
#include <cerrno>
#include <cmath>
#include <complex>
#include <csignal>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <limits>
#include <numbers>
#include <string_view>
#include <sys/prctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

namespace {

constexpr std::size_t channelCount = 2;
constexpr std::size_t fftSize = 2048;
constexpr std::size_t bandCount = 32;
constexpr std::size_t hopSize = 1600;
constexpr float sampleRate = 48000.0F;
constexpr float minimumFrequency = 50.0F;
constexpr float maximumFrequency = 12000.0F;
constexpr float minimumDecibels = -72.0F;
constexpr float maximumDecibels = -12.0F;

volatile std::sig_atomic_t stopRequested = 0;
volatile std::sig_atomic_t captureProcessId = -1;

void handleSignal(int) {
	stopRequested = 1;
	const auto processId = static_cast<pid_t>(captureProcessId);
	if (processId > 0) kill(processId, SIGTERM);
}

bool installSignalHandlers() {
	struct sigaction action {};
	action.sa_handler = handleSignal;
	sigemptyset(&action.sa_mask);
	action.sa_flags = 0;

	return sigaction(SIGINT, &action, nullptr) == 0
		&& sigaction(SIGTERM, &action, nullptr) == 0
		&& sigaction(SIGHUP, &action, nullptr) == 0
		&& sigaction(SIGPIPE, &action, nullptr) == 0;
}

class SpectrumAnalyzer {
public:
	using Samples = std::array<float, fftSize>;
	using Bands = std::array<float, bandCount>;

	SpectrumAnalyzer() {
		for (std::size_t index = 0; index < fftSize; ++index) {
			window_[index] = 0.5F * (1.0F - std::cos(
				2.0F * std::numbers::pi_v<float> * static_cast<float>(index)
				/ static_cast<float>(fftSize - 1)));
		}
	}

	Bands analyze(const Samples& samples) {
		for (std::size_t index = 0; index < fftSize; ++index) {
			fft_[index] = std::complex<float>(samples[index] * window_[index], 0.0F);
		}

		transform();

		Bands bands {};
		for (std::size_t band = 0; band < bandCount; ++band) {
			const float lowerFrequency = bandFrequency(band);
			const float upperFrequency = bandFrequency(band + 1);
			const std::size_t firstBin = std::max<std::size_t>(1,
				static_cast<std::size_t>(std::floor(
					lowerFrequency * static_cast<float>(fftSize) / sampleRate)));
			const std::size_t lastBin = std::min<std::size_t>(fftSize / 2,
				std::max(firstBin + 1, static_cast<std::size_t>(std::ceil(
					upperFrequency * static_cast<float>(fftSize) / sampleRate))));

			float magnitude = 0.0F;
			for (std::size_t bin = firstBin; bin < lastBin; ++bin) {
				magnitude = std::max(magnitude, std::abs(fft_[bin]));
			}

			magnitude *= 4.0F / static_cast<float>(fftSize);
			const float decibels = 20.0F * std::log10(std::max(
				magnitude, std::numeric_limits<float>::epsilon()));
			bands[band] = std::clamp(
				(decibels - minimumDecibels) / (maximumDecibels - minimumDecibels),
				0.0F, 1.0F);
		}

		return bands;
	}

	static std::size_t bandForFrequency(float frequency) {
		const float normalized = std::log(frequency / minimumFrequency)
			/ std::log(maximumFrequency / minimumFrequency);
		return std::min<std::size_t>(bandCount - 1,
			static_cast<std::size_t>(std::floor(normalized * bandCount)));
	}

private:
	static float bandFrequency(std::size_t boundary) {
		const float position = static_cast<float>(boundary)
			/ static_cast<float>(bandCount);
		return minimumFrequency * std::pow(
			maximumFrequency / minimumFrequency, position);
	}

	void transform() {
		for (std::size_t source = 1, target = 0; source < fftSize; ++source) {
			std::size_t bit = fftSize >> 1;
			for (; target & bit; bit >>= 1) target ^= bit;
			target ^= bit;
			if (source < target) std::swap(fft_[source], fft_[target]);
		}

		for (std::size_t length = 2; length <= fftSize; length <<= 1) {
			const float angle = -2.0F * std::numbers::pi_v<float>
				/ static_cast<float>(length);
			const std::complex<float> step(std::cos(angle), std::sin(angle));

			for (std::size_t offset = 0; offset < fftSize; offset += length) {
				std::complex<float> factor(1.0F, 0.0F);
				for (std::size_t index = 0; index < length / 2; ++index) {
					const auto even = fft_[offset + index];
					const auto odd = fft_[offset + index + length / 2] * factor;
					fft_[offset + index] = even + odd;
					fft_[offset + index + length / 2] = even - odd;
					factor *= step;
				}
			}
		}
	}

	std::array<float, fftSize> window_ {};
	std::array<std::complex<float>, fftSize> fft_ {};
};

class AudioWindow {
public:
	bool push(float sample) {
		if (!std::isfinite(sample)) sample = 0.0F;
		samples_[writeIndex_] = std::clamp(sample, -1.0F, 1.0F);
		writeIndex_ = (writeIndex_ + 1) % fftSize;
		totalSamples_++;
		samplesSinceOutput_++;

		if (totalSamples_ < fftSize || samplesSinceOutput_ < hopSize) return false;
		samplesSinceOutput_ = 0;
		return true;
	}

	SpectrumAnalyzer::Samples orderedSamples() const {
		SpectrumAnalyzer::Samples ordered {};
		for (std::size_t index = 0; index < fftSize; ++index) {
			ordered[index] = samples_[(writeIndex_ + index) % fftSize];
		}
		return ordered;
	}

private:
	SpectrumAnalyzer::Samples samples_ {};
	std::size_t writeIndex_ = 0;
	std::size_t totalSamples_ = 0;
	std::size_t samplesSinceOutput_ = 0;
};

class CaptureProcess {
public:
	bool start() {
		int pipeDescriptors[2] {};
		if (pipe(pipeDescriptors) != 0) {
			std::cerr << "spectrum: unable to create capture pipe: "
				<< std::strerror(errno) << '\n';
			return false;
		}

		processId_ = fork();
		if (processId_ < 0) {
			std::cerr << "spectrum: unable to start pw-record: "
				<< std::strerror(errno) << '\n';
			close(pipeDescriptors[0]);
			close(pipeDescriptors[1]);
			return false;
		}

		if (processId_ == 0) {
			close(pipeDescriptors[0]);
			if (dup2(pipeDescriptors[1], STDOUT_FILENO) < 0) _exit(126);
			close(pipeDescriptors[1]);
			prctl(PR_SET_PDEATHSIG, SIGTERM);

			execlp("pw-record", "pw-record",
				"--raw",
				"--format=f32",
				"--rate=48000",
				"--channels=2",
				"--channel-map=stereo",
				"--latency=1024",
				"--properties={\"stream.capture.sink\":true,\"node.virtual\":true}",
				"-",
				static_cast<char*>(nullptr));
			std::cerr << "spectrum: unable to execute pw-record: "
				<< std::strerror(errno) << '\n';
			_exit(127);
		}

		close(pipeDescriptors[1]);
		readDescriptor_ = pipeDescriptors[0];
		captureProcessId = processId_;
		return true;
	}

	int descriptor() const {
		return readDescriptor_;
	}

	int stop() {
		if (readDescriptor_ >= 0) {
			close(readDescriptor_);
			readDescriptor_ = -1;
		}

		if (processId_ <= 0) return 0;
		if (kill(processId_, SIGTERM) != 0 && errno != ESRCH) {
			std::cerr << "spectrum: unable to stop pw-record: "
				<< std::strerror(errno) << '\n';
		}

		int status = 0;
		while (waitpid(processId_, &status, 0) < 0 && errno == EINTR) {}
		processId_ = -1;
		captureProcessId = -1;
		return status;
	}

	~CaptureProcess() {
		stop();
	}

private:
	pid_t processId_ = -1;
	int readDescriptor_ = -1;
};

bool emitBands(const SpectrumAnalyzer::Bands& bands) {
	for (std::size_t index = 0; index < bands.size(); ++index) {
		if (index > 0) std::cout << ';';
		std::cout << static_cast<int>(std::lround(bands[index] * 1000.0F));
	}
	std::cout << '\n' << std::flush;
	return std::cout.good();
}

int runSelfTest() {
	SpectrumAnalyzer analyzer;
	SpectrumAnalyzer::Samples silence {};
	const auto silentBands = analyzer.analyze(silence);
	if (*std::max_element(silentBands.begin(), silentBands.end()) != 0.0F) {
		std::cerr << "spectrum self-test: silence produced non-zero bands\n";
		return 1;
	}

	constexpr float testFrequency = 440.0F;
	SpectrumAnalyzer::Samples tone {};
	for (std::size_t index = 0; index < tone.size(); ++index) {
		tone[index] = 0.5F * std::sin(2.0F * std::numbers::pi_v<float>
			* testFrequency * static_cast<float>(index) / sampleRate);
	}

	const auto toneBands = analyzer.analyze(tone);
	const auto peak = std::max_element(toneBands.begin(), toneBands.end());
	const std::size_t peakBand = static_cast<std::size_t>(
		std::distance(toneBands.begin(), peak));
	const std::size_t expectedBand = SpectrumAnalyzer::bandForFrequency(testFrequency);
	const std::size_t bandDistance = peakBand > expectedBand
		? peakBand - expectedBand : expectedBand - peakBand;
	if (bandDistance > 1 || *peak < 0.5F) {
		std::cerr << "spectrum self-test: 440 Hz tone mapped to band "
			<< peakBand << " instead of " << expectedBand << '\n';
		return 1;
	}

	std::cout << "Spectrum helper self-test passed.\n";
	return 0;
}

int runCapture() {
	if (!installSignalHandlers()) {
		std::cerr << "spectrum: unable to install signal handlers\n";
		return 1;
	}

	CaptureProcess capture;
	if (!capture.start()) return 1;

	SpectrumAnalyzer analyzer;
	AudioWindow audioWindow;
	std::array<std::byte, 16384> readBuffer {};
	std::vector<std::byte> pendingBytes;
	pendingBytes.reserve(readBuffer.size() + channelCount * sizeof(float));

	while (!stopRequested) {
		const ssize_t bytesRead = read(capture.descriptor(),
			readBuffer.data(), readBuffer.size());
		if (bytesRead == 0) break;
		if (bytesRead < 0) {
			if (errno == EINTR) continue;
			std::cerr << "spectrum: unable to read captured audio: "
				<< std::strerror(errno) << '\n';
			break;
		}

		pendingBytes.insert(pendingBytes.end(), readBuffer.begin(),
			readBuffer.begin() + bytesRead);
		constexpr std::size_t frameSize = channelCount * sizeof(float);
		const std::size_t completeBytes = pendingBytes.size()
			- pendingBytes.size() % frameSize;

		for (std::size_t offset = 0; offset < completeBytes; offset += frameSize) {
			float left = 0.0F;
			float right = 0.0F;
			std::memcpy(&left, pendingBytes.data() + offset, sizeof(float));
			std::memcpy(&right, pendingBytes.data() + offset + sizeof(float),
				sizeof(float));
			if (audioWindow.push((left + right) * 0.5F)
				&& !emitBands(analyzer.analyze(audioWindow.orderedSamples()))) {
				stopRequested = 1;
				break;
			}
		}

		pendingBytes.erase(pendingBytes.begin(),
			pendingBytes.begin() + static_cast<std::ptrdiff_t>(completeBytes));
	}

	const int captureStatus = capture.stop();
	if (stopRequested) return 0;
	if (WIFEXITED(captureStatus)) return WEXITSTATUS(captureStatus);
	return WIFSIGNALED(captureStatus) ? 128 + WTERMSIG(captureStatus) : 1;
}

void printUsage(std::string_view program) {
	std::cout << "Usage: " << program << " [--self-test]\n";
}

} // namespace

int main(int argc, char** argv) {
	if (argc == 1) return runCapture();
	if (argc == 2 && std::string_view(argv[1]) == "--self-test") {
		return runSelfTest();
	}
	if (argc == 2 && (std::string_view(argv[1]) == "--help"
		|| std::string_view(argv[1]) == "-h")) {
		printUsage(argv[0]);
		return 0;
	}

	printUsage(argv[0]);
	return 2;
}
