# Generated from ActorSimulation DSL
# Makefile for pipeline_actors

.PHONY: build test clean

build:
	corral fetch
	ponyc .

test:
	corral fetch
	ponyc test
	./test

clean:
	rm -rf pipeline_actors test
	rm -rf _corral .corral

run: build
	./pipeline_actors
