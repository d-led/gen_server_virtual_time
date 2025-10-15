// Generated from ActorSimulation DSL
// Default callback implementation for: burst_generator
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!

package main

import (
	"fmt"
)


// DefaultBurstGeneratorCallbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultBurstGeneratorCallbacks struct{}

func (c *DefaultBurstGeneratorCallbacks) OnBatch() {
	// TODO: Implement custom behavior for batch
	fmt.Printf("BurstGenerator: Sending batch message\n")
}

