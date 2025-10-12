# Generated from ActorSimulation DSL
# Makefile for burst_actors

# Binary naming: {example}.pony.{os}
# Note: ponyc creates binary based on directory name, not project name
DIR_NAME := $(shell basename $(CURDIR))
UNAME_S := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ifeq ($(UNAME_S),darwin)
    BINARY := burst_actors.pony.darwin
else ifeq ($(UNAME_S),linux)
    BINARY := burst_actors.pony.linux
else
    BINARY := burst_actors.pony.exe
endif

.PHONY: build test clean run

build:
	corral fetch
	ponyc .
	mv $(DIR_NAME) $(BINARY)

test:
	corral fetch
	ponyc test
	./test

clean:
	rm -rf $(BINARY) burst_actors.pony.* $(DIR_NAME) test
	rm -rf _corral .corral

run: build
	./$(BINARY)
