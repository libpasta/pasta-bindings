targets  = java python php5 ruby

LIBS            = ./libpasta-ffi/target/${BUILD_TYPE}/libpasta.a
NATIVE_LIBS     = -lcrypto -lc -lm -lc -lutil -lutil -ldl -lrt -lpthread -lgcc_s -lc -lm -lrt -lpthread -lutil
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
java_SWIG_ARGS  = -package io.github.libpasta
java_DIR        = $(shell java -XshowSettings 2>&1 | grep java.home | grep '/usr/.*/' -o)
java_INCLUDES   = -I$(java_DIR)include/ -I$(java_DIR)include/linux/
javascript_INCLUDES = -I/usr/include/node/
php_INCLUDE_DIR = $(shell $(PHP_CONFIG) --include-dir)
php5_INCLUDES   = $(shell $(PHP_CONFIG) --includes)
python_INCLUDES = $(shell python2-config --includes)
ruby_INCLUDES   = -I$(shell ruby -rrbconfig -e 'puts RbConfig::CONFIG[%q{rubyhdrdir}]') -I$(shell ruby -rrbconfig -e 'puts RbConfig::CONFIG[%q{rubyarchhdrdir}]')

all: $(targets)

java: OUTPUT_DIR = META-INF/lib/linux_64
java: OUTPUT_NAME = libpasta_jni.so
javascript: CC    = g++
python: OUTPUT_NAME = _pasta.so

$(targets): pasta.i libpasta
	mkdir -p $@/$(OUTPUT_DIR)
	$(SWIG) -$@ $($@_SWIG_ARGS) -outdir $@ -o $@/pasta_wrap.c  pasta.i
	$(CC) $@/pasta_wrap.c -fPIC -c -g $($@_INCLUDES) -o $@/pasta_wrap.o
	$(CC) -shared $@/pasta_wrap.o $(LIBS)  -L/usr/lib/ $(NATIVE_LIBS) -o $@/$(OUTPUT_DIR)/$(OUTPUT_NAME)

clean:
	rm -rf $(targets)
	rm -f tests/test.class
	rm libpasta.jar

force: clean all

test: all
	make -C tests/ c $(targets)

libpasta: libpasta-ffi/Cargo.toml libpasta-ffi/src/lib.rs
	cd libpasta-ffi/ && cargo build --${BUILD_TYPE}

libpasta-ffi/Cargo.toml:
	git submodule update --remote && git submodule sync


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


.PHONY: all clean force test libpasta-ffi/Cargo.toml