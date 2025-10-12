// Generated from ActorSimulation DSL
// Main entry point for loadbalanced_actors

package main

import (
	"fmt"
)

func main() {
	fmt.Println("Starting actor system...")
	
	// Spawn all actors
	load_balancer := &LoadBalancer{}
	load_balancer.Start()
	server1 := &Server1{}
	server1.Start()
	server2 := &Server2{}
	server2.Start()
	server3 := &Server3{}
	server3.Start()
	database := &Database{}
	database.Start()
	
	fmt.Println("Actor system started. Press Ctrl+C to exit.")
	
	// Keep running
	select {}
}
