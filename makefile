#适用于GnuWin32 Make
EXE := main.exe
OBJS := Main.obj

MASM32_DIR := H:\masm32
LIB := $(MASM32_DIR)\lib
INCLUDE := $(MASM32_DIR)\include

ML := $(MASM32_DIR)\bin\ml.exe
LINK := $(MASM32_DIR)\bin\link.exe
RC := $(MASM32_DIR)\bin\rc.exe

LINK_FLAG := /subsystem:CONSOLE /LIBPATH:$(LIB)
ML_FLAG := /c /coff /I$(INCLUDE)

$(EXE): $(OBJS) $(RES)
	$(LINK) $(LINK_FLAG) /out:$(EXE) $(OBJS) $(RES)

%.obj: %.asm
	$(ML) $(ML_FLAG) $<
%.res: %.rc
	$(RC) $<

.PHONY : clean all

all: $(EXE)

clean:
	del *.obj
	del *.res
	del $(EXE)