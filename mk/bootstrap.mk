# -----------------------------------------------------------------------------
# $Id: bootstrap.mk,v 1.2 2001/03/26 16:58:09 simonmar Exp $
#
# Makefile rules for booting from .hc files without a driver.
#

TOP_SAVED := $(TOP)
TOP:=$(TOP)/ghc

include $(FPTOOLS_TOP_ABS)/ghc/mk/version.mk
include $(FPTOOLS_TOP_ABS)/ghc/mk/paths.mk

# Reset TOP
TOP:=$(TOP_SAVED)

# -----------------------------------------------------------------------------
# Set the platform-specific options to send to the C compiler.  These should
# match the list in machdepCCOpts in ghc/compiler/DriverFlags.hs.
#

PLATFORM_CC_OPTS =
PLATFORM_HC_BOOT_CC_OPTS =

ifeq "$(i386_TARGET_ARCH)" "1"
PLATFORM_CC_OPTS += -DDONT_WANT_WIN32_DLL_SUPPORT
PLATFORM_HC_BOOT_CC_OPTS += -fno-defer-pop -fomit-frame-pointer 
endif

ifeq "$(hppa_TARGET_ARCH)" "1"
PLATFORM_CC_OPTS += -static -D_HPUX_SOURCE
endif

ifeq "$(powerpc_TARGET_ARCH)" "1"
PLATFORM_CC_OPTS += -static
PLATFORM_HC_BOOT_CC_OPTS += -finhibit-size-directive
endif

ifeq "$(rs6000_TARGET_ARCH)" "1"
PLATFORM_CC_OPTS += -static
PLATFORM_HC_BOOT_CC_OPTS += -static -finhibit-size-directive
endif

ifeq "$(mingw32_TARGET_OS)" "1"
PLATFORM_CC_OPTS += -mno-cygwin
endif

PLATFORM_CC_OPTS += -D__GLASGOW_HASKELL__=$(ProjectVersionInt) 

HC_BOOT_CC_OPTS = $(PLATFORM_HC_BOOT_CC_OPTS) $(CC_OPTS)

SRC_CC_OPTS += -I$(FPTOOLS_TOP_ABS)/ghc/includes -I$(FPTOOLS_TOP_ABS)/ghc/lib/std/cbits -I$(FPTOOLS_TOP_ABS)/hslibs/lang/cbits -I$(FPTOOLS_TOP_ABS)/hslibs/posix/cbits -I$(FPTOOLS_TOP_ABS)/hslibs/util/cbits -I$(FPTOOLS_TOP_ABS)/hslibs/text/cbits -I$(FPTOOLS_TOP_ABS)/hslibs/hssource/cbits

# -----------------------------------------------------------------------------
# Linking: we have to give all the libraries explicitly.

HC_BOOT_LD_OPTS =				\
   -L$(FPTOOLS_TOP_ABS)/ghc/rts			\
   -L$(FPTOOLS_TOP_ABS)/ghc/lib/std		\
   -L$(FPTOOLS_TOP_ABS)/ghc/lib/std/cbits	\
   -L$(FPTOOLS_TOP_ABS)/hslibs/lang		\
   -L$(FPTOOLS_TOP_ABS)/hslibs/lang/cbits	\
   -L$(FPTOOLS_TOP_ABS)/hslibs/text		\
   -u "PrelBase_Izh_static_info"		\
   -u "PrelBase_Czh_static_info"		\
   -u "PrelFloat_Fzh_static_info"		\
   -u "PrelFloat_Dzh_static_info"		\
   -u "PrelPtr_Ptr_static_info"			\
   -u "PrelWord_Wzh_static_info"		\
   -u "PrelInt_I8zh_static_info"		\
   -u "PrelInt_I16zh_static_info"		\
   -u "PrelInt_I32zh_static_info"		\
   -u "PrelInt_I64zh_static_info"		\
   -u "PrelWord_W8zh_static_info"		\
   -u "PrelWord_W16zh_static_info"		\
   -u "PrelWord_W32zh_static_info"		\
   -u "PrelWord_W64zh_static_info"		\
   -u "PrelStable_StablePtr_static_info"	\
   -u "PrelBase_Izh_con_info"			\
   -u "PrelBase_Czh_con_info"			\
   -u "PrelFloat_Fzh_con_info"			\
   -u "PrelFloat_Dzh_con_info"			\
   -u "PrelPtr_Ptr_con_info"			\
   -u "PrelStable_StablePtr_con_info"		\
   -u "PrelBase_False_closure"			\
   -u "PrelBase_True_closure"			\
   -u "PrelPack_unpackCString_closure"		\
   -u "PrelIOBase_stackOverflow_closure"	\
   -u "PrelIOBase_heapOverflow_closure"		\
   -u "PrelIOBase_NonTermination_closure"	\
   -u "PrelIOBase_BlockedOnDeadMVar_closure"	\
   -u "PrelWeak_runFinalizzerBatch_closure"	\
   -u "__init_Prelude"				\
   -u "PrelMain_mainIO_closure"			\
   -u "__init_PrelMain"

HC_BOOT_LIBS = -lHStext -lHSlang -lHSstd -lHSstd_cbits -lHSrts -lgmp $(EXTRA_HC_BOOT_LIBS)

# -----------------------------------------------------------------------------
# suffix rules for building a .o from a .hc file.

%.raw_s : %.hc
	$(CC) -x c $< -o $@ -S -O $(HC_BOOT_CC_OPTS) -I.  `echo $(patsubst -monly-%-regs, -DSTOLEN_X86_REGS=%, $(filter -monly-%-regs, $($*_HC_OPTS))) | sed 's/^$$/-DSTOLEN_X86_REGS=4/'`

%.s : %.raw_s
	$(GHC_MANGLER) $< $@ $(patsubst -monly-%-regs, %, $(filter -monly-%-regs, $($*_HC_OPTS)))

%.o : %.s
	$(CC) -c -o $@ $<
