/* SPDX-License-Identifier: BSD-3-Clause
 * Copyright(C) 2019 Marvell.
 */
#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define READ_BUFFER_SIZE (2 * 1024 * 1024)

void dbg_print(const char *format, ...) __attribute__((format(printf, 1, 2)));


static uint64_t magic_halt(uint64_t op_num, uint64_t arg1, uint64_t arg2,
			     uint64_t arg3, uint64_t arg4)
{
	dbg_print("Magic Halt op: %lx arg: 0x%lx \n", op_num, arg1);
	asm volatile ("mov x0, %1 \n\t"          /* x0 = op_num */
		      "mov x1, %2 \n\t"          /* x1 = arg1 */
		      "mov x2, %3 \n\t"          /* x2 = arg2 */
		      "mov x3, %4 \n\t"          /* x1 = arg3 */
		      "mov x4, %5 \n\t"          /* x1 = arg4 */
		      "mov x6, 0  \n\t"
		      "mov x7, 0  \n\t"
		      "mov x8, 0  \n\t"
		      "hlt 0xf000 \n\t"
		      "mov %0, x0 \n\t"          /* number = x0 */
		      : "+r" (op_num)            /* Outputs */
		      :			    /* Inputs */
		      "r" (op_num), "r" (arg1), "r" (arg2), "r" (arg3), "r" (arg4)
		      : "x0", "x1", "x2", "x3", "x4", "x5", "x6", "x7", "x8","memory", "cc");

	return op_num;
}

#define MAGIC_FILE_FLAGS_O_RDONLY 0x0
#define MAGIC_FILE_FLAGS_O_CREATE 0x1
#define MAGIC_FILE_FLAGS_O_RDWR   0x4
#define MAGIC_FILE_FLAGS_O_APPEND 0xc

#define MAGIC_FILE_FLAGS_O_STDOUT 0x4 /* only valid if fname is ":tt" */

/* Opens file from host of name fname  returns fd > 0 if success */
static int magic_open(char *fname)
{
	int file_open_op_num = 0x0001;
	uint64_t file_open_desc[3];
	int fd;

	file_open_desc[0] = (uint64_t)fname;
	file_open_desc[1] = MAGIC_FILE_FLAGS_O_RDONLY;
	file_open_desc[2] = strlen(fname);

	fd = magic_halt(file_open_op_num, (uint64_t)file_open_desc, 0, 0, 0);

	return fd;
}

/* read dat from file, returns number of count bytes munus number of   bytes read */
static uint64_t magic_read(int fd, void* buf, uint64_t count)
{
	const int file_read_op_num = 0x0006;
	uint64_t file_read_desc[4];
	uint64_t read;

	file_read_desc[0] = fd;
	file_read_desc[1] = (uint64_t)buf;
	file_read_desc[2] = count;
	file_read_desc[3] = 0; /* Unknown field */

	read = magic_halt(file_read_op_num, (uint64_t)file_read_desc, 0, 0, 0);

	return read;
}

/* read dat from file, return number of bytes read */
uint64_t magic_stat(int fd)
{
	const int file_stat_op_num = 0x000c;
	uint64_t file_stat_desc[1];
	uint64_t size;

	file_stat_desc[0] = fd;

	size = magic_halt(file_stat_op_num, (uint64_t)file_stat_desc, 0, 0, 0);

	return size;
}

/* close file opened with magic_open */
static int magic_close(int fd)
{
	const int file_close_op = 0x0002;
	uint64_t file_close_desc[1];
	int ret;

	file_close_desc[0] = fd;

	ret = magic_halt(file_close_op, (uint64_t)file_close_desc, 0, 0, 0);

	return ret;
}

static char *host_fname  =  "/tmp/a.out";
static char *guest_fname =  "/tmp/a.out";
static int  overwrite_guest_file = 0;
static int64_t arg_buf_size = 0;
static int debug = 0;

void dbg_print(const char *format, ...)
{
	va_list va;
	va_start(va, format);

	if (debug)
		vprintf(format, va);
	va_end(va);
}

void help(int argc, char **argv)
{
	static char usage[] =
	"Usage: %s [options] [SRC] [DSR]\n"
	"Copies SRC(/tmp/a.out) from guest to DST(/tmp/.aut) using asim backdor\n"
	"\n"
	"Options:\n"
	"-b --buffer-size SIZE         Size of buffer allocated for file transfer \n"
	"			             default [2097152 or file_size if it's less]\n"
	"-d --debug                    print executing operations, default=no\n"
	"-o --overwrite                Overwrite guest FILE if exists, default=no\n"
	"-h --help                     Display this text and exit\n"
	;
	(void) argc;
	fprintf(stderr, usage, argv[0]);
}

void parse_options(int argc, char **argv)
{
	int arg_left;
	int c;


	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			/* option   , arg req,  flag, value */
			{"buffer-size",   0,     0,  'b' },
			{"debug",         0,     0,  'd' },
			{"help",          0,     0,  'h' },
			{"overwrite",     1,     0,  'o' },
			{NULL,            0,     0,  0   }
		};

		c = getopt_long(argc, argv, "b:dho",
			long_options, &option_index);
		if (c == -1)
			break;
		switch (c) {
		case 'b':
			arg_buf_size = strtol(optarg, NULL, 10);
			if (arg_buf_size < 1) {
				fprintf(stderr, "Invalid buffer-size %ld\n", arg_buf_size);
				help(argc, argv);
				exit(1);
			}
			break;
		case 'd':
			debug = 1;
			break;
		case 'h':
			help(argc, argv);
			exit(0);
			break;

		case 'o':
			overwrite_guest_file = 1;
			break;

		case '?':
			break;

		default:
			printf("?? getopt returned character code 0%o ??\n", c);
			break;
		}
	}
	arg_left = argc - optind;
	if (arg_left <= 0)
		return;
	if (arg_left > 2) {
		fprintf(stderr, "To many augments\n");
		help(argc, argv);
		exit(1);
	}
	if (arg_left == 1) {
		host_fname  = strdup(argv[optind]);
		guest_fname = strdup(argv[optind]);
		return;
	}
	host_fname  = strdup(argv[optind]);
	guest_fname = strdup(argv[optind + 1]);

}

int main(int argc, char **argv)
{
	mode_t mode = S_IRWXU | S_IRGRP | S_IROTH;
	int eof = 0, i  = 0, read, open_flags;
	int host_fd, guest_fd, ret = 0;
	uint64_t buf_size, file_size;
	uint64_t total_read = 0;
	uint64_t read_res = 0;
	char *buf;

	parse_options(argc, argv);

	open_flags =  O_CREAT | O_EXCL | O_WRONLY;
	if (overwrite_guest_file)
		open_flags =  O_CREAT | O_WRONLY | O_TRUNC;

	guest_fd = open(guest_fname, open_flags, mode);
	if(guest_fd < 0) {
		printf("Error %d opening guest file %s file exist %s\n",
			guest_fd, guest_fname, strerror(errno));
		exit(1);
	}

	host_fd = magic_open(host_fname);
	if (host_fd < 0) {
		printf("Error %d opening host file %s \n", guest_fd, host_fname);
		ret = EACCES;
		goto exit;
	}

	file_size = magic_stat(host_fd);

	buf_size = file_size > READ_BUFFER_SIZE ? READ_BUFFER_SIZE : file_size;
	if (arg_buf_size)
		buf_size = arg_buf_size;

	dbg_print("%s size %lu buf_size %lu \n", guest_fname, file_size, buf_size);

	buf = (char*) malloc(buf_size);
	if (!buf) {
		printf("Error allocation memory closing file %s %d\n", host_fname, host_fd);
		ret = ENOMEM;
		goto exit;
	}

	while (!eof) {
		read_res = magic_read(host_fd, buf, buf_size);
		read = buf_size - read_res;
		total_read += read;
		eof = (total_read == file_size);

		if (total_read > file_size)
			printf("Critical error total_read > file_size "
			       "%lu > %lu \n", total_read, file_size);

		dbg_print("Read %d magic_read %ld  eof %d  total_read %lu "
			  "iter %d \n", read, read_res, eof, total_read, i);

		int wrote = 0, wr_pos = 0;

		while (wr_pos < read) {
			wrote = write(guest_fd, buf + wr_pos,
				      read - wr_pos);
			if (wrote < 0) {
				if (errno == EAGAIN || EINTR) {
					continue;
				}
				ret = wrote;
				printf("Error writing to file %s\n", guest_fname);
				goto exit_free;
			}
			wr_pos += wrote;
		}
		dbg_print("Wrote %d   iter %d \n", read, i);
		i++;
	}

exit_free:
	free(buf);
exit:
	(void)close(guest_fd);

	ret |= magic_close((uint64_t)host_fd);
	if (ret < 0) {
		printf("Error closing file %s %d\n", host_fname, host_fd);
		exit(ret);
	}

	return 0;
}
