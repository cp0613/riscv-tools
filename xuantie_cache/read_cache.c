#include <stdio.h>
#include <stdint.h>

// index: memory addr
static inline void read_l2_dcache(uint32_t index, uint32_t way, uint64_t *data0, uint64_t *data1)
{
    uint32_t mcindex_value  = (0x5 << 28) | (way << 21) | (index & 0x1FFFFF);
    asm volatile (
        "mv t0, %2\n\t"
        "csrw mcindex, t0\n\t"
        "li t0, 0x1\n\t"
        "csrw mcins, t0\n\t"
        "csrr %0, mcdata0\n\t"
        "csrr %1, mcdata1\n\t"
        : "=r"(*data0), "=r"(*data1)
        : "r"(mcindex_value)
        : "t0"
    );
}
