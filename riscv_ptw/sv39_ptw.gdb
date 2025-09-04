#https://gist.github.com/jrtc27/31379990b9d6b802490a9bb06e13f496
#usage:
#  1. vatopa 0xffffffff80004a68
#  2. vatopa-verbose 0xffffffff80004a68
#  3. vatopa-silent 0xffffffff80004a68
#     p /x $pa

set $PPN_MASK = 0xfffffffffff

set $SATP_PPN_M = $PPN_MASK

set $GIGAPAGE_MASK = 0x3fffffff
set $MEGAPAGE_MASK = 0x1fffff
set $PAGE_MASK = 0xfff
set $PAGE_SHIFT = 12
set $VPN_MASK = 0x1ff
set $VPN_2 = 30
set $VPN_1 = 21
set $VPN_0 = 12

set $PTE_V = 0x1
set $PTE_R = 0x2
set $PTE_W = 0x4
set $PTE_X = 0x8
set $PTE_U = 0x10
set $PTE_G = 0x20
set $PTE_A = 0x40
set $PTE_D = 0x80
set $PTE_XWR = $PTE_X | $PTE_W | $PTE_R
set $PTE_PA_S = 10
set $PTE_PA_M = $PPN_MASK

define vatopa-silent
  set $va = (unsigned long)$arg0
  set $pt = ($satp & $SATP_PPN_M) << $PAGE_SHIFT
  set $idx = ($va >> $VPN_2) & $VPN_MASK
  set $satp_s = $satp
  set $satp = 0
  set $pte = ((unsigned long *)$pt)[$idx]
  if (($pte & $PTE_V) == 0)
    printf "Invalid L1 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
  else
    set $pa = (($pte >> $PTE_PA_S) & $PTE_PA_M) << $PAGE_SHIFT
    if (($pte & $PTE_XWR) != 0)
      set $pa = $pa | ($va & $GIGAPAGE_MASK)
    else
      set $pt = $pa
      set $idx = ($va >> $VPN_1) & $VPN_MASK
      set $pte = ((unsigned long *)$pt)[$idx]
      if (($pte & $PTE_V) == 0)
  printf "Invalid L2 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
      else
  set $pa = (($pte >> $PTE_PA_S) & $PTE_PA_M) << $PAGE_SHIFT
  if (($pte & $PTE_XWR) != 0)
    set $pa = $pa | ($va & $MEGAPAGE_MASK)
  else
    set $pt = $pa
    set $idx = ($va >> $VPN_0) & $VPN_MASK
    set $pte = ((unsigned long *)$pt)[$idx]
    if (($pte & $PTE_V) == 0)
      printf "Invalid L3 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
    else
      set $pa = (($pte >> $PTE_PA_S) & $PTE_PA_M) << $PAGE_SHIFT
      set $pa = $pa | ($va & $PAGE_MASK)
    end
  end
      end
    end
  end
  set $satp = $satp_s
end

define pte-print-meta
  set $printed_meta = 0
  if (($arg0 & $PTE_R) != 0)
    if ($printed_meta == 0)
      printf " "
      set $printed_meta = 1
    end
    printf "R"
  end
  if (($arg0 & $PTE_W) != 0)
    if ($printed_meta == 0)
      printf " "
      set $printed_meta = 1
    end
    printf "W"
  end
  if (($arg0 & $PTE_X) != 0)
    if ($printed_meta == 0)
      printf " "
      set $printed_meta = 1
    end
    printf "X"
  end
  if (($arg0 & $PTE_U) != 0)
    if ($printed_meta == 0)
      printf " "
      set $printed_meta = 1
    end
    printf "U"
  end
  if (($arg0 & $PTE_G) != 0)
    if ($printed_meta == 0)
      printf " "
      set $printed_meta = 1
    end
    printf "G"
  end
  if (($arg0 & $PTE_A) != 0)
    if ($printed_meta == 0)
      printf " "
      set $printed_meta = 1
    end
    printf "A"
  end
  if (($arg0 & $PTE_D) != 0)
    if ($printed_meta == 0)
      printf " "
      set $printed_meta = 1
    end
    printf "D"
  end
end

define vatopa
  set $va = (unsigned long)$arg0
  set $pt = ($satp & $SATP_PPN_M) << $PAGE_SHIFT
  set $idx = ($va >> $VPN_2) & $VPN_MASK
  set $satp_s = $satp
  set $satp = 0
  set $pte = ((unsigned long *)$pt)[$idx]
  if (($pte & $PTE_V) == 0)
    printf "Invalid L1 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
  else
    set $pa = (($pte >> $PTE_PA_S) & $PTE_PA_M) << $PAGE_SHIFT
    if (($pte & $PTE_XWR) != 0)
      set $pa = $pa | ($va & $GIGAPAGE_MASK)
      printf "PA 0x%lx"
      pte-print-meta $pte
      printf " (gigapage)\n"
    else
      set $pt = $pa
      set $idx = ($va >> $VPN_1) & $VPN_MASK
      set $pte = ((unsigned long *)$pt)[$idx]
      if (($pte & $PTE_V) == 0)
  printf "Invalid L2 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
      else
  set $pa = (($pte >> $PTE_PA_S) & $PTE_PA_M) << $PAGE_SHIFT
  if (($pte & $PTE_XWR) != 0)
    set $pa = $pa | ($va & $MEGAPAGE_MASK)
    printf "PA 0x%lx", $pa
    pte-print-meta $pte
    printf " (megapage)\n"
  else
    set $pt = $pa
    set $idx = ($va >> $VPN_0) & $VPN_MASK
    set $pte = ((unsigned long *)$pt)[$idx]
    if (($pte & $PTE_V) == 0)
      printf "Invalid L3 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
    else
      set $pa = (($pte >> $PTE_PA_S) & $PTE_PA_M) << $PAGE_SHIFT
      set $pa = $pa | ($va & $PAGE_MASK)
      printf "PA 0x%lx", $pa
      pte-print-meta $pte
      printf "\n"
    end
  end
      end
    end
  end
  set $satp = $satp_s
end

define vatopa-verbose
  set $va = (unsigned long)$arg0
  set $pt = ($satp & $SATP_PPN_M) << $PAGE_SHIFT
  set $idx = ($va >> $VPN_2) & $VPN_MASK
  set $satp_s = $satp
  set $satp = 0
  set $pte = ((unsigned long *)$pt)[$idx]
  printf "L0 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
  if (($pte & $PTE_V) == 0)
    printf "Invalid L1 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
  else
    set $pa = (($pte >> $PTE_PA_S) & $PTE_PA_M) << $PAGE_SHIFT
    if (($pte & $PTE_XWR) != 0)
      set $pa = $pa | ($va & $GIGAPAGE_MASK)
      printf "PA 0x%lx"
      pte-print-meta $pte
      printf " (gigapage)\n"
    else
      set $pt = $pa
      set $idx = ($va >> $VPN_1) & $VPN_MASK
      set $pte = ((unsigned long *)$pt)[$idx]
      printf "L1 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
      if (($pte & $PTE_V) == 0)
  printf "Invalid L2 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
      else
  set $pa = (($pte >> $PTE_PA_S) & $PTE_PA_M) << $PAGE_SHIFT
  if (($pte & $PTE_XWR) != 0)
    set $pa = $pa | ($va & $MEGAPAGE_MASK)
    printf "PA 0x%lx", $pa
    pte-print-meta $pte
    printf " (megapage)\n"
  else
    set $pt = $pa
    set $idx = ($va >> $VPN_0) & $VPN_MASK
    set $pte = ((unsigned long *)$pt)[$idx]
    printf "L2 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
    if (($pte & $PTE_V) == 0)
      printf "Invalid L3 PTE 0x%lx @ 0x%lx\n", $pte, ((unsigned long *)$pt)+$idx
    else
      set $pa = (($pte >> $PTE_PA_S) & $PTE_PA_M) << $PAGE_SHIFT
      set $pa = $pa | ($va & $PAGE_MASK)
      printf "PA 0x%lx", $pa
      pte-print-meta $pte
      printf "\n"
    end
  end
      end
    end
  end
  set $satp = $satp_s
end

define unwind-one
  set $vfp = (unsigned long)$arg0
  vatopa-silent $vfp
  set $pfp = (unsigned long)$pa
  set $vnfp = ((unsigned long *)$pfp)[-2]
  set $vra = ((unsigned long *)$pfp)[-1]
  vatopa-silent $vra
  set $pra = (unsigned long)$pa
  info line *$pra
  printf "pc = 0x%lx, s0 = 0x%lx\n", $pra, $vnfp
end

define unwind-many
  set $vofp = 0
  set $vnfp = (unsigned long)$arg0
  if ($vnfp == $fp)
    vatopa-silent $pc
    info line *$pa
    printf "pc = 0x%lx, s0 = 0x%lx\n", $pa, $vnfp
  else
    printf "No line number information available for address ?\n"
    printf "pc = ?, s0 = 0x%lx\n", $vnfp
  end
  while $vofp != $vnfp && $vnfp != 0
    set $vofp = $vnfp
    unwind-one $vnfp
  end
end