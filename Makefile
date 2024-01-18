
PLV8_VERSION = 3.2.1

CP := cp
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
SHLIB_LINK += -std=c++17
PG_CPPFLAGS := -fPIC -Wall -Wno-register -xc++
PG_LDFLAGS := -std=c++17

SRCS = plv8.cc plv8_type.cc plv8_func.cc plv8_param.cc plv8_allocator.cc plv8_guc.cc
OBJS = $(SRCS:.cc=.o)
MODULE_big = plv8-$(PLV8_VERSION)
EXTENSION = plv8
PLV8_DATA = plv8.control plv8--$(PLV8_VERSION).sql

CCFLAGS += -Wall -Wextra -v

ifeq ($(OS),Windows_NT)
	# noop for now
else
	SHLIB_LINK += -Ldeps/v8-cmake/build
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Darwin)
		CCFLAGS += -stdlib=libc++
		SHLIB_LINK += -stdlib=libc++ -std=c++17 -lc++
		NUMPROC := $(shell sysctl hw.ncpu | awk '{print $$2}')
	endif
	ifeq ($(UNAME_S),Linux)
		SHLIB_LINK += -lrt -std=c++17
		NUMPROC := $(shell grep -c ^processor /proc/cpuinfo)
	endif
endif

ifeq ($(NUMPROC),0)
	NUMPROC = 1
endif

SHLIB_LINK += -Ldeps/v8-cmake/build

all: v8 $(OBJS)

# For some reason, this solves parallel make dependency.
plv8_config.h plv8.so: v8

deps/v8-cmake/build/libv8_libbase.a:
	@git submodule update --init --recursive
	@cd deps/v8-cmake && mkdir -p build && cd build && cmake -Denable-fPIC=ON -DCMAKE_BUILD_TYPE=Release ../ && make -j $(NUMPROC)
