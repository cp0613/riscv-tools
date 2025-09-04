# riscv_ptw
riscv sv39/sv48/sv57 ptw

- riscv_ptw：一个C程序，结合GDB一步步完成PTW
- riscv_ptw.gdb：一个gdb脚本，用于gdb中自动完成PTW（支持sv39/sv48/sv57）
- sv39_ptw.gdb：一个开源gdb脚本，用于gdb中自动完成PTW（仅支持sv39）
- user_va.c：一个C程序，用户态通过malloc、calloc、mmap申请内存，结合上述程序or脚本调试验证

kernel在从初始化到运行阶段会使用3种页表，分别为：
- trampoline_pg_dir（短暂使用，仅用作 PA 切换到 VA 的跳板）
- early_pg_dir
- swapper_pg_dir（kernel最终使用的页表）
所以上述程序or脚本输入的VA主要是基于`swapper_pg_dir`建立的页表映射。即可输入的 VA 为：
- setup_vm_final()中建立的，如create_linear_mapping_page_table()（如 0xFF60_0000_0020_0000 为 kernel 的线性 map 起点） 、 create_kernel_page_table(swapper_pg_dir, false)（如 0xFFFF_FFFF_8000_0000 为 kernel 的另一个 map 起点 ）
- 早期基于`early_pg_dir`建立的页表，如create_fdt_early_page_table(__fix_to_virt(FIX_FDT), dtb_pa)）是建立在 fixmap 区域（其中 0xFF1B_FFFF_FEC0_0000 对应 dtb 的映射起点，但此区域并非所有 VA，都在页表中映射了对应的 PA）
- 后续kernel运行当中动态建立的页表

## Virtual Memory Layout on RISC-V Linux
- https://www.kernel.org/doc/html/latest/arch/riscv/vm-layout.html

## riscv_ptw.gdb
### sv57
```
(gdb) source riscv-ptw.gdb 

(gdb) va2pa &_start
Current paging mode: Sv57 (0xa)
VA = 0xffffffff80000000, PA = 0x80200000
Page size: 2 MiB 
Flags: R-X-GAD (0xea)
PBMT: None (0x0)
N: Normal (0x0)
    
(gdb) va2pa 0xffffffff80000000
Current paging mode: Sv57 (0xa)
VA = 0xffffffff80000000, PA = 0x80200000
Page size: 2 MiB 
Flags: R-X-GAD (0xea)
PBMT: None (0x0)
N: Normal (0x0)

(gdb) va2pa 0xff60000000200000
Current paging mode: Sv57 (0xa)
VA = 0xff60000000200000, PA = 0x80200000
Page size: 2 MiB 
Flags: R---GAD (0xe2)
PBMT: None (0x0)
N: Normal (0x0)

# 下述 va 来源于 log 的 Virtual kernel memory layout 中的 fixmap
# 在最后一级页表（使用 VPN[0] 索引得到）中转换失败的原因，是因为建立了页表结构，但是没有填充实际 VA/PA 的映射
(gdb) va2pa 0xff1bfffffea00000
Invalid L0 PTE 0x0 @ 0x81be2000
Current paging mode: Sv57 (0xa)
VA to PA translation failed for 0xff1bfffffea00000
# 比如在 fixmap 范围内的 FIX_EARLYCON_MEM_BASE（0x407） 和对应的 VA（0xff1bfffffebf9000）就能正常转换
(gdb) va2pa 0xff1bfffffebf9000
Current paging mode: Sv57 (0xa)
VA = 0xff1bfffffebf9000, PA = 0x10000000
Page size: 4 KiB 
Flags: RW--GAD (0xe6)
PBMT: None (0x0)
N: Normal (0x0)
(gdb) va2pa 0xff1bfffffec00000
Current paging mode: Sv57 (0xa)
# 比如在 fixmap 范围内的 dtb_pa（0xbfe00000） 和 __fix_to_virt(FIX_FDT)（为 0xff1bfffffec00000）
VA = 0xff1bfffffec00000, PA = 0xbfe00000
Page size: 2 MiB 
Flags: RW--GAD (0xe6)
PBMT: None (0x0)
N: Normal (0x0)
```

### sv48
```
(gdb) source riscv-ptw.gdb 

(gdb) va2pa &_start
Current paging mode: Sv48 (0x9)
VA = 0xffffffff80000000, PA = 0x80200000
Page size: 2 MiB 
Flags: R-X-GAD (0xea)
PBMT: None (0x0)
N: Normal (0x0)
    
(gdb) va2pa 0xffffffff80000000
Current paging mode: Sv48 (0x9)
VA = 0xffffffff80000000, PA = 0x80200000
Page size: 2 MiB 
Flags: R-X-GAD (0xea)
PBMT: None (0x0)
N: Normal (0x0)
```

### sv39
```
(gdb) source riscv-ptw.gdb 

(gdb) va2pa &_start
Current paging mode: Sv39 (0x8)
VA = 0xffffffff80000000, PA = 0x80200000
Page size: 2 MiB 
Flags: R-X-GAD (0xea)
PBMT: None (0x0)
N: Normal (0x0)
    
(gdb) va2pa 0xffffffff80000000
Current paging mode: Sv39 (0x8)
VA = 0xffffffff80000000, PA = 0x80200000
Page size: 2 MiB 
Flags: R-X-GAD (0xea)
PBMT: None (0x0)
N: Normal (0x0)
```