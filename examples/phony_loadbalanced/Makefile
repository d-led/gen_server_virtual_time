# Generated from ActorSimulation DSL
# Makefile for loadbalanced_actors

.PHONY: build test clean run

build:
	go build -o loadbalanced_actors .

test:
	go test -v ./...

clean:
	rm -f loadbalanced_actors

run: build
	./loadbalanced_actors

deps:
	go mod download
	go mod tidy
