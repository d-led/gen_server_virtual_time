// Generated from ActorSimulation DSL
// Main entry point for pipeline_actors

package main

import (
	"fmt"
)

func main() {
	fmt.Println("Starting actor system...")
	
	// Spawn all actors
	source := &Source{}
	source.Start()
	stage1 := &Stage1{}
	stage1.Start()
	stage2 := &Stage2{}
	stage2.Start()
	stage3 := &Stage3{}
	stage3.Start()
	sink := &Sink{}
	sink.Start()
	
	fmt.Println("Actor system started. Press Ctrl+C to exit.")
	
	// Keep running
	select {}
}
