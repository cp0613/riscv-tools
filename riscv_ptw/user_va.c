#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <termios.h>

#define MEM_SIZE (4 * 1024) // 4KB 内存区域
#define PROTECTION (PROT_READ | PROT_WRITE) // 可读可写
#define FLAGS (MAP_PRIVATE | MAP_ANONYMOUS) // 私有匿名映射

// 设置终端为原始模式（直接读取按键，不需要按回车）
void set_terminal_raw() {
    struct termios term;
    tcgetattr(STDIN_FILENO, &term);
    term.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &term);
}

// 恢复终端原始设置
void reset_terminal() {
    struct termios term;
    tcgetattr(STDIN_FILENO, &term);
    term.c_lflag |= (ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &term);
}

// 等待用户按键
void wait_for_key(const char *prompt) {
    printf("%s", prompt);
    fflush(stdout);
    
    set_terminal_raw(); // 设置终端为原始模式
    getchar();          // 等待任意按键
    reset_terminal();   // 恢复终端设置
    
    printf("\n");
}

int main()
{
    printf("=== 内存申请与读写演示程序 ===\n\n");

    /******************************************
     * 方法1: 使用标准库函数 malloc 申请内存
     ******************************************/
    printf("方法1: 使用 malloc 申请内存\n");

    // 申请内存
    printf("> 申请内存中...\n");
    char *malloc_ptr = (char *)malloc(MEM_SIZE);
    if (!malloc_ptr) {
        perror("malloc 失败");
        exit(EXIT_FAILURE);
    }
    printf("✓ 申请成功! 内存地址: %p\n", (void *)malloc_ptr);

    // 申请成功后暂停
    wait_for_key("> 按任意键继续（申请完成）...");

    // 写入数据
    printf("> 写入数据到内存...\n");
    const char *message = "Hello, malloc memory!";
    strncpy(malloc_ptr, message, strlen(message) + 1);
    printf("✓ 写入数据: \"%s\"\n", message);

    // 写入后暂停
    wait_for_key("> 按任意键继续（写入完成）...");

    // 读取数据
    printf("> 从内存读取数据...\n");
    printf("✓ 读取数据: \"%s\"\n", malloc_ptr);

    // 读取后暂停
    wait_for_key("> 按任意键释放内存...");

    // 释放内存
    free(malloc_ptr);
    printf("✓ 内存已释放\n");

    wait_for_key("> 按任意键进入下一个方法...");

    /******************************************
     * 方法2: 使用系统调用 mmap 申请内存
     ******************************************/
    printf("\n方法2: 使用 mmap 申请内存\n");

    // 申请内存
    printf("> 通过 mmap 系统调用申请内存...\n");
    char *mmap_ptr = (char *)mmap(NULL, MEM_SIZE, PROTECTION, FLAGS, -1, 0);
    if (mmap_ptr == MAP_FAILED) {
        perror("mmap 失败");
        exit(EXIT_FAILURE);
    }
    printf("✓ 申请成功! 内存地址: %p\n", (void *)mmap_ptr);

    // 申请成功后暂停
    wait_for_key("> 按任意键继续（申请完成）...");

    // 写入数据
    printf("> 写入数据到内存...\n");
    const char *mmap_message = "Hello, mmap memory!";
    strncpy(mmap_ptr, mmap_message, strlen(mmap_message) + 1);
    printf("✓ 写入数据: \"%s\"\n", mmap_message);

    // 写入后暂停
    wait_for_key("> 按任意键继续（写入完成）...");

    // 读取数据
    printf("> 从内存读取数据...\n");
    printf("✓ 读取数据: \"%s\"\n", mmap_ptr);

    // 读取后暂停
    wait_for_key("> 按任意键测试写入大块数据...");

    // 写入大块数据
    printf("> 写入大量数据（4KB内存填充'A'字符）...\n");
    memset(mmap_ptr, 'A', MEM_SIZE - 1);
    mmap_ptr[MEM_SIZE - 1] = '\0'; // 确保字符串终止
    printf("✓ 写入完成! 首字节: '%c', 尾字节: '%c'\n", mmap_ptr[0], mmap_ptr[MEM_SIZE - 2]);

    // 写入后暂停
    wait_for_key("> 按任意键释放内存...");

    // 释放内存
    if (munmap(mmap_ptr, MEM_SIZE) == -1) {
        perror("munmap 失败");
        exit(EXIT_FAILURE);
    }
    printf("✓ 内存已释放\n");

    wait_for_key("> 按任意键进入下一个方法...");

    /******************************************
     * 方法3: 使用 calloc 申请并初始化内存
     ******************************************/
    printf("\n方法3: 使用 calloc 申请并初始化内存\n");

    // 申请内存
    printf("> 申请并初始化内存为0...\n");
    int *calloc_ptr = (int *)calloc(10, sizeof(int));
    if (!calloc_ptr) {
        perror("calloc 失败");
        exit(EXIT_FAILURE);
    }
    printf("✓ 申请成功! 内存地址: %p\n", (void *)calloc_ptr);

    // 申请成功后暂停
    wait_for_key("> 按任意键继续（申请完成）...");

    // 显示初始值
    printf("> 显示初始值（应为全0）...\n");
    printf("初始值: ");
    for (int i = 0; i < 10; i++) {
        printf("%d ", calloc_ptr[i]);
    }
    printf("\n");

    wait_for_key("> 按任意键写入数据...");
    
    // 写入数据
    printf("> 写入平方值到数组...\n");
    for (int i = 0; i < 10; i++) {
        calloc_ptr[i] = i * i; // 平方值
    }
    printf("✓ 写入完成!\n");

    // 写入后暂停
    wait_for_key("> 按任意键继续（写入完成）...");

    // 读取数据
    printf("> 读取数据...\n");
    printf("读取数据: ");
    for (int i = 0; i < 10; i++) {
        printf("%d ", calloc_ptr[i]);
    }
    printf("\n");

    // 读取后暂停
    wait_for_key("> 按任意键释放内存并结束程序...");

    // 释放内存
    free(calloc_ptr);
    printf("✓ 内存已释放\n");

    printf("\n=== 程序执行完毕 ===\n");
    return 0;
}
