# Generated from ActorSimulation DSL
# Makefile for burst_actors

.PHONY: build test clean

build:
	corral fetch
	ponyc .

test:
	corral fetch
	ponyc test
	./test

clean:
	rm -rf burst_actors test
	rm -rf _corral .corral

run: build
	./burst_actors
