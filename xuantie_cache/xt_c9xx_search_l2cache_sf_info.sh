# usage: xt_c9xx_search_l2cache_sf_info 0x60da9a9a 0xf

define xt_c9xx_search_l2cache_sf_info
  printf "\npa value:0x%lx\n", $arg0
  printf "totally way:%d\n", $arg1

  set var $idx_mask        = (long long)0x1fffff
  set var $tag_mask        = (long long)0xfffffff000
  set var $replace_mask    = 0x70
  set var $dirty_mask      = 0xf
  set var $tag_high_val    = ((long long)($arg0)) & ((long long)($tag_mask))

  set var $sf_tag_mask     = (long long)0xfffffff000
  set var $sf_replace_mask = 0x600
  set var $sf_info_mask    = 0x1ff
  set var $sf_tag_high_val = ((long long)($arg0)) & ((long long)($sf_tag_mask))

  set var $loop_i     = 0
  set var $cindex_val = (long long)0
  set var $cdata_val  = (long long)0
  printf "============================================================\n"
  while $loop_i < $arg1
    set $cindex_val = ((long long)($arg0)) & ((long long)$idx_mask)
    set $cindex_val = ((long long)($cindex_val)) | ((long long)0x4 << 28)
    set $cindex_val = ((long long)($cindex_val)) | ((long long)$loop_i << 21)

    set $mcindex = (long long)$cindex_val
    set $mcins = 1

    set $cdata_val = (long long)$mcdata0
    set $cdata_val = ((long long)$cdata_val) & ((long long)$tag_mask)
    if $cdata_val == (long long)$tag_high_val
      printf "======================L2Cache way %d hit===========================\n", $loop_i

      set $cdata_val = (long long)$mcdata0
      set $cdata_val = (((long long)$cdata_val) & ((long long)$replace_mask)) >> 4
      printf "rep val: 0x%lx\n", $cdata_val

      set $cdata_val = (long long)$mcdata0
      set $cdata_val = ((long long)$cdata_val) & ((long long)$dirty_mask)
      printf "flags val {v,s,d,p}: 0x%lx\n", $cdata_val

      set $cindex_val = ((long long)$arg0) & ((long long)$idx_mask)
      set $cindex_val = ((long long)($cindex_val)) | ((long long)0x5 << 28)
      set $cindex_val = ((long long)($cindex_val)) | ((long long)$loop_i << 21)

      set $mcindex = (long long)$cindex_val
      set $mcins = 1
      set $cdata_val = (long long)$mcdata0
      printf "data[63:0]:    0x%lx\n", $cdata_val
      set $cdata_val = $mcdata1
      printf "data[127:64]:  0x%lx\n", $cdata_val

      set $cindex_val = ((long long)$cindex_val) + 0x10
      set $mcindex = (long long)$cindex_val
      set $mcins = 1
      set $cdata_val = (long long)$mcdata0
      printf "data[191:128]: 0x%lx\n", $cdata_val
      set $cdata_val = $mcdata1
      printf "data[255:192]: 0x%lx\n", $cdata_val

      set $cindex_val = ((long long)$cindex_val) + 0x10
      set $mcindex = (long long)$cindex_val
      set $mcins = 1
      set $cdata_val = (long long)$mcdata0
      printf "data[319:256]: 0x%lx\n", $cdata_val
      set $cdata_val = $mcdata1
      printf "data[383:320]: 0x%lx\n", $cdata_val

      set $cindex_val = ((long long)$cindex_val) + 0x10
      set $mcindex = (long long)$cindex_val
      set $mcins = 1
      set $cdata_val = (long long)$mcdata0
      printf "data[447:384]: 0x%lx\n", $cdata_val
      set $cdata_val = $mcdata1
      printf "data[511:448]: 0x%lx\n", $cdata_val

    else
      printf "======================L2Cache way %d miss==========================\n", $loop_i
      set $cdata_val = (long long)$mcdata0
      printf "Cmp tag: 0x%lx, Get mcdata: 0x%lx\n", $tag_high_val, $cdata_val
    end

    set $cindex_val = ((long long)$arg0) & ((long long)$idx_mask)
    set $cindex_val = ((long long)($cindex_val)) | ((long long)0x14 << 28)
    set $cindex_val = ((long long)($cindex_val)) | ((long long)$loop_i << 21)

    set $mcindex = (long long)$cindex_val
    set $mcins = 1

    set $cdata_val = (long long)$mcdata0
    set $cdata_val = ((long long)$cdata_val) & ((long long)$sf_tag_mask)
    if $cdata_val == ((long long)$sf_tag_high_val)
      printf "======================SF way %d hit===========================\n", $loop_i

      set $cdata_val = (long long)$mcdata0
      set $cdata_val = (((long long)$cdata_val) & ((long long)$sf_replace_mask)) >> 9
      printf "sf rep val: 0x%lx\n", $cdata_val

      set $cdata_val = (long long)$mcdata0
      set $cdata_val = ((long long)$cdata_val) & ((long long)$sf_info_mask)
      printf "sf info val: 0x%lx\n", $cdata_val

    else
      printf "======================SF way %d miss==========================\n", $loop_i
      set $cdata_val = (long long)$mcdata0
      printf "Cmp sf_tag: 0x%lx, Get mcdata: 0x%lx\n", $sf_tag_high_val, $cdata_val
    end

    set $loop_i = $loop_i + 1

  end
end
