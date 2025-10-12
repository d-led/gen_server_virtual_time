# Generated from ActorSimulation DSL
# Makefile for pubsub_actors

.PHONY: build test clean

build:
	corral fetch
	ponyc .

test:
	corral fetch
	ponyc test
	./test

clean:
	rm -rf pubsub_actors test
	rm -rf _corral .corral

run: build
	./pubsub_actors
