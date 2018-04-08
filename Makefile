targets  = csharp go java python php5 ruby

STATIC_LIBPASTA ?= $(shell pwd)/../libpasta/build/libpasta.a
SHARED_LIBPASTA ?= -lpasta
NATIVE_LIBS     = -lpthread -ldl -lm
SWIG            = swig
OUTPUT_NAME     = pasta.so
CXX              ?= g++
CXX_OPTS         = -z noexecstack -std=c++17 -Wno-register -Wall -fPIC -c -g
CXX_LINK_OPTS    = -z noexecstack -std=c++17 -Wno-deprecated-register

BUILD_TYPE      = release

PHP_VERSION    ?= 56
export PHP_CONFIG = php-config${PHP_VERSION}
export PHP_BIN  = php${PHP_VERSION}
PYTHON_VERSION ?= python2.7

go_SWIG_ARGS    = -cgo -intgosize 64 -use-shlib -soname libpasta.so -package libpasta
javascript_SWIG_ARGS = -c++ -node
java_SWIG_ARGS  = -package io.github.libpasta
java_DIR        = $(shell java -XshowSettings 2>&1 | grep java.home | grep '/usr/.*/' -o)
java_INCLUDES   = -I$(java_DIR)include/ -I$(java_DIR)include/linux/
javascript_INCLUDES = -I/usr/include/node/
php_INCLUDE_DIR = $(shell $(PHP_CONFIG) --include-dir)
php5_CXX_OPTS     = -Wno-unused-label
php5_INCLUDES   = $(shell $(PHP_CONFIG) --includes)
python_INCLUDES = $(shell python2-config --includes)
python_SWIG_ARGS= -module libpasta
ruby_INCLUDES   = -I$(shell ruby -rrbconfig -e 'puts RbConfig::CONFIG[%q{rubyhdrdir}]') -I$(shell ruby -rrbconfig -e 'puts RbConfig::CONFIG[%q{rubyarchhdrdir}]')

all: $(targets)

java: OUTPUT_DIR = META-INF/lib/linux_64
java: OUTPUT_NAME = libpasta_jni.so
python: OUTPUT_NAME = _pasta.so

$(targets): libpasta pasta.i
	mkdir -p $@/$(OUTPUT_DIR)
	$(SWIG) -$@ $($@_SWIG_ARGS) -Wextra -c++ -outdir $@ -o $@/pasta_wrap.cpp  pasta.i
	$(CXX) $(CXX_OPTS) $($@_CXX_OPTS) -o $@/pasta_wrap.o $@/pasta_wrap.cpp -I./../libpasta/libpasta-capi/include/  $($@_INCLUDES) 
ifdef USE_STATIC
	$(CXX) $(CXX_LINK_OPTS) $($@_CXX_LINK_OPTS) -static-libgcc -shared -o $@/$(OUTPUT_DIR)/$(OUTPUT_NAME) $@/pasta_wrap.o $(STATIC_LIBPASTA)  -L/usr/lib/ $(NATIVE_LIBS) 
else
	$(CXX) $(CXX_LINK_OPTS) -shared -o $@/$(OUTPUT_DIR)/$(OUTPUT_NAME) $@/pasta_wrap.o $(SHARED_LIBPASTA)  || true
endif

go: libpasta pasta.i
	mkdir -p $@/$(OUTPUT_DIR)
	$(SWIG) -$@ $($@_SWIG_ARGS) -Wextra -c++ -outdir $@ -o $@/pasta_wrap.cpp  pasta.i
ifdef USE_STATIC
	CGO_CPPFLAGS="$($@_CXX_OPTS) -I$(shell pwd)/../libpasta/libpasta-capi/include/  $($@_INCLUDES)" \
	CGO_LDFLAGS=" $($@_CXX_LINK_OPTS) -static-libgcc -shared -L/usr/lib/ $(NATIVE_LIBS) $(STATIC_LIBPASTA)" \
	go build -v ./go/pasta.go
else
	CGO_CPPFLAGS="$($@_CXX_OPTS) -I../libpasta/libpasta-capi/include/  $($@_INCLUDES)" \
	CGO_LDFLAGS="$($@_CXX_LINK_OPTS) -shared $(SHARED_LIBPASTA)" \
	go build -v ./go/pasta.go
endif

clean:
	rm -rf $(targets)
	make -C ../libpasta clean

force:
	touch pasta.i
	make $(targets)

test: all
	make -C tests/ c $(targets)

libpasta.a libpasta.so:
	make -C ../libpasta $@

libpasta: libpasta.a libpasta.so
ifndef USE_STATIC
	make -C ../libpasta install
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


.PHONY: all clean force test $(targets)
