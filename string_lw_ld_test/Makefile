#CC=riscv32-linux-gcc
CC=riscv64-linux-gcc

objects := main.o memcpy_ld.o memcpy_lw.o memset_ld.o memset_lw.o memload_ld.o memload_lw.o
clean_objects := $(foreach obj, $(objects), $(obj))

all:test_mem
	@echo all


test_mem:$(objects)
	${CC} -static -o $@ $^

%.o:%.S
	${CC} -c $< -o $@

%.o:%.c
	${CC} -c $< -o $@

clean:
	rm -f $(clean_objects) test_mem