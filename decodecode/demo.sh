# https://lore.kernel.org/all/20230119074738.708301-3-bjorn@kernel.org/

echo 'Code: bf45 f793 1007 f7d9 50ef 37af d541 b7d9 7097 00c8 (80e7) 6140' | AFLAGS="-march=rv64imac" ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- ./scripts/decodecode