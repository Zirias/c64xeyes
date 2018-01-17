C64SYS?=c64
C64AS?=ca65
C64LD?=ld65

C64ASFLAGS?=-t $(C64SYS) -g
C64LDFLAGS?=-Ln xeyes.lbl -m xeyes.map -Csrc/xeyes.cfg

xeyes_OBJS:=$(addprefix obj/,main.o)
xeyes_BIN:=xeyes.prg

all: $(xeyes_BIN)

$(xeyes_BIN): $(xeyes_OBJS)
	$(C64LD) -o$@ $(C64LDFLAGS) $^

obj:
	mkdir obj

obj/%.o: src/%.s src/xeyes.cfg Makefile | obj
	$(C64AS) $(C64ASFLAGS) -o$@ $<

clean:
	rm -fr obj *.lbl *.map

distclean: clean
	rm -f $(xeyes_BIN)

.PHONY: all clean distclean

