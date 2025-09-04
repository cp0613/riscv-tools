# pmp_check

1. 通过gdb dump pmp相关寄存器
```
i r mseccfg
i r pmpcfg0
i r pmpcfg2
i r pmpaddr0 pmpaddr1 pmpaddr2 pmpaddr3 pmpaddr4 pmpaddr5 pmpaddr6 pmpaddr7 pmpaddr8 pmpaddr9 pmpaddr10 pmpaddr11 pmpaddr12 pmpaddr13 pmpaddr14 pmpaddr15
```

2. 修改`pmp_check.py`中的`mseccfg`、`pmpcfg0`、`pmpcfg2`、`pmpaddr_vals`和`tests`

3. 执行`python3 pmp_check.py`查看pmp配置情况和`tests`的权限判定结果
