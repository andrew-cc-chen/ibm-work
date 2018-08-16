#!/bin/bash

#setup gcc 4.9.3
set -xe
installdir=`pwd`

if [[ $# -ne 0 ]]
then
  installdir=$1
  shift
fi

wget http://ftp.gnu.org/gnu/gmp/gmp-6.1.0.tar.xz
tar xJf gmp-6.1.0.tar.xz
mkdir build
cd build && ../gmp-6.1.0/configure  --prefix=$installdir
make -j8
make install
echo installing gmp1
echo $?
cd - && rm -rf build gmp-6.1.0 gmp-6.1.0.tar.xz
echo installing gmp2
echo $?

export LD_LIBRARY_PATH=$installdir/lib:$LD_LIBRARY_PATH

wget http://ftp.gnu.org/gnu/mpfr/mpfr-3.1.4.tar.gz
tar xzf mpfr-3.1.4.tar.gz
mkdir build
cd build && ../mpfr-3.1.4/configure --with-gmp=$installdir --prefix=$installdir
make -j8
make install
echo installing mpfr1
echo $?
cd - && rm -rf build mpfr-3.1.4 mpfr-3.1.4.tar.gz
echo installing mpfr2
echo $?

wget http://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
tar xzf mpc-1.0.3.tar.gz
mkdir build
cd build  && ../mpc-1.0.3/configure --with-mpfr=$installdir --with-gmp=$installdir --prefix=$installdir
make -j8
make install
echo installing mpc1
echo $?
cd - && rm -rf build mpc-1.0.3 mpc-1.0.3.tar.gz
echo installing mpc2
echo $?

wget http://ftp.gnu.org/gnu/gcc/gcc-4.9.3/gcc-4.9.3.tar.gz
tar -xzf gcc-4.9.3.tar.gz

mkdir build && cd build
../gcc-4.9.3/configure --enable-languages=c,c++ --with-mpfr=$installdir --with-gmp=$installdir --prefix=$installdir/gcc-4.9.3
make -j8
echo installing gcc1
echo $?
make install
echo installing gcc2
echo $?
cd ..
export PATH=gcc-4.9.3/bin:$PATH
export LD_LIBRARY_PATH=gcc-4.9.3/lib/../lib64:$LD_LIBRARY_PATH
export CC=gcc-4.9.3/bin/gcc
export CXX=gcc-4.9.3/bin/g++
rm -rf build
#finish setting up gcc 4.9.3


#setup cmake
wget http://www.cmake.org/files/v3.11/cmake-3.11.1.tar.gz
tar zxf cmake-3.11.1.tar.gz
cd cmake-3.11.1
./configure --prefix=.
make && make install
echo $(bin/cmake --version)
cd ../

#get google's clang's version
git clone https://chromium.googlesource.com/chromium/src/tools/clang.git/
version=$(grep -oP "(?<=CLANG_REVISION\s\=\s\')[0-9]+" clang/scripts/update.py)
rm -rf clang

#checkout llvm
svn co -r $version http://llvm.org/svn/llvm-project/llvm/trunk llvm

#checkout clang
cd llvm/tools
svn co -r $version http://llvm.org/svn/llvm-project/cfe/trunk clang
echo $0
cd ../../

#extra tools (optional)
cd llvm/tools/clang/tools
svn co -r $version http://llvm.org/svn/llvm-project/clang-tools-extra/trunk extra
echo $0
cd ../../../../

#compiler-rt (optional)
cd llvm/projects
svn co -r $version http://llvm.org/svn/llvm-project/compiler-rt/trunk compiler-rt 
echo $0
cd ../../

#Check out libcxx: (only required to build and run Compiler-RT tests on OS X, optional otherwise)
#cd llvm/projects
#svn co http://llvm.org/svn/llvm-project/libcxx/trunk libcxx
#cd ../..

#Build LLVM and Clang
mkdir build && cd build
../cmake-3.11.1/bin/cmake -G "Unix Makefiles" ../llvm
#RUNNING make WITH -j 2 INSTEAD OF 8, SINCE IT WILL RUN OUT OF MEMORY
make
cd ..

cd build
#test suite from llvm
make check-clang
cd ..