LD_LIBRARY_PATH="../"
test:	
	CGO_LDFLAGS="-l pasta -L../"

	@printf "\nTest C:\n"
	gcc -Wall test.c -lpasta -I../ -o test
	chmod +x test
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) \
	./test


	@printf "\nTest Java:\n"
	javac -cp .:../libpasta.jar test.java
	java -cp .:../libpasta.jar test

	# @printf "\nTest Javascript (node.js)\n"
	# cd ../javacsript && node-gyp build

	@# printf "\nTest Go:\n"
	@# go test

	@printf "\nTest PHP:\n"
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) \
	$(PHP_BIN) test.php

	@printf "\nTest Python:\n"
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) \
	python2 test.py

	@printf "\nTest Ruby\n"
	LD_LIBRARY_PATH=$(LD_LIBRARY_PATH) \
	ruby test.rb

.PHONY: test