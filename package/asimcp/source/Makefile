.PHONY: all clean

cc := $(CROSS_COMPILE)gcc
CC_srcs:=$(wildcard *.c)
CC_targets:=$(CC_srcs:.c=)
CC_objects:=$(CC_srcs:.c=.o)

cc_flags = -Wall -Wextra -g -ggdb -O3 $(CFLAGS) -Wa,-adhln="${@:.o=.lst}"

targets:=asimcp

all: $(targets)

$(CC_objects): %.o : %.c
	$(cc) -c $(cc_flags) $< -o $@

$(CC_targets): % : $(patsubst %,%.o,%)
	$(cc) $(cc_ldflags) $(LDFLAGS) -o $@ $<

clean:
	-rm $(targets) $(CC_objects)

help:
	@echo Targets:
	@echo
	@echo '		all'
	@echo '		clean'
	@echo
