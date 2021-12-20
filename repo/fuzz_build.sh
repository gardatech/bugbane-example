export CXX="${CXX:=afl-clang-fast++}" &&
mkdir -p build &&
make clean &&
make -j obj/libre2.a &&
$CXX $CXXFLAGS --std=c++11 -I. re2/fuzzing/re2_fuzzer.cc /AFLplusplus/libAFLDriver.a obj/libre2.a -lpthread -o build/re2_fuzzer
