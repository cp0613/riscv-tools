cat rv64_bin.txt | xxd -r -p > rv64_bin
riscv64-unknown-linux-gnu-objdump -D -b binary -m riscv:rv64 -M numeric,no-aliases rv64_bin > rv64_asm.asm
