// Generated from ActorSimulation DSL
// Default callback implementation for: publisher
// CUSTOMIZE THIS FILE - This is where you add your custom behavior!

package main

import (
	"fmt"
)


// DefaultPublisherCallbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultPublisherCallbacks struct{}

func (c *DefaultPublisherCallbacks) OnEvent() {
	// TODO: Implement custom behavior for event
	fmt.Printf("Publisher: Sending event message\n")
}

