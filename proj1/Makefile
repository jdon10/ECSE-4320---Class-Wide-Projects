CXX ?= g++
COMMON = -std=c++17 -O3 -Wall -Wextra -Wpedantic -fno-lto -fno-math-errno -fno-trapping-math -fno-signed-zeros -fassociative-math -ffp-contract=fast
SCALAR = -fno-tree-loop-vectorize -fno-tree-slp-vectorize
AUTO = -ftree-loop-vectorize -ftree-slp-vectorize
WIDEST = $(shell $(CXX) -dumpmachine | grep -Eq 'x86_64|i.86' && echo -mprefer-vector-width=512)
NATIVE = $(AUTO) -march=native -mtune=native $(WIDEST)
.PHONY: all scalar auto native check verify flags clean
all: scalar auto native
scalar: build/scalar
auto: build/auto
native: build/native
build:
	mkdir -p build
build/scalar: bench.cpp Makefile | build
	rm -f build/scalar.vec
	$(CXX) $(COMMON) $(SCALAR) -DBUILD_NAME='"scalar"' -fopt-info-vec-all=build/scalar.vec bench.cpp -o $@
build/auto: bench.cpp Makefile | build
	rm -f build/auto.vec
	$(CXX) $(COMMON) $(AUTO) -DBUILD_NAME='"auto"' -fopt-info-vec-all=build/auto.vec bench.cpp -o $@
build/native: bench.cpp Makefile | build
	rm -f build/native.vec
	$(CXX) $(COMMON) $(NATIVE) -DBUILD_NAME='"native"' -fopt-info-vec-all=build/native.vec bench.cpp -o $@
flags:
	@echo 'CXX=$(CXX)'
	@echo 'COMMON=$(COMMON)'
	@echo 'SCALAR=$(SCALAR)'
	@echo 'AUTO=$(AUTO)'
	@echo 'NATIVE=$(NATIVE)'
check: all
	python3 check.py
verify: all
	bash verify_simd.sh
clean:
	rm -rf build
