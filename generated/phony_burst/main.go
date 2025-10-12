// Generated from ActorSimulation DSL
// Main entry point for burst_actors

package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println("Starting actor system...")
	
	// Spawn all actors
	processor := &Processor{}
	processor.Start()
	burst_generator := &BurstGenerator{}
	burst_generator.Start()
	
	fmt.Println("Actor system started. Press Ctrl+C to exit.")
	
	// Keep running
	select {}
}
