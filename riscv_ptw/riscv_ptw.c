#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
/*
pgd_t *pgd; PGD（Page Global Directory）是页表的最高层次。每个进程拥有一个 PGD，存储了一组指针，指向下一级的 P4D。
p4d_t *p4d; P4D（Page Level 4 Directory）是第二层页表结构。它的主要职责是进一步细分内存地址空间并指向 PUD。
pud_t *pud; PUD（Page Upper Directory）是页表的第三层。它包含指向 PMD 的指针，进一步细分地址空间。
pmd_t *pmd; PMD（Page Middle Directory）是页表的第四层。它指向 PTE，负责更细粒度的地址映射。
pte_t *pte; PTE（Page Table Entry）是页表的最底层，直接映射到物理内存页。它包含一个虚拟地址对应的物理地址，以及一些管理标志（如访问权限、是否存在等）。
*/
#define SATP_MODE_SV39 8
#define SATP_MODE_SV48 9
#define SATP_MODE_SV57 10

#define PTE_FLAG_V  0   //Valid
#define PTE_FLAG_R  1   //Readable
#define PTE_FLAG_W  2   //Writeable
#define PTE_FLAG_X  3   //Executable
#define PTE_FLAG_U  4   //User
#define PTE_FLAG_G  5   //Global
#define PTE_FLAG_A  6   //Access
#define PTE_FLAG_D  7   //Dirty
#define PTE_FLAG_NC 61  //PBMT
#define PTE_FLAG_IO 62  //PBMT
#define PTE_FLAG_N  63  //Svnapot

#define BIT(n) (1<<n)
#define GET_BIT(num, n) ((num & ((unsigned long)1 << n)) ? 1 : 0)

enum pte_stat {
    PTE_IS_LEAF,
    PTE_NOT_LEAF,
    PTE_INVALID,
};

unsigned long extract_64bits(unsigned long number, unsigned int end, unsigned int start)
{
    // 确保范围有效
    if (start < 0 || end >= 64 || start > end) {
        return 0; // 无效的范围
    }
    // 创建掩码
    unsigned long mask = ((1ULL << (end - start + 1)) - 1); // 生成指定范围的掩码
    return (number >> start) & mask; // 右移并与掩码相与
}

unsigned long concatenate_pa(unsigned long satp_ppn, unsigned long vpn)
{
    return (satp_ppn << 12) | (vpn << 3);
}

void print_pte_flags(unsigned long pte)
{
    printf("\t N \t IO \t NC \t D \t A \t G \t U \t X \t W \t R \t V \t 0x%lx\n", pte);
    printf("\t %d \t %d \t %d \t %d \t %d \t %d \t %d \t %d \t %d \t %d \t %d\t 0x%lx\n", 
        GET_BIT(pte, PTE_FLAG_N),
        GET_BIT(pte, PTE_FLAG_IO),
        GET_BIT(pte, PTE_FLAG_NC),
        GET_BIT(pte, PTE_FLAG_D),
        GET_BIT(pte, PTE_FLAG_A),
        GET_BIT(pte, PTE_FLAG_G),
        GET_BIT(pte, PTE_FLAG_U),
        GET_BIT(pte, PTE_FLAG_X),
        GET_BIT(pte, PTE_FLAG_W),
        GET_BIT(pte, PTE_FLAG_R),
        GET_BIT(pte, PTE_FLAG_V),
        pte);
}

unsigned long calc_final_pa(unsigned long ppnx, unsigned long vpnx, unsigned int page_offset)
{
    unsigned long pa = ppnx + vpnx + page_offset;
    printf("The final PA=0x%lx\n", pa);
    return pa;
}

unsigned long get_pte_from_pa(unsigned long pa)
{
    unsigned long pte;
    printf("now pa=0x%lx please input value of (x/xg 0x%lx):\n", pa, pa);
    scanf("%lx", &pte);
    return pte;
}

/**
 * @brief Verify PTE and print PA if is Leaf-PTE
 * @param pte pte
 * @param page_offset page_offset from va
 * @return pte_stat
 */
enum pte_stat verify_pte(unsigned long pte, unsigned int page_offset)
{
    print_pte_flags(pte);
    if (GET_BIT(pte, PTE_FLAG_V)) {
        unsigned int XWR = GET_BIT(pte, PTE_FLAG_X)|GET_BIT(pte, PTE_FLAG_W)|GET_BIT(pte, PTE_FLAG_R);
        if (XWR == 0) {
            printf("Not Leaf Page Table. Continue...\n\n");
            return PTE_NOT_LEAF;
        } else {
            printf("Is Leaf Page Table. Down...\n");
            return PTE_IS_LEAF;
        }
    } else {
        printf("Invalid PTE. Breaking...\n\n");
        return PTE_INVALID;
    }
}

int main()
{
    unsigned long pa;
    unsigned long pte, pte_ppn;
    unsigned long va;
    unsigned long satp;
    printf("Please input va:\n");
    scanf("%lx", &va);
    printf("Please input satp:\n");
    scanf("%lx", &satp);
    printf("va=0x%lx satp=0x%lx\n", va, satp);

    unsigned long satp_mdoe, satp_asid, satp_ppn;
    satp_mdoe = extract_64bits(satp, 63, 60);
    satp_asid = extract_64bits(satp, 59, 44);
    satp_ppn = extract_64bits(satp, 43, 0);
    printf("satp_mdoe=0x%lx satp_asid=0x%lx satp_ppn=0x%lx\n", satp_mdoe, satp_asid, satp_ppn);

    unsigned long ppnx, vpnx, vpn4, vpn3, vpn2, vpn1, vpn0, page_offset;
    enum pte_stat stat;
    if (satp_mdoe == SATP_MODE_SV39) {
        vpn2 = extract_64bits(va, 38, 30);
        vpn1 = extract_64bits(va, 29, 21);
        vpn0 = extract_64bits(va, 20, 12);
        page_offset = extract_64bits(va, 11, 0);
        printf("SATP_MODE_SV39 vpn2=0x%lx vpn1=0x%lx vpn0=0x%lx page_offset=0x%lx\n", vpn2, vpn1, vpn0, page_offset);
        printf("'set $satp=0' and continue...\n");
        //根据 SATP.PPN 和 VPN[2] 得到一级页表访存地址{SATP.PPN, VPN[2], 3’b0}
        pa = concatenate_pa(satp_ppn, vpn2);
        pte = get_pte_from_pa(pa); //PUD
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = (vpn1 << 21) + (vpn0 << 12);
                ppnx = extract_64bits(pte, 53, 28) << 30;
                printf("HUGEPAGE(1G) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(vpnx, vpnx, page_offset);
            }
            return 0;
        }
        //使用 pte.ppn 代替 satp.ppn，vpn 换为下一级 vpn，再拼接 3’b0 继续
        pte_ppn = extract_64bits(pte, 53, 10);
        pa = concatenate_pa(pte_ppn, vpn1);
        pte = get_pte_from_pa(pa); //PMD
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = vpn0 << 12;
                ppnx = extract_64bits(pte, 53, 19) << 21;
                printf("HUGEPAGE(2M) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
        //使用 pte.ppn 代替 satp.ppn，vpn 换为下一级 vpn，再拼接 3’b0 继续
        pte_ppn = extract_64bits(pte, 53, 10);
        pa = concatenate_pa(pte_ppn, vpn0);
        pte = get_pte_from_pa(pa); //PTE
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = 0;
                ppnx = extract_64bits(pte, 53, 10) << 12;
                printf("PAGE(4K) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
    } else if (satp_mdoe == SATP_MODE_SV48) {
        vpn3 = extract_64bits(va, 47, 39);
        vpn2 = extract_64bits(va, 38, 30);
        vpn1 = extract_64bits(va, 29, 21);
        vpn0 = extract_64bits(va, 20, 12);
        page_offset = extract_64bits(va, 11, 0);
        printf("SATP_MODE_SV48 vpn3=0x%lx vpn2=0x%lx vpn1=0x%lx vpn0=0x%lx page_offset=0x%lx\n", vpn3, vpn2, vpn1, vpn0, page_offset);
        printf("'set $satp=0' and continue...\n");
        //根据 SATP.PPN 和 VPN[3] 得到一级页表访存地址{SATP.PPN, VPN[3], 3’b0}
        pa = concatenate_pa(satp_ppn, vpn3);
        pte = get_pte_from_pa(pa); //P4D
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = (vpn2 << 30) + (vpn1 << 21) + (vpn0 << 12);
                ppnx = extract_64bits(pte, 53, 37) << 39;
                printf("HUGEPAGE(512G) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
        //使用 pte.ppn 代替 satp.ppn，vpn 换为下一级 vpn，再拼接 3’b0 继续
        pte_ppn = extract_64bits(pte, 53, 10);
        pa = concatenate_pa(pte_ppn, vpn2);
        pte = get_pte_from_pa(pa); //PUD
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = (vpn1 << 21) + (vpn0 << 12);
                ppnx = extract_64bits(pte, 53, 28) << 30;
                printf("HUGEPAGE(1G) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
        //使用 pte.ppn 代替 satp.ppn，vpn 换为下一级 vpn，再拼接 3’b0 继续
        pte_ppn = extract_64bits(pte, 53, 10);
        pa = concatenate_pa(pte_ppn, vpn1);
        pte = get_pte_from_pa(pa); //PMD
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = vpn0 << 12;
                ppnx = extract_64bits(pte, 53, 19) << 21;
                printf("HUGEPAGE(2M) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
        //使用 pte.ppn 代替 satp.ppn，vpn 换为下一级 vpn，再拼接 3’b0 继续
        pte_ppn = extract_64bits(pte, 53, 10);
        pa = concatenate_pa(pte_ppn, vpn0);
        pte = get_pte_from_pa(pa); //PTE
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = 0;
                ppnx = extract_64bits(pte, 53, 10) << 12;
                printf("PAGE(4K) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
    } else if (satp_mdoe == SATP_MODE_SV57) {
        vpn4 = extract_64bits(va, 56, 48);
        vpn3 = extract_64bits(va, 47, 39);
        vpn2 = extract_64bits(va, 38, 30);
        vpn1 = extract_64bits(va, 29, 21);
        vpn0 = extract_64bits(va, 20, 12);
        page_offset = extract_64bits(va, 11, 0);
        printf("SATP_MODE_SV57 vpn4=0x%lx vpn3=0x%lx vpn2=0x%lx vpn1=0x%lx vpn0=0x%lx page_offset=0x%lx\n", vpn4, vpn3, vpn2, vpn1, vpn0, page_offset);
        printf("'set $satp=0' and continue...\n");
        //根据 SATP.PPN 和 VPN[4] 得到一级页表访存地址{SATP.PPN, VPN[4], 3’b0}
        pa = concatenate_pa(satp_ppn, vpn4);
        pte = get_pte_from_pa(pa); //PGD
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = (vpn3 << 39) + (vpn2 << 30) + (vpn1 << 21) + (vpn0 << 12);
                ppnx = extract_64bits(pte, 53, 46) << 48;
                printf("HUGEPAGE(256T) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
        //使用 pte.ppn 代替 satp.ppn，vpn 换为下一级 vpn，再拼接 3’b0 继续
        pte_ppn = extract_64bits(pte, 53, 10);
        pa = concatenate_pa(pte_ppn, vpn3);
        pte = get_pte_from_pa(pa); //P4D
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = (vpn2 << 30) + (vpn1 << 21) + (vpn0 << 12);
                ppnx = extract_64bits(pte, 53, 37) << 39;
                printf("HUGEPAGE(512G) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
        //使用 pte.ppn 代替 satp.ppn，vpn 换为下一级 vpn，再拼接 3’b0 继续
        pte_ppn = extract_64bits(pte, 53, 10);
        pa = concatenate_pa(pte_ppn, vpn2);
        pte = get_pte_from_pa(pa); //PUD
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = (vpn1 << 21) + (vpn0 << 12);
                ppnx = extract_64bits(pte, 53, 28) << 30;
                printf("HUGEPAGE(1G) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
        //使用 pte.ppn 代替 satp.ppn，vpn 换为下一级 vpn，再拼接 3’b0 继续
        pte_ppn = extract_64bits(pte, 53, 10);
        pa = concatenate_pa(pte_ppn, vpn1);
        pte = get_pte_from_pa(pa); //PMD
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = vpn0 << 12;
                ppnx = extract_64bits(pte, 53, 19) << 21;
                printf("HUGEPAGE(2M) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
        //使用 pte.ppn 代替 satp.ppn，vpn 换为下一级 vpn，再拼接 3’b0 继续
        pte_ppn = extract_64bits(pte, 53, 10);
        pa = concatenate_pa(pte_ppn, vpn0);
        pte = get_pte_from_pa(pa); //PTE
        stat = verify_pte(pte, page_offset);
        if (stat != PTE_NOT_LEAF) {
            if (stat == PTE_IS_LEAF) {
                vpnx = 0;
                ppnx = extract_64bits(pte, 53, 10) << 12;
                printf("PAGE(4K) ppnx=0x%lx vpnx=0x%lx page_offset=0x%lx\n", ppnx, vpnx, page_offset);
                calc_final_pa(ppnx, vpnx, page_offset);
            }
            return 0;
        }
    } else {
        printf("Unsupport SATP_MODE...\n");
    }

    return 0;
}

/*
SV39:
Please input va: 0xffffffc800212000
Please input satp: 0x8000000000081298
satp_mdoe=0x8 satp_asid=0x0 satp_ppn=0x81298
SATP_MODE_SV39 vpn2=0x120 vpn1=0x1 vpn0=0x12 page_offset=0x0
now pa=0x81298900 please input value of (x/xg 0x81298900): 0x40001001
now pa=0x100004008 please input value of (x/xg 0x100004008): 0x400d6c01
now pa=0x10035b090 please input value of (x/xg 0x10035b090): 0x40000000060040e7
The final PA=0x18010000
*/

/*
SV48:
Please input va: 0xffff8f8000212000
Please input satp: 0x9000000000081298
satp_mdoe=0x9 satp_asid=0x0 satp_ppn=0x81298
SATP_MODE_SV48 vpn3=0x11f vpn2=0x0 vpn1=0x1 vpn0=0x12 page_offset=0x0
now pa=0x812988f8 please input value of (x/xg 0x812988f8): 0x40001001
now pa=0x100004000 please input value of (x/xg 0x100004000): 0x40015401
now pa=0x100055008 please input value of (x/xg 0x100055008): 0x400d6801
now pa=0x10035a090 please input value of (x/xg 0x10035a090): 0x40000000060040e7
The final PA=0x18010000
*/

/*
https://marz.utk.edu/my-courses/cosc130/lectures/virtual-memory/
SV39:
Please input va: 0xdeadbeef
Please input satp: 0x8000000000123456
satp_mdoe=0x8 satp_asid=0x0 satp_ppn=0x123456
SATP_MODE_SV39 vpn2=0x3 vpn1=0xf5 vpn0=0xdb page_offset=0xeef
now pa=0x123456018 please input value of (x/xg 0x123456018): 0x774101
now pa=0x1dd07a8 please input value of (x/xg 0x1dd07a8): 0x2001
now pa=0x86d8 please input value of (x/xg 0x86d8): 0x1700f
The final PA=0x0x5ceef
*/

/*
SV39-2M:
Please input va: 0xffffffd8816d5a00
Please input satp: 0x8000000000081c59
satp_mdoe=0x8 satp_asid=0x0 satp_ppn=0x81c59
SATP_MODE_SV39 vpn2=0x162 vpn1=0xb vpn0=0xd5 page_offset=0xa00
now pa=0x81c59b10 please input value of (x/xg 0x81c59b10): 0x5ffff001
now pa=0x17fffc058 please input value of (x/xg 0x17fffc058): 0x405800e7
HWGEPAGE(2M) ppnx=0x101600000 vpnx=0xd5000 page_offset=0xa00
The final PA=0x1016d5a00
*/

/*
SV48-4K:
Please input va: 0x7ffff674dff8
Please input satp: 0x901f4001004049a9
satp_mdoe=0x9 satp_asid=0x1f4 satp_ppn=0x1004049a9
SATP_MODE_SV48 vpn3=0xff vpn2=0x1ff vpn1=0x1b3 vpn0=0x14d page_offset=0xff8
now pa=0x1004049a97f8 please input value of (x/xg 0x1004049a97f8):0x401_0122f401
now pa=0x1004048bdff8 please input value of (x/xg 0x1004048bdff8):0x401_0122f801
now pa=0x1004048bed98 please input value of (x/xg 0x1004048bed98):0x401_01299001
now pa=0x100404a64a68 please input value of (x/xg 0x100404a64a68):0x401_01f9a4d7
PAGE(4K) ppnx=0x100407e69000 vpnx=0x0 page_offset=0xff8
The final PA=0x100407e69ff8
*/

/*
SV48-1G:
Please input va: 0xffffaf80816d5a00
Please input satp: 0x9000000000081c59
satp_mdoe=0x9 satp_asid=0x0 satp_ppn=0x81c59
SATP_MODE_SV48 vpn3=0x15f vpn2=0x2 vpn1=0xb vpn0=0xd5 page_offset=0xa00
now pa=0x81c59af8 please input value of (x/xg 0x81c59af8): 0x5ffffc01
now pa=0x17ffff010 please input value of (x/xg 0x17ffff010): 0x400000e7
HUGEPAGE(1G) ppnx=0x100000000 vpnx=0x16d5000 page_offset=0xa00
The final PA=0x1016d5a00
*/

/*
SV57-1G:
Please input va: 0xff600000816d7a00
Please input satp: 0xa000000000081c59
satp_mdoe=0xa satp_asid=0x0 satp_ppn=0x81c59
SATP_MODE_SV57 vpn4=0x160 vpn3=0x0 vpn2=0x2 vpn1=0xb vpn0=0xd7 page_offset=0xa00
now pa=0x81c59b00 please input value of (x/xg 0x81c59b00): 0x5ffffc01
now pa=0x17ffff000 please input value of (x/xg 0x17ffff000): 0x5ffff801
now pa=0x17fffe010 please input value of (x/xg 0x17fffe010): 0x400000e7
HUGEPAGE(1G) ppnx=0x100000000 vpnx=0x16d7000 page_offset=0xa00
The final PA=0x1016d7a00
*/
