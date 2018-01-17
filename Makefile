C64SYS?=c64
C64AS?=ca65
C64LD?=ld65
VICE?=x64sc

C64ASFLAGS?=-t $(C64SYS) -g
C64LDFLAGS?=-m xeyes.map -Csrc/xeyes.cfg

xeyes_OBJS:=$(addprefix obj/,main.o)
xeyes_BIN:=xeyes.prg
xeyes_LABLES:=xeyes.lbl

all: $(xeyes_BIN) $(xeyes_LABLES)

run: all
	$(VICE) -autoload $(xeyes_BIN) -moncommands $(xeyes_LABLES) \
		-controlport1device 3 -keybuf 'sys49152\n'

$(xeyes_BIN) $(xeyes_LABLES): $(xeyes_OBJS)
	$(C64LD) -Ln $(xeyes_LABLES) -o$(xeyes_BIN) $(C64LDFLAGS) $^

obj:
	mkdir obj

obj/%.o: src/%.s src/xeyes.cfg Makefile | obj
	$(C64AS) $(C64ASFLAGS) -o$@ $<

clean:
	rm -fr obj *.lbl *.map

distclean: clean
	rm -f $(xeyes_BIN)

.PHONY: all run clean distclean

