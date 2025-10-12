# Generated from ActorSimulation DSL
# Makefile for loadbalanced_actors

.PHONY: build test clean

build:
	corral fetch
	ponyc .

test:
	corral fetch
	ponyc test
	./test

clean:
	rm -rf loadbalanced_actors test
	rm -rf _corral .corral

run: build
	./loadbalanced_actors
