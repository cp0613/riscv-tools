def decode_napot(pmpaddr: int, xlen: int = 64) -> tuple[int, int]:
    """Decode NAPOT region from pmpaddr (raw CSR value)."""
    if pmpaddr == 0:
        return 0, 4  # 4-byte region at 0

    temp = pmpaddr + 1
    mask = pmpaddr ^ temp
    trailing_ones = mask.bit_length() - 1
    size = 1 << (trailing_ones + 3)  # 2^(k+3) bytes
    clear_mask = ~((1 << (trailing_ones + 1)) - 1)
    base_pmp = pmpaddr & clear_mask
    base = base_pmp << 2  # 4-byte granularity
    addr_mask = (1 << xlen) - 1
    return base & addr_mask, size


def parse_pmp_entries(pmpcfg_list, pmpaddr_list, xlen=64):
    """
    Parse PMP entries from pmpcfg and pmpaddr registers.

    Args:
        pmpcfg_list: List of pmpcfg register values [pmpcfg0, pmpcfg1, ...]
                     Each is a 64-bit integer (for RV64).
        pmpaddr_list: List of pmpaddr values [pmpaddr0, pmpaddr1, ..., pmpaddr15]
        xlen: 32 or 64

    Returns:
        List of dict, each representing a PMP entry.
    """
    entries = []
    num_entries = min(len(pmpaddr_list), 16)

    for i in range(num_entries):
        # Determine which pmpcfg register and byte offset
        cfg_reg_index = i // 8  # 0 for PMP0-7, 1 for PMP8-15 (in RV64)
        byte_offset = i % 8

        if cfg_reg_index >= len(pmpcfg_list):
            cfg_byte = 0  # assume disabled if cfg not provided
        else:
            # Extract the i-th byte from pmpcfg[cfg_reg_index]
            cfg_byte = (pmpcfg_list[cfg_reg_index] >> (byte_offset * 8)) & 0xFF

        # Decode fields
        R = bool(cfg_byte & (1 << 0))
        W = bool(cfg_byte & (1 << 1))
        X = bool(cfg_byte & (1 << 2))
        A = (cfg_byte >> 3) & 0x3  # bits [4:3]
        L = bool(cfg_byte & (1 << 7))

        pmpaddr = pmpaddr_list[i] if i < len(pmpaddr_list) else 0

        mode = {0: "OFF", 1: "TOR", 2: "NA4", 3: "NAPOT"}.get(A, f"RESERVED({A})")

        base = 0
        size = 0

        if A == 0:  # OFF
            base = 0
            size = 0
        elif A == 1:  # TOR
            if i == 0:
                prev_addr = 0
            else:
                prev_addr = pmpaddr_list[i - 1] << 2  # previous pmpaddr << 2
            curr_addr = pmpaddr << 2
            base = prev_addr
            size = curr_addr - prev_addr
            if size < 0:
                size = 0  # invalid, but handle gracefully
        elif A == 2:  # NA4 (4-byte naturally aligned)
            base = (pmpaddr << 2) & ~0x3  # align to 4-byte
            size = 4
        elif A == 3:  # NAPOT
            base, size = decode_napot(pmpaddr, xlen)

        entries.append({
            "entry": i,
            "mode": mode,
            "R": R,
            "W": W,
            "X": X,
            "L": L,
            "pmpcfg_byte": cfg_byte,
            "pmpaddr_raw": pmpaddr,
            "base": base,
            "size": size,
        })

    return entries

def address_in_region(addr: int, base: int, size: int) -> bool:
    """Check if addr falls in [base, base + size)"""
    if size == 0:
        return False
    return base <= addr < (base + size)


def check_pmp_access(addr: int, privilege: str, access_type: str, pmp_entries: list, mseccfg: int, xlen: int = 64) -> bool:
    """
    Check PMP access permission.
    
    Rules:
      - Entries are checked in order (0 to 15).
      - First matching entry decides.
      - If no entry matches:
          - M-mode: ALLOW
          - S/U-mode: DENY
    """
    # Normalize inputs
    privilege = privilege.upper()
    access_type = access_type.upper()
    if privilege not in ('M', 'S', 'U'):
        raise ValueError("privilege must be 'M', 'S', or 'U'")
    if access_type not in ('R', 'W', 'X'):
        raise ValueError("access_type must be 'R', 'W', or 'X'")

    addr &= (1 << xlen) - 1  # mask to XLEN bits
    mseccfg_MML = mseccfg & 1 # TODO

    # Check PMP entries in order
    for entry in pmp_entries:
        if entry["mode"] == "OFF":
            continue
        if address_in_region(addr, entry["base"], entry["size"]):
            # Matched! Check permission
            if access_type == 'R' and entry["R"]:
                return True
            if access_type == 'W' and entry["W"]:
                return True
            if access_type == 'X' and entry["X"]:
                return True
            # Matched but no permission → deny
            return False

    # No entry matched
    if privilege == 'M':
        return True   # M-mode: default allow
    else:
        return False  # S/U-mode: default deny

def print_pmp_table(entries):
    print(f"{'Entry':<5} {'Mode':<6} {'R':<2} {'W':<2} {'X':<2} {'L':<2} {'Base (hex)':<18} {'End (hex)':<18} {'Size (bytes)':<12}")
    print("-" * 80)
    for e in entries:
        base = e['base']
        size = e['size']
        end = base + size

        if e["size"] == 0:
            size_str = "0"
        elif e["size"] < 1024:
            size_str = f"{e['size']}"
        elif e["size"] < 1024*1024:
            size_str = f"{e['size']//1024}K"
        else:
            size_str = f"{e['size']//(1024*1024)}M"
        print(f"{e['entry']:<5} {e['mode']:<6} {int(e['R']):<2} {int(e['W']):<2} {int(e['X']):<2} {int(e['L']):<2} "
              f"{base:18x} {end:18x}  {size_str}")


# ======================
# 示例使用
# ======================
if __name__ == "__main__":
    # 示例：假设我们有 pmpcfg0 和 pmpcfg2（对应 PMP0-PMP15）
    # 每个 pmpcfg 是 64 位整数

    mseccfg = 0x205

    pmpcfg0 = 0x9b9b9b9b9b1e1e00 # PMP0-7
    pmpcfg2 = 0x1f9d  # PMP8-15

    # pmpaddr0-15: for NAPOT, use values like 0, 1, 3, 7, etc.
    pmpaddr_vals = [
        0x20d96a5f,
        0x401ff,
        0x40001ff,
        0x90001ff,
        0x94001ff,
        0x801fff,
        0x3001fff,
        0x20023fff,
        0x2000ffff,
        0xffffffffffffffff,
        0x0,
        0x0,
        0x0,
        0x0,
        0x0,
        0x0,
    ]

    # Parse
    entries = parse_pmp_entries(
        pmpcfg_list=[pmpcfg0, pmpcfg2],
        pmpaddr_list=pmpaddr_vals[:16],
        xlen=64
    )

    # Print
    print_pmp_table(entries)

    # Test access
    tests = [
        (0x80000000, 'M', 'R'),
        (0x80000000, 'M', 'W'),
        (0x80000000, 'M', 'X'),
        (0x0, 'M', 'R'),
    ]

    print("mseccfg:", mseccfg, "")
    print("\nAccess Tests:")
    print(f"{'Addr':<12} {'Priv':<4} {'RWX_Type':<4}")
    print("-" * 80)
    for addr, priv, rwx_type in tests:
        allowed = check_pmp_access(addr, priv, rwx_type, entries, mseccfg, xlen=64)
        status = "✅" if allowed else "❌"
        print(f"0x{addr:08x} {priv:<4} {rwx_type:<4} {allowed!s:<8} {status}")
