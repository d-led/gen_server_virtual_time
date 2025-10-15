// Generated from ActorSimulation DSL
// Default callback implementation for: source
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!

package main

import (
	"fmt"
)

// DefaultSourceCallbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultSourceCallbacks struct{}

func (c *DefaultSourceCallbacks) OnData() {
	// TODO: Implement custom behavior for data
	fmt.Printf("Source: Sending data message\n")
}

