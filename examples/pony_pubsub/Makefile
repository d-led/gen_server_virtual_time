# Generated from ActorSimulation DSL
# Makefile for pubsub_actors

# Binary naming: {example}.pony.{os}
# Note: ponyc creates binary based on directory name, not project name
DIR_NAME := $(shell basename $(CURDIR))
UNAME_S := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ifeq ($(UNAME_S),darwin)
    BINARY := pubsub_actors.pony.darwin
else ifeq ($(UNAME_S),linux)
    BINARY := pubsub_actors.pony.linux
else
    BINARY := pubsub_actors.pony.exe
endif

.PHONY: build test clean run

build:
	corral fetch
	ponyc .
	mv $(DIR_NAME) $(BINARY)

test:
	@echo "Use 'bash scripts/test_pony_demo.sh' from the project root to run tests"

clean:
	rm -rf $(BINARY) pubsub_actors.pony.* $(DIR_NAME) test test1
	rm -rf _corral .corral

run: build
	./$(BINARY)
