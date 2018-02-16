SHELL = /bin/sh
CC = gcc
NASM = nasm
CFLAGS += -O3 -flto -Wall -ffast-math -fforce-addr -fstrength-reduce -fno-expensive-optimizations -fschedule-insns2 $(shell pkgconf sdl SDL_mixer --cflags) -std=gnu90
LDFLAGS += $(shell pkgconf sdl SDL_mixer --libs) -lm
RM_F = rm -f

TARGET=fortnight-by-mfx

INSTALL = install
INSTALL_DIR     = $(INSTALL) -p -d -o root -g root  -m  755
INSTALL_FILE    = $(INSTALL) -p    -o root -g root  -m  644
INSTALL_PROGRAM = $(INSTALL) -p    -o root -g root  -m  755

PREFIX = /usr
EXEC_PREFIX     = $(PREFIX)
BINDIR          = $(EXEC_PREFIX)/bin

#si code gcc4 compilé via gcc5 le standard par défaut était different
GCCVERSIONGTEQ5 := $(shell expr `gcc -dumpversion | cut -f1 -d.` \>= 5)
ifeq "$(GCCVERSIONGTEQ5)" "1"
    CFLAGS += -std=gnu90
    CXXFLAGS += -fabi-compat-version=2
endif
ifneq (,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
 NUMJOBS = $(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
 MAKEFLAGS += -j$(NUMJOBS)
endif

export

all: $(TARGET)

clean: 
	-@$(RM_F) *.o *.bak fortnight.bz2 $(TARGET) intro || :;

datat.o: datat.asm
	$(NASM) -f elf datat.asm

main.o: *.c Makefile
	$(CC) -frename-registers $(CFLAGS) -c main.c

$(TARGET): main.o datat.o
	$(CC) -flto main.o datat.o -o $(TARGET) $(LDFLAGS)
	objcopy -R .note -R .comment -R .note.ABI-tag -R .sbss -R .gnu_version -x -g -S $(TARGET)

install: $(TARGET)
	$(INSTALL_DIR) $(DESTDIR)$(BINDIR)
	-@$(RM_F) $(DESTDIR)$(BINDIR)/$(TARGET)
	$(INSTALL_PROGRAM) $(TARGET) $(DESTDIR)$(BINDIR)
