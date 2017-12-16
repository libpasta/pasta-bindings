targets  = java python php5 ruby

STATIC_LIBPASTA ?= ./libpasta/build/libpasta.a
SHARED_LIBPASTA ?= -lpasta
NATIVE_LIBS     = -lpthread -l:libcrypto.so.1.0.0 -ldl -lm
SWIG            = swig
OUTPUT_NAME     = pasta.so
CC              = gcc
CC_OPTS         = -z noexecstack

BUILD_TYPE      = release

PHP_VERSION    ?= 56
export PHP_CONFIG = php-config${PHP_VERSION}
export PHP_BIN  = php${PHP_VERSION}
PYTHON_VERSION ?= python2.7

go_SWIG_ARGS    = -cgo -intgosize 64 -use-shlib -soname libpasta.so
javascript_SWIG_ARGS = -c++ -v8
java_SWIG_ARGS  = -package io.github.libpasta
java_DIR        = $(shell java -XshowSettings 2>&1 | grep java.home | grep '/usr/.*/' -o)
java_INCLUDES   = -I$(java_DIR)include/ -I$(java_DIR)include/linux/
javascript_INCLUDES = -I/usr/include/node/
php_INCLUDE_DIR = $(shell $(PHP_CONFIG) --include-dir)
php5_INCLUDES   = $(shell $(PHP_CONFIG) --includes)
python_INCLUDES = $(shell python2-config --includes)
ruby_INCLUDES   = -I$(shell ruby -rrbconfig -e 'puts RbConfig::CONFIG[%q{rubyhdrdir}]') -I$(shell ruby -rrbconfig -e 'puts RbConfig::CONFIG[%q{rubyarchhdrdir}]')

all: libpasta-sync $(targets)

java: OUTPUT_DIR = META-INF/lib/linux_64
java: OUTPUT_NAME = libpasta_jni.so
javascript: CC    = g++
python: OUTPUT_NAME = _pasta.so

$(targets): pasta.i
	mkdir -p $@/$(OUTPUT_DIR)
	$(SWIG) -$@ $($@_SWIG_ARGS) -outdir $@ -o $@/pasta_wrap.c  pasta.i
	$(CC) $(CC_OPTS) $@/pasta_wrap.c -fPIC -c -g $($@_INCLUDES) -o $@/pasta_wrap.o
ifdef USE_STATIC
	$(CC) $(CC_OPTS) -static-libgcc -shared $@/pasta_wrap.o $(STATIC_LIBPASTA)  -L/usr/lib/ $(NATIVE_LIBS) -o $@/$(OUTPUT_DIR)/$(OUTPUT_NAME)
else
	$(CC) $(CC_OPTS) -shared $@/pasta_wrap.o $(SHARED_LIBPASTA) -o $@/$(OUTPUT_DIR)/$(OUTPUT_NAME)
endif

clean:
	rm -rf $(targets)
	make -C libpasta clean

force: clean
	make -C libpasta force
	make all

test: all
	make -C tests/ c $(targets)

libpasta-sync:
	git submodule update --init --recursive
	cd libpasta && git fetch
ifneq ($(shell git -C libpasta/ rev-parse --abbrev-ref HEAD),master)
	cd libpasta && git fetch && git checkout origin/master
endif

libpasta/build/libpasta.%:
	make -C libpasta $(@F)

libpasta: libpasta-sync libpasta/build/libpasta.a libpasta/build/libpasta.so
ifndef USE_STATIC
	make -C libpasta install
endif

PHP_INI=$(shell $(PHP_BIN) -i | grep -o '/etc/.*/php.ini')
PHPENMOD := $(shell command -v php${PHP_VERSION}enmod 2> /dev/null)

install_php: libpasta php5
	sudo cp bindings/php5/pasta.so $(shell $(PHP_CONFIG) --extension-dir)/pasta.so 
ifdef PHPENMOD
	sudo $(PHPENMOD) pasta
else
	(grep -qi pasta.so $(PHP_INI) && sudo sed -i 's/;extension=pasta.so/extension=pasta/' $(PHP_INI)) || \
	(echo "extension=pasta.so" | sudo tee --append $(PHP_INI) > /dev/null)
endif


.PHONY: all clean force test libpasta-sync
