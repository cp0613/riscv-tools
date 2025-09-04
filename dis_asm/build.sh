# xuantie-toolchain-3.4
CROSS_COMPILER=/rvhome/chenp/toolchain/gcc/Xuantie-900-gcc-linux-6.6.36-glibc-x86_64-V3.4.0/bin/riscv64-unknown-linux-gnu-
# xuantie-toolchain-3.0
#CROSS_COMPILER=/rvhome/chenp/toolchain/gcc/Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V3.0.0/bin/riscv64-unknown-linux-gnu-
#CROSS_COMPILER=/rvhome/chenp/toolchain/gcc/Xuantie-900-gcc-linux-6.6.0-glibc-x86_64-V3.0.0/bin/riscv64-unknown-linux-gnu-
# xuantie-toolchain-2.10.x
#CROSS_COMPILER=/rvhome/chenp/toolchain/gcc/Xuantie-900-gcc-linux-6.6.0-glibc-x86_64-V2.10.1/bin/riscv64-unknown-linux-gnu-
#CROSS_COMPILER=/rvhome/chenp/toolchain/gcc/Xuantie-900-gcc-linux-6.6.0-glibc-x86_64-V2.10.0/bin/riscv64-unknown-linux-gnu-
# xuantie-toolchain-2.8
#CROSS_COMPILER=/rvhome/chenp/toolchain/gcc/Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V2.8.1/bin/riscv64-unknown-linux-gnu-
# xuantie-toolchain-2.6
#CROSS_COMPILER=/rvhome/chenp/toolchain/gcc/Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V2.6.2/bin/riscv64-unknown-linux-gnu-

${CROSS_COMPILER}as -march=rv64gc_xtheadc_xtheadmatrix_zbb asm.s -o asm.o
${CROSS_COMPILER}ld asm.o -o asm
${CROSS_COMPILER}objdump -d asm