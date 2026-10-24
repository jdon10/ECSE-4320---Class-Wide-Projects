CXX = g++
CXXFLAGS = -O3 -std=c++17 -Wall -Wextra -Wpedantic

.PHONY: all check clean
all: benchmark
benchmark: benchmark.cpp
	$(CXX) $(CXXFLAGS) $< -o $@
check: benchmark
	./benchmark --self-test
	./benchmark --experiment knee --size 1048576 --intensity 8 --check-only
	./benchmark --experiment pattern --pattern stride --size 1048576 --stride 1024 --granularity 64 --read 70 --check-only
clean:
	rm -f benchmark
