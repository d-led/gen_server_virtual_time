# Generated from ActorSimulation DSL
# Makefile for pubsub_actors

.PHONY: build test clean run

build:
	go build -o pubsub_actors .

test:
	go test -v ./...

clean:
	rm -f pubsub_actors

run: build
	./pubsub_actors

deps:
	go mod download
	go mod tidy
