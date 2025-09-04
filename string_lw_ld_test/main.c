#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>
typedef unsigned long long ull;
extern void *memcpy_lw(void *, const void *, size_t);
extern void *memload_lw(void *, const void *, size_t);
extern void *memset_sw(void *s, int c, size_t n);
#if __riscv_xlen == 64
extern void *memcpy_ld(void *, const void *, size_t);
extern void *memload_ld(void *, const void *, size_t);
extern void *memset_sd(void *s, int c, size_t n);
#endif

ull xprint(struct timeval *start_tv, struct timeval *end_tv, char *str)
{
	ull start_time, end_time;
	ull diff;
	start_time = (ull)(start_tv->tv_sec) * 1000 + (ull)(start_tv->tv_usec) / 1000;
	end_time = (ull)(end_tv->tv_sec) * 1000 + (ull)(end_tv->tv_usec) / 1000;
	printf("=========%s=========\n", str);
	printf("start time: %u ms\n", start_time);
	printf("end   time: %u ms\n", end_time);
	diff = end_time - start_time;
	printf("cost  time: %u ms\n", diff);
	return diff;
}
/*
flag: 0 is memcpy_lw , 1 is memcpy_ld
*/
ull do_cpy(void *desc, const void *src, size_t len, unsigned long loop, int flag)
{
	struct timeval start_tv, end_tv;
	ull diff;
	unsigned long i;
	gettimeofday(&start_tv, NULL);
	for (i = 0; i < loop; i++)
	{
		if (flag)
#if __riscv_xlen == 64
			memcpy_ld(desc, src, len);
#else
			;
#endif
		else
			memcpy_lw(desc, src, len);
	}
	gettimeofday(&end_tv, NULL);
	diff = xprint(&start_tv, &end_tv, flag ? "memcpy_ld" : "memcpy_lw");
	return diff;
}

/*
flag: 0 is memload_lw , 1 is memload_ld
*/
ull do_load(void *desc, const void *src, size_t len, unsigned long loop, int flag)
{
	struct timeval start_tv, end_tv;
	ull diff;
	unsigned long i;
	gettimeofday(&start_tv, NULL);
	for (i = 0; i < loop; i++)
	{
		if (flag)
#if __riscv_xlen == 64
			memload_ld(desc, src, len);
#else
			;
#endif
		else
			memload_lw(desc, src, len);
	}
	gettimeofday(&end_tv, NULL);
	diff = xprint(&start_tv, &end_tv, flag ? "memload_ld" : "memload_lw");
	return diff;
}

unsigned long do_mem_set(void *src, int c, size_t n, unsigned long loop, int flag)
{
	struct timeval start_tv, end_tv;
	ull diff;
	unsigned long i;
	gettimeofday(&start_tv, NULL);
	for (i = 0; i < loop; i++)
	{
		if (flag)
#if __riscv_xlen == 64
			memset_sd(src, c, n);
#else
			;
#endif
		else
			memset_sw(src, c, n);
	}
	gettimeofday(&end_tv, NULL);
	diff = xprint(&start_tv, &end_tv, flag ? "memset_sd" : "memset_sw");
	printf("^ mem_set: %d \n", c);
	return diff;
}

int main(int argc, char **argv)
{
	unsigned long opt;
	unsigned long loop_num = 1000;
	unsigned long mem = 1;
	long optval = 0;
	ull diff_lw, diff_ld;
	double elapsed_time;
	unsigned long size;
	double percent;

	while ((opt = getopt(argc, argv, "m:c:h")) != -1)
	{
		switch (opt)
		{
		case 'c':
			optval = strtol(optarg, (char **)NULL, 10);
			if (optval >= 1000)
				loop_num = optval;
			break;
		case 'm':
			optval = strtol(optarg, (char **)NULL, 10);
			mem = optval;
			break;
		case 'h':
			printf("mem_test\n");
			printf("-h\n");
			printf("-m memory size,unit is KB\n");
			printf("-c loop num  Need to be larger than 1000\n");
			break;
		default:
			break;
		}
	}

	size = mem * 1024;
	printf("malloc memory: %u KB\n", mem);
	printf("loop: %u \n", loop_num);

	void *src = malloc(size);
	void *desc = malloc(size);

	diff_lw = do_cpy(desc, src, size, loop_num, 0);
	diff_ld = do_cpy(desc, src, size, loop_num, 1);
	percent = (diff_lw - diff_ld) / (diff_ld + 0.0d);
	printf("%u loop and %u KB memcpy update percent: %f \n", loop_num, mem, percent);

	diff_lw = do_load(desc, src, size, loop_num, 0);
	diff_ld = do_load(desc, src, size, loop_num, 1);
	percent = (diff_lw - diff_ld) / (diff_ld + 0.0d);
	printf("%u loop and %u KB memload update percent: %f \n", loop_num, mem, percent);

	diff_lw = do_mem_set(src, 123456, size, loop_num, 0);
	diff_ld = do_mem_set(src, 123456, size, loop_num, 1);
	percent = (diff_lw - diff_ld) / (diff_ld + 0.0d);
	printf("%u loop and %u KB memset update percent: %f \n", loop_num, mem, percent);

	free(desc);
	free(src);
	return 0;
}