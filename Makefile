BUILD ?= release
MODEL ?= $(shell getconf LONG_BIT)

ifneq ($(MODEL), 32)
	ifneq ($(MODEL), 64)
		$(error Unsupported architecture: $(MODEL))
	endif
endif

ifneq ($(BUILD), debug)
	ifneq ($(BUILD), release)
		$(error Unknown build mode: $(BUILD))
	endif
endif

DFLAGS = -lib -w -wi -property -m$(MODEL)

ifeq ($(BUILD), release)
	DFLAGS += -release -O -inline -noboundscheck
	LIBNAME = xchatd
else
	DFLAGS += -debug -g
	LIBNAME = xchatd-d
endif

ifeq ($(MODEL), 32)
	OUTDIR = lib32
else
	OUTDIR = lib
endif

XCHATD_SOURCES = source/xchat/plugin.d source/xchat/capi.d

all: $(OUTDIR)/$(LIBNAME).lib

.PHONY : clean

clean:
	-rm $(OUTDIR)/$(LIBNAME).lib

$(OUTDIR)/$(LIBNAME).lib: $(XCHATD_SOURCES)
	dmd $(DFLAGS) -of"$@" $^
