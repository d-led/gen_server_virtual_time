# Generated from ActorSimulation DSL
# Makefile for burst_actors

.PHONY: build test clean run

build:
	go build -o burst_actors .

test:
	go test -v ./...

clean:
	rm -f burst_actors

run: build
	./burst_actors

deps:
	go mod download
	go mod tidy
