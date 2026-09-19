// mtdnor.c (Fase D-2a') — escribir una imagen en /dev/mtdN con verificación.
// Uso: mtdnor <mtdN> <archivo-imagen> [verify]
//   sin "verify": erase + write + readback byte-a-byte + reporte
//   con "verify" : SOLO compara el contenido actual del mtd contra el archivo (sin escribir)
// Compilar: mips-mti-linux-gnu-gcc -mips32r2 -EL -static
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <mtd/mtd-user.h>

static int sha_ok(const char *path) { return 0; } /* placeholder — verificación es memcmp */

int main(int argc, char **argv)
{
	const char *mtddev, *imgpath;
	int verify_only = (argc >= 4 && !strcmp(argv[3], "verify"));
	if (argc < 3) {
		fprintf(stderr, "Uso: %s <mtdN> <archivo-imagen> [verify]\n", argv[0]);
		return 2;
	}
	mtddev = argv[1];
	imgpath = argv[2];

	int fd = open(mtddev, O_SYNC | O_RDWR);
	if (fd < 0) { perror("open mtd"); return 1; }

	mtd_info_t info;
	if (ioctl(fd, MEMGETINFO, &info) != 0) { perror("MEMGETINFO"); close(fd); return 1; }
	printf("mtd: size=%u erasesize=%u writesize=%u\n", info.size, info.erasesize, info.writesize);

	int fdi = open(imgpath, O_RDONLY);
	if (fdi < 0) { perror("open imagen"); close(fd); return 1; }
	struct stat st;
	if (fstat(fdi, &st) != 0) { perror("fstat imagen"); close(fdi); close(fd); return 1; }
	if ((size_t)st.st_size > info.size) {
		fprintf(stderr, "ERROR: imagen (%lld B) > mtd (%u B)\n", (long long)st.st_size, info.size);
		close(fdi); close(fd); return 1;
	}
	unsigned char *img = malloc(st.st_size);
	if (!img) { fprintf(stderr, "OOM\n"); close(fdi); close(fd); return 1; }
	if (read(fdi, img, st.st_size) != st.st_size) { perror("read imagen"); close(fdi); close(fd); return 1; }
	close(fdi);
	printf("imagen: %s (%lld B)\n", imgpath, (long long)st.st_size);

	if (!verify_only) {
		/* 1) borrar el rango necesario */
		size_t eraselen = ((size_t)st.st_size + info.erasesize - 1) & ~(size_t)(info.erasesize - 1);
		printf("erase: %zu B (%zu bloques de %u)...\n", eraselen, eraselen / info.erasesize, info.erasesize);
		for (size_t off = 0; off < eraselen; off += info.erasesize) {
			erase_info_t ei;
			memset(&ei, 0, sizeof(ei));
			ei.start = off;
			ei.length = info.erasesize;
			if (ioctl(fd, MEMERASE, &ei) != 0) {
				fprintf(stderr, "ERROR MEMERASE @0x%zx: %s\n", off, strerror(errno));
				close(fd); return 1;
			}
			if ((off / info.erasesize) % 16 == 0) { printf("\rerase %zu/%zu", off, eraselen); fflush(stdout); }
		}
		printf("\nerase OK\n");

		/* 2) escribir */
		printf("write...\n");
		if (lseek(fd, 0, SEEK_SET) != 0) { perror("lseek"); close(fd); return 1; }
		size_t written = 0;
		while (written < (size_t)st.st_size) {
			ssize_t n = write(fd, img + written, st.st_size - written);
			if (n <= 0) { fprintf(stderr, "ERROR write @%zu: %s\n", written, strerror(errno)); close(fd); return 1; }
			written += n;
		}
		printf("write OK (%zu B)\n", written);
	}

	/* 3) readback byte-a-byte */
	printf("readback-verify...\n");
	if (lseek(fd, 0, SEEK_SET) != 0) { perror("lseek r"); close(fd); return 1; }
	unsigned char *buf = malloc(st.st_size);
	if (!buf) { close(fd); return 1; }
	size_t got = 0;
	while (got < (size_t)st.st_size) {
		ssize_t n = read(fd, buf + got, st.st_size - got);
		if (n <= 0) { fprintf(stderr, "ERROR read @%zu\n", got); close(fd); return 1; }
		got += n;
	}
	if (memcmp(buf, img, st.st_size) != 0) {
		for (size_t i = 0; i < (size_t)st.st_size; i++)
			if (buf[i] != img[i]) { fprintf(stderr, "MISMATCH en 0x%zx: %02x != %02x\n", i, buf[i], img[i]); break; }
		close(fd); return 1;
	}
	printf("VERIFY OK — mtd == imagen byte-a-byte (%lld B)\n", (long long)st.st_size);
	close(fd);
	printf("%s COMPLETO\n", verify_only ? "VERIFY-ONLY" : "ERASE+WRITE+VERIFY");
	return 0;
}
