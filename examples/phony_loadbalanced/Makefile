# Generated from ActorSimulation DSL
# Makefile for loadbalanced_actors

# Binary naming: {example}.phony.{os}
UNAME_S := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ifeq ($(UNAME_S),darwin)
    BINARY := loadbalanced_actors.phony.darwin
else ifeq ($(UNAME_S),linux)
    BINARY := loadbalanced_actors.phony.linux
else
    BINARY := loadbalanced_actors.phony.exe
endif

.PHONY: build test clean run

build:
	go build -o $(BINARY) .

test:
	@echo "Use 'bash scripts/test_phony_demo.sh' from the project root to run tests"

clean:
	rm -f $(BINARY) loadbalanced_actors.phony.* loadbalanced_actors

run: build
	./$(BINARY)

deps:
	go mod download
	go mod tidy
