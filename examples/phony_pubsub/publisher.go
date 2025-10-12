// Generated from ActorSimulation DSL
// Actor: publisher

package main

import (
	"github.com/Arceliar/phony"
	"fmt"
	"time"
)

// PublisherCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type PublisherCallbacks interface {
	OnEvent()
}

// DefaultPublisherCallbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultPublisherCallbacks struct{}

func (c *DefaultPublisherCallbacks) OnEvent() {
	// TODO: Implement custom behavior for event
	fmt.Printf("Publisher: Received event message\n")
}



type Publisher struct {
	phony.Inbox
	targets []*Publisher
	callbacks PublisherCallbacks
	sendCount int
}

func (a *Publisher) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Publisher) Start() {
	a.callbacks = &DefaultPublisherCallbacks{}
	go func() {
		ticker := time.NewTicker(100 * time.Millisecond)
		defer ticker.Stop()
		for range ticker.C {
			a.Act(nil, func() { a.Event() })
		}
	}()
}

func (a *Publisher) Event() {
	a.callbacks.OnEvent()
	// Send to targets
	for _, target := range a.targets {
		target.Act(a, func() { target.Event() })
	}
	a.sendCount++
}

