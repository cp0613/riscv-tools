def compare_strings(str1, str2):
    # 分割字符串为单词列表
    words1 = str1.split('_')
    words2 = str2.split('_')

    # 创建集合用于快速查找
    set2 = set(words2)
    set1 = set(words1)

    # 找出第一个字符串中独有的单词（保留原始顺序）
    unique1 = [word for word in words1 if word not in set2]

    # 找出第二个字符串中独有的单词（保留原始顺序）
    unique2 = [word for word in words2 if word not in set1]

    # 打印结果
    if unique1:
        print("First string unique part:", "_".join(unique1), "\n")
    if unique2:
        print("Second string unique part:", "_".join(unique2), "\n")
    if not unique1 and not unique2:
        print("No differences found - the strings are identical")

# 示例用法
if __name__ == "__main__":
    str1 = "rv64imafdcvh_zic64b_zicbom_zicbop_zicboz_ziccamoa_ziccamoc_ziccif_zicclsm_ziccrse_zicfilp_zicfiss_zicntr_zicond_zicsr_zifencei_zihintntl_zihintpause_zihpm_zimop_zmmul_za64rs_zabha_zacas_zalasr_zama16b_zawrs_zfa_zfbfmin_zfh_zfhmin_zca_zcb_zcd_zcmop_zba_zbb_zbc_zbs_zkr_zkt_ssdtso_zvbb_zvbc_zvbc32e_zve32f_zve32x_zve64d_zve64f_zve64x_zvfbfmin_zvfbfwma_zvfh_zvfhmin_zvkb_zvkg_zvkgs_zvkn_zvknc_zvkned_zvkng_zvknha_zvknhb_zvks_zvksc_zvksed_zvksg_zvksh_zvkt_zvl128b_zvl32b_zvl64b_zvqdotq_shcounterenw_shgatpa_shtvala_shvsatpa_shvstvala_shvstvecd_smaia_smcdeleg_smcntrpmf_smcsrind_smctr_smepmp_smmpm_smmtt_smnpm_smrnmi_smstateen_ssaia_ssccfg_ssccptr_sscofpmf_sscounterenw_sscsrind_ssctr_ssdbltrp_ssnpm_sspm_ssqosid_ssstateen_ssstrict_sstc_sstvala_sstvecd_ssu64xl_supm_svadu_svbare_svinval_svnapot_svpbmt_svvptc_xtheadcbop_xtheadvarith_xtheadvcoder_xtheadvcrypto_xtheadvdot_xtheadser"

    str2 = "rv64imacfdbv_zicbom_zicntr_zicond_zicsr_zifencei_zihintpause_zihpm_zawrs_zacas_zabha_ziccrse_zba_zbb_zbs_zkt_smaia_smctr_smstateen_smcsrind_ssaia_sscsrind_ssctr_sstc_svinval_svnapot_svpbmt"

    compare_strings(str1, str2)
