# SXLEN = 64
set $SATP_PPN_MASK = 0xfffffffffff
set $SATP_MODE_OFFSET = 60

# Page masks for different page sizes
# 256TiB (48-bit)，即 VPN[3] + VPN[2] + VPN[1] + VPN[0] + page offset 字段
set $TERAPAGE_MASK = 0xFFFFFFFFFFFF
# 512GiB (39-bit)，即 VPN[2] + VPN[1] + VPN[0] + page offset 字段
set $PETAPAGE_MASK = 0x7FFFFFFFFF
# 1GiB (30-bit)，即 VPN[1] + VPN[0] + page offset 字段
set $GIGAPAGE_MASK = 0x3fffffff
# 4MiB（22-bit），即 VPN[0] + page offset 字段
set $MEGAPAGE_MASK_SV32 = 0x3fffff 
# 2MiB (21-bit)，即 VPN[0] + page offset 字段
set $MEGAPAGE_MASK = 0x1fffff
# 4KiB (12-bit)，即 page offset 字段 
set $PAGE_MASK = 0xfff

# VPN[x] OFFSET
set $VPN_4_OFFSET = 48
set $VPN_3_OFFSET = 39
set $VPN_2_OFFSET = 30
set $VPN_1_OFFSET = 21
set $VPN_1_OFFSET_SV32 = 22
set $VPN_0_OFFSET = 12

# VPN[x] mask
# 10 bits per VPN
set $VPN_MASK_SV32 = 0x3ff
# 9 bits per VPN
set $VPN_MASK = 0x1ff

# PTE 中 PPN 的 MASK
set $PTE_PPN_MASK_SV32 = 0x3fffff
set $PTE_PPN_MASK = 0xFFFFFFFFFFF
# PTE 中 PPN OFFSET
set $PTE_PPN_OFFSET = 10

# VA 中 VPN OFFSET
set $VPN_OFFSET = 12

# PTE flags
set $PTE_V = 0x1
set $PTE_R = 0x2
set $PTE_W = 0x4
set $PTE_X = 0x8
set $PTE_U = 0x10
set $PTE_G = 0x20
set $PTE_A = 0x40
set $PTE_D = 0x80
set $PTE_XWR = $PTE_X | $PTE_W | $PTE_R

# PBMT 字段 (bit 62-61)
set $PTE_PBMT_SHIFT = 61
set $PTE_PBMT_MASK = (unsigned long)0x3 << $PTE_PBMT_SHIFT
# None
set $PTE_PBMT_NONE = (unsigned long)0x0 << $PTE_PBMT_SHIFT
# Non-cacheable, idempotent, weakly-ordered
set $PTE_PBMT_NC   = (unsigned long)0x1 << $PTE_PBMT_SHIFT
# Non-cacheable, non-idempotent, strongly-ordered (I/O)
set $PTE_PBMT_IO   = (unsigned long)0x2 << $PTE_PBMT_SHIFT
# Reserved
set $PTE_PBMT_RSV  = (unsigned long)0x3 << $PTE_PBMT_SHIFT

# N 字段 (bit 63)
set $PTE_N_SHIFT = 63
set $PTE_N_MASK = (unsigned long)0x1 << $PTE_N_SHIFT
# Normal page
set $PTE_N_NORMAL = (unsigned long)0x0 << $PTE_N_SHIFT
# NAPOT (Naturally Aligned Power-Of-Two) page
set $PTE_N_NAPOT  = (unsigned long)0x1 << $PTE_N_SHIFT

# 分页方式
set $SV32_MODE = 0x1
set $SV39_MODE = 0x8
set $SV48_MODE = 0x9
set $SV57_MODE = 0xA

# Helper function to print PTE
define print-flags
  set $pte_val = (unsigned long)$arg0
  set $flags = $pte_val & ($PTE_R|$PTE_W|$PTE_X|$PTE_U|$PTE_G|$PTE_A|$PTE_D)
  set $pbmt = $pte_val & $PTE_PBMT_MASK
  set $n = $pte_val & $PTE_N_MASK
  
  # 直接打印所有标志位
  printf "\n"
  printf "Flags: %c%c%c%c%c%c%c (0x%lx)", \
         ($pte_val & $PTE_R) ? 'R' : '-', \
         ($pte_val & $PTE_W) ? 'W' : '-', \
         ($pte_val & $PTE_X) ? 'X' : '-', \
         ($pte_val & $PTE_U) ? 'U' : '-', \
         ($pte_val & $PTE_G) ? 'G' : '-', \
         ($pte_val & $PTE_A) ? 'A' : '-', \
         ($pte_val & $PTE_D) ? 'D' : '-', \
         $flags
  printf "\n"

  printf "PBMT: "
  if ($pbmt == $PTE_PBMT_NONE)
    printf "None ",
  end
  if ($pbmt == $PTE_PBMT_NC)
    printf "NC "
  end
  if ($pbmt == $PTE_PBMT_IO)
    printf "IO "
  end
  printf "(0x%lx)\n", $pbmt

  printf "N: "
  if ($n == $PTE_N_NORMAL)
    printf "Normal "
  end
  if ($n == $PTE_N_NAPOT)
    printf "NAPOT "
  end
  printf "(0x%lx)", $n

end

define va2pa
  set $satp_val = $satp
  set $mode = ($satp_val >> $SATP_MODE_OFFSET) & 0xf
  set $mode_name = "Unknown"
  # 暂时将 satp 的 MODE 字段置0，否则 gdb 无权限访问物理地址
  set $satp = $satp_val & (~((unsigned long)0xf << $SATP_MODE_OFFSET))
  set $va = (unsigned long)$arg0
  # page table
  set $pt = ($satp & $SATP_PPN_MASK) << $VPN_OFFSET
  set $success = 0
  set $final_pte = 0
  set $page_size = ""

  # 根据分页模式选择不同的转换方案
  # Sv32
  if ($mode == $SV32_MODE)
    set $mode_name = "Sv32"

    # Level 1: 4MB pages
    set $idx = ($va >> $VPN_1_OFFSET_SV32) & $VPN_MASK_SV32
    # Sv32 使用 32 位 PTE
    set $pte = *((unsigned int *)$pt + $idx)
    if (($pte & $PTE_V) == 0)
      printf "Invalid L1 PTE 0x%x @ 0x%lx\n", $pte, ((unsigned int *)$pt)+$idx
    else
      # Sv32 PTE格式: [PPN1(12位)|PPN0(10位)|flags(12位)]
      # 获取 PPN，得到 PA 的高位地址
      set $pa = ((($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK_SV32) << $VPN_OFFSET) 
      if (($pte & $PTE_XWR) != 0)
        # 如果 PTE 是 leaf PTE，则是 4 MiB 巨页，则直接或上 VA 的 VPN[0] + page offset 字段，得到最终的 PA
        set $pa = $pa | ($va & $MEGAPAGE_MASK_SV32)
        set $success = 1
        set $final_pte = $pte
        set $page_size = "4 MiB"
      else
        # 如果是非 leaf PTE，则查看下一级页表
        # Level 0: 4KB pages
        set $pt = $pa
        set $idx = ($va >> $VPN_0_OFFSET) & $VPN_MASK_SV32
        set $pte = *((unsigned int *)$pt + $idx)
        if (($pte & $PTE_V) == 0)
          printf "Invalid L0 PTE 0x%x @ 0x%lx\n", $pte, ((unsigned int *)$pt)+$idx
        else
          set $pa = ((($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK_SV32) << $VPN_OFFSET) 
          # 或上 VA 中的 page offset 字段
          set $pa = $pa | ($va & $PAGE_MASK)
          set $success = 1
          set $final_pte = $pte
          set $page_size = "4 KiB"
        end
      end
    end
  end

  if ($mode == $SV39_MODE)
    # Sv39
    set $mode_name = "Sv39"
    
    # L2: 1GB pages
    set $idx = ($va >> $VPN_2_OFFSET) & $VPN_MASK
    set $pte = *((unsigned long *)$pt + $idx)
    if (($pte & $PTE_V) == 0)
      printf "Invalid L2 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
    else
      set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
      if (($pte & $PTE_XWR) != 0)
        # 如果 PTE 是 leaf PTE，则是 1 GiB 超大页，则直接或上 VA 的 VPN[1] + VPN[0] + page offset 字段，得到最终的 PA
        set $pa = $pa | ($va & $GIGAPAGE_MASK)
        set $success = 1
        set $final_pte = $pte
        set $page_size = "1 GiB"
      else
        # L1: 2MB pages
        set $pt = $pa
        set $idx = ($va >> $VPN_1_OFFSET) & $VPN_MASK
        set $pte = *((unsigned long *)$pt + $idx)
        if (($pte & $PTE_V) == 0)
          printf "Invalid L1 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
        else
          set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
          if (($pte & $PTE_XWR) != 0)
            set $pa = $pa | ($va & $MEGAPAGE_MASK)
            set $success = 1
            set $final_pte = $pte
            set $page_size = "2 MiB"
          else
            # L0: 4KB pages
            set $pt = $pa
            set $idx = ($va >> $VPN_0_OFFSET) & $VPN_MASK
            set $pte = *((unsigned long *)$pt + $idx)
            if (($pte & $PTE_V) == 0)
              printf "Invalid L0 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
            else
              set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
              set $pa = $pa | ($va & $PAGE_MASK)
              set $success = 1
              set $final_pte = $pte
              set $page_size = "4 KiB"
            end
          end
        end
      end
    end
  end

  if ($mode == $SV48_MODE)
    # Sv48
    set $mode_name = "Sv48"
    
    # L3: 512GB pages
    set $idx = ($va >> $VPN_3_OFFSET) & $VPN_MASK
    set $pte = *((unsigned long *)$pt + $idx)
    if (($pte & $PTE_V) == 0)
      printf "Invalid L3 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
    else
      set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
      if (($pte & $PTE_XWR) != 0)
        set $pa = $pa | ($va & $PETAPAGE_MASK)
        set $success = 1
        set $final_pte = $pte
        set $page_size = "512 GiB"
      else
        # L2: 1GB pages
        set $pt = $pa
        set $idx = ($va >> $VPN_2_OFFSET) & $VPN_MASK
        set $pte = *((unsigned long *)$pt + $idx)
        if (($pte & $PTE_V) == 0)
          printf "Invalid L2 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
        else
          set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
          if (($pte & $PTE_XWR) != 0)
            set $pa = $pa | ($va & $GIGAPAGE_MASK)
            set $success = 1
            set $final_pte = $pte
            set $page_size = "1 GiB"
          else
            # L1: 2MB pages
            set $pt = $pa
            set $idx = ($va >> $VPN_1_OFFSET) & $VPN_MASK
            set $pte = *((unsigned long *)$pt + $idx)
            if (($pte & $PTE_V) == 0)
              printf "Invalid L1 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
            else
              set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
              if (($pte & $PTE_XWR) != 0)
                set $pa = $pa | ($va & $MEGAPAGE_MASK)
                set $success = 1
                set $final_pte = $pte
                set $page_size = "2 MiB"
              else
                # L0: 4KB pages
                set $pt = $pa
                set $idx = ($va >> $VPN_0_OFFSET) & $VPN_MASK
                set $pte = *((unsigned long *)$pt + $idx)
                if (($pte & $PTE_V) == 0)
                  printf "Invalid L0 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
                else
                  set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
                  set $pa = $pa | ($va & $PAGE_MASK)
                  set $success = 1
                  set $final_pte = $pte
                  set $page_size = "4 KiB"
                end
              end
            end
          end
        end
      end
    end
  end

  if ($mode == $SV57_MODE)
    # Sv57
    set $mode_name = "Sv57"
    
    # L4: 256TB pages
    set $idx = ($va >> $VPN_4_OFFSET) & $VPN_MASK
    set $pte = *((unsigned long *)$pt + $idx)
    if (($pte & $PTE_V) == 0)
      printf "Invalid L4 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
    else
      set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
      if (($pte & $PTE_XWR) != 0)
        set $pa = $pa | ($va & $TERAPAGE_MASK)
        set $success = 1
        set $final_pte = $pte
        set $page_size = "256 TiB"
      else
        # L3: 512GB pages
        set $pt = $pa
        set $idx = ($va >> $VPN_3_OFFSET) & $VPN_MASK
        set $pte = *((unsigned long *)$pt + $idx)
        if (($pte & $PTE_V) == 0)
          printf "Invalid L3 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
        else
          set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
          if (($pte & $PTE_XWR) != 0)
            set $pa = $pa | ($va & $PETAPAGE_MASK)
            set $success = 1
            set $final_pte = $pte
            set $page_size = "512 GiB"
          else
            # L2: 1GB pages
            set $pt = $pa
            set $idx = ($va >> $VPN_2_OFFSET) & $VPN_MASK
            set $pte = *((unsigned long *)$pt + $idx)
            if (($pte & $PTE_V) == 0)
              printf "Invalid L2 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
            else
              set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
              if (($pte & $PTE_XWR) != 0)
                set $pa = $pa | ($va & $GIGAPAGE_MASK)
                set $success = 1
                set $final_pte = $pte
                set $page_size = "1 GiB"
              else
                # L1: 2MB pages
                set $pt = $pa
                set $idx = ($va >> $VPN_1_OFFSET) & $VPN_MASK
                set $pte = *((unsigned long *)$pt + $idx)
                if (($pte & $PTE_V) == 0)
                  printf "Invalid L1 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
                else
                  set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
                  if (($pte & $PTE_XWR) != 0)
                    set $pa = $pa | ($va & $MEGAPAGE_MASK)
                    set $success = 1
                    set $final_pte = $pte
                    set $page_size = "2 MiB"
                  else
                    # L0: 4KB pages
                    set $pt = $pa
                    set $idx = ($va >> $VPN_0_OFFSET) & $VPN_MASK
                    set $pte = *((unsigned long *)$pt + $idx)
                    if (($pte & $PTE_V) == 0)
                      printf "Invalid L0 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
                    else
                      set $pa = (($pte >> $PTE_PPN_OFFSET) & $PTE_PPN_MASK) << $VPN_OFFSET
                      set $pa = $pa | ($va & $PAGE_MASK)
                      set $success = 1
                      set $final_pte = $pte
                      set $page_size = "4 KiB"
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  if $mode != 1 && $mode != 8 && $mode != 9 && $mode != 10
    printf "Unsupported paging mode: %d\n", $mode
  else
    printf "Current paging mode: %s (0x%x)\n", $mode_name, $mode
  end

  if ($success == 0)
    printf "VA to PA translation failed for 0x%lx\n", $va
  else
    printf "VA = 0x%lx, PA = 0x%lx\n", $va, $pa
    printf "Page size: %s ", $page_size
    print-flags $final_pte
    printf "\n"
  end

  # 恢复原始satp值
  set $satp = $satp_val
end
