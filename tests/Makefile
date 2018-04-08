LD_LIBRARY_PATH="../"
NATIVE_LIBS=-lcrypto -lc -lm -lc -lutil -lutil -ldl -lrt -lpthread -lgcc_s -lc -lm -lrt -lpthread -lutil
CGO_CFLAGS="-I../../libpasta/libpasta-capi/include/"

all: c csharp java go php python ruby

c:
	@printf "\nTest C:\n"
	@echo -e "\e[1;33mC tests should be performed using the libpasta repo in the libpasta-capi/ folder.\e[0m"

csharp:
	@printf "\nTest C#\n"
	@echo -e "\e[1;33mC# tests not yet written.\e[0m"

java:
	@printf "\nTest Java:\n"
	@echo -e "\e[1;33mJava tests should be performed using the libpasta-java repo.\e[0m"

javascript:
	@printf "\nTest Javascript (node.js)\n"
	cd ../javascript && node-gyp build

go:
	@printf "\nTest Go:\n"
	@echo -e "\e[1;33mGo tests not yet configured correctly.\e[0m"
	# CGO_CFLAGS=$(CGO_CFLAGS) go test

php5 php56 php:
	@printf "\nTest PHP:\n"
	@$(PHP_BIN) test.php || \
	echo -e "\e[1;33mPHP requires either installing libpasta (try: make install_php), or enabling dynamically loaded extensions.\e[0m"


python:
	@printf "\nTest Python:\n"
	@cp "../python/_pasta.so" "../python/_libpasta.so"
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH)python/ \
	python2 test.py

ruby:
	@printf "\nTest Ruby\n"
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) \
	ruby test.rb

.PHONY: all c java javascript go php python ruby