#!/bin/bash
cd build
export JlCxx_DIR=~/.julia/packages/CxxWrap/KcmSi/deps/usr/lib/cmake/JlCxx
cmake -D Julia_EXECUTABLE=~/bin/julia-1.0.1/bin/julia ..
make
