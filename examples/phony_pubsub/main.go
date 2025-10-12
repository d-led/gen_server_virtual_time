// Generated from ActorSimulation DSL
// Main entry point for pubsub_actors

package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println("Starting actor system...")
	
	// Spawn all actors
	publisher := &Publisher{}
	publisher.Start()
	subscriber1 := &Subscriber1{}
	subscriber1.Start()
	subscriber2 := &Subscriber2{}
	subscriber2.Start()
	subscriber3 := &Subscriber3{}
	subscriber3.Start()
	
	fmt.Println("Actor system started. Press Ctrl+C to exit.")
	
	// Keep running
	select {}
}
