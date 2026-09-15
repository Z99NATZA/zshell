CXX ?= c++
CXXFLAGS ?= -O2

build_directory := .build
spectrum_helper := $(build_directory)/zshell-spectrum

.PHONY: build check run

build: $(spectrum_helper)

$(spectrum_helper): native/spectrum.cpp
	mkdir -p $(build_directory)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -std=c++20 -Wall -Wextra -Wpedantic \
		$< $(LDFLAGS) -o $@

check: build
	$(spectrum_helper) --self-test
	./scripts/check.sh

run: build
	./scripts/run.sh
