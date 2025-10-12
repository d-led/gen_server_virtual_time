# Generated from ActorSimulation DSL
# Makefile for pipeline_actors

# Binary naming: {example}.phony.{os}
UNAME_S := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ifeq ($(UNAME_S),darwin)
    BINARY := pipeline_actors.phony.darwin
else ifeq ($(UNAME_S),linux)
    BINARY := pipeline_actors.phony.linux
else
    BINARY := pipeline_actors.phony.exe
endif

.PHONY: build test clean run

build:
	go build -o $(BINARY) .

test:
	go test -v ./...

clean:
	rm -f $(BINARY) pipeline_actors.phony.* pipeline_actors

run: build
	./$(BINARY)

deps:
	go mod download
	go mod tidy
