#!/bin/bash
now=`date "+%Y%m%d_%H%M"`
file=mem_${now}.log
loop=100000
echo "-m 1 -c 40000000 " > $file
./test_mem -m 1 -c 40000000 | tee -a $file

echo "\n\n-m 4 -c 10000000" >> $file
./test_mem -m 4 -c 10000000 | tee -a $file

echo "\n\n-m 16 -c 2500000" >> $file
./test_mem -m 16 -c 2500000 | tee -a $file

echo "\n\n-m 64 -c 625000" >> $file
./test_mem -m 64 -c 625000 | tee -a $file

echo "\n\n-m 256 -c 156250" >> $file
./test_mem -m 256 -c 156250 | tee -a $file

echo "\n\n-m 1024 -c 39062" >> $file
./test_mem -m 1024 -c 39062 | tee -a $file

echo "\n\n-m 10240 -c 3900" >> $file
./test_mem -m 10240 -c 3900 | tee -a $file

echo "\n\n\n" | tee -a $file
cat $file | grep "memcpy update percent" | tee -a $file

echo "\n\n\n" | tee -a $file
cat $file | grep "memload update percent" | tee -a $file

echo "\n\n\n" | tee -a $file
cat $file | grep "memset update percent" | tee -a $file
