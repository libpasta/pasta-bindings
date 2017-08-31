targets  = java python php5 ruby

LIBS            = -l pasta -L.
SWIG            = swig
OUTPUT_NAME     = pasta.so
CC              = gcc

BUILD_TYPE      = release

PHP_VERSION    ?= 56
export PHP_CONFIG = php-config${PHP_VERSION}
export PHP_BIN  = php${PHP_VERSION}
PYTHON_VERSION ?= python2.7

go_SWIG_ARGS    = -cgo -intgosize 64 -use-shlib -soname libpasta.so
javascript_SWIG_ARGS = -c++ -v8
java_DIR        = $(shell java -XshowSettings 2>&1 | grep java.home | grep '/usr/.*/' -o)
java_INCLUDES   = -I$(java_DIR)include/ -I$(java_DIR)include/linux/
javascript_INCLUDES = -I/usr/include/node/
php_INCLUDE_DIR = $(shell $(PHP_CONFIG) --include-dir)
php5_INCLUDES   = $(shell $(PHP_CONFIG) --includes)
python_INCLUDES = $(shell python2-config --includes)
ruby_INCLUDES   = -I$(shell ruby -rrbconfig -e 'puts RbConfig::CONFIG[%q{rubyhdrdir}]') -I$(shell ruby -rrbconfig -e 'puts RbConfig::CONFIG[%q{rubyarchhdrdir}]')

all: $(targets)

java: OUTPUT_NAME = libpasta_jni.so
javascript: CC    = g++
python: OUTPUT_NAME = _pasta.so
$(targets): pasta.i libpasta
	$(SWIG) -$@ $($@_SWIG_ARGS) -outdir $@ pasta.i
	$(CC) $@/pasta_wrap.c -fPIC -c -g $($@_INCLUDES) -o $@/pasta_wrap.o
	$(CC) -shared $@/pasta_wrap.o $(LIBS) -o $@/$(OUTPUT_NAME)

clean:
	rm -rf $(targets)
	rm -f tests/test.class
	cd libpasta-ffi && cargo clean

force: clean all

test: all
	make -C tests

libpasta: libpasta-ffi/Cargo.toml libpasta-ffi/src/lib.rs
	cd libpasta-ffi/ && cargo build --${BUILD_TYPE}
	cp libpasta-ffi/target/${BUILD_TYPE}/libpasta.so ../

libpasta-ffi/Cargo.toml:
	git submodule update && git submodule sync
	

.PHONY: all clean force test