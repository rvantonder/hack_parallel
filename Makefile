################################################################################
#                            Variables to override                             #
################################################################################

INTERNAL_MODULES=src/stubs

################################################################################
#                              OS-dependent stuff                              #
################################################################################

ifeq ($(UNAME_S), Linux)
  INOTIFY=src/third-party/inotify
  INOTIFY_STUBS=$(INOTIFY)/inotify_stubs.c
  FSNOTIFY=src/fsnotify_linux
  FSNOTIFY_STUBS=
  RT=rt
  FRAMEWORKS=
  EXE=
endif
ifeq ($(UNAME_S), Darwin)
  INOTIFY=src/fsevents
  INOTIFY_STUBS=$(INOTIFY)/fsevents_stubs.c
  FSNOTIFY=src/fsnotify_darwin
  FSNOTIFY_STUBS=
  RT=
  FRAMEWORKS=CoreServices CoreFoundation
  EXE=
endif
ifeq ($(UNAME_S), Windows)
  INOTIFY=
  INOTIFY_STUBS=
  FSNOTIFY=src/fsnotify_win
  FSNOTIFY_STUBS=$(FSNOTIFY)/fsnotify_stubs.c
  RT=
  FRAMEWORKS=
  EXE=.exe
endif

################################################################################
#                                 Definitions                                  #
################################################################################

MODULES=\
  src/third-party/lz4\
  src/heap\
  src/injection/default_injector\
  src/procs\
  src/socket\
  src/third-party/hack_core\
  src/utils\
  src/utils/collections\
  src/utils/disk\
  src/utils/hh_json\
  $(INOTIFY)\
  $(FSNOTIFY)\
  $(INTERNAL_MODULES)

NATIVE_C_FILES=\
  $(INOTIFY_STUBS)\
  $(FSNOTIFY_STUBS)\
  src/heap/hh_shared.c\
  src/utils/files.c\
  src/utils/handle_stubs.c\
  src/utils/nproc.c\
  src/utils/realpath.c\
  src/utils/sysinfo.c\
  src/utils/priorities.c\
  $(sort $(wildcard src/third-party/lz4/*.c))

NATIVE_LIBRARIES=\
  hp\
  pthread\
  $(RT)

################################################################################
#                                    Rules                                     #
################################################################################

NATIVE_C_DIRS=$(patsubst %/,%,$(sort $(dir $(NATIVE_C_FILES))))
ALL_HEADER_FILES=$(addprefix _build/,$(shell find $(NATIVE_C_DIRS) -name '*.h'))


NATIVE_OBJECT_FILES=$(patsubst %.c,%.o,$(NATIVE_C_FILES))

BUILT_OBJECT_FILES=$(addprefix _build/,$(NATIVE_OBJECT_FILES))
NATIVE_LIB_OPTS=$(foreach lib, $(NATIVE_LIBRARIES),-cclib -l -cclib $(lib))

LINKER_FLAGS=$(NATIVE_LIB_OPTS)

INCLUDE_OPTS=$(foreach dir,$(MODULES),-I $(dir))

BUILT_C_DIRS=$(addprefix _build/,$(NATIVE_C_DIRS))
BUILT_C_FILES=$(addprefix _build/,$(NATIVE_C_FILES))
CC_FLAGS=-DNO_SQLITE3
CC_OPTS=$(foreach flag, $(CC_FLAGS), -ccopt $(flag))

ALL_INCLUDE_PATHS=$(sort $(realpath $(BUILT_C_DIRS)))
EXTRA_INCLUDE_OPTS=$(foreach dir, $(ALL_INCLUDE_PATHS),-ccopt -I -ccopt $(dir))

%.h: $(subst _build/,,$@)
	mkdir -p $(dir $@)
	cp $(subst _build/,,$@) $@

.PHONY: all
all: libhp.a 
	mkdir -p _build/default
	cp static_libs/libhp.a _build/default/
	dune build @install -j auto --profile dev

.PHONY: install
install:
	dune install

.PHONY: generate_install
generate_install:
	find _build -type f  '('\
		-name '*.a' -o\
		-name '*.annot' -o\
		-name '*.cma' -o\
		-name '*.cmi' -o\
		-name '*.cmo' -o\
		-name '*.cmt' -o\
		-name '*.cmti' -o\
		-name '*.cmx' -o\
		-name '*.cmxa' -o\
		-name '*.ml' -o\
		-name '*.mli'\
		')'\
		> install.txt

.PHONY: remove
remove:
	dune uninstall

.PHONY: clean
clean:
	dune clean

$(BUILT_C_FILES): _build/%.c: %.c
	mkdir -p $(dir $@)
	cp $< $@

$(BUILT_OBJECT_FILES): %.o: %.c $(ALL_HEADER_FILES)
	cd $(dir $@) && ocamlopt $(EXTRA_INCLUDE_OPTS) $(CC_OPTS) -c $(notdir $<)

libhp.a: $(BUILT_OBJECT_FILES)
	ar -cvq libhp.a $(BUILT_OBJECT_FILES)
	mv libhp.a static_libs
