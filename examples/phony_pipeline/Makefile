# Generated from ActorSimulation DSL
# Makefile for pipeline_actors

.PHONY: build test clean run

build:
	go build -o pipeline_actors .

test:
	go test -v ./...

clean:
	rm -f pipeline_actors

run: build
	./pipeline_actors

deps:
	go mod download
	go mod tidy
