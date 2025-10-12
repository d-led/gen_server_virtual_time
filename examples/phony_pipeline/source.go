// Generated from ActorSimulation DSL
// Actor: source

package main

import (
	"github.com/Arceliar/phony"
	"fmt"
	"time"
)

// SourceCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type SourceCallbacks interface {
	OnData()
}

// DefaultSourceCallbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultSourceCallbacks struct{}

func (c *DefaultSourceCallbacks) OnData() {
	// TODO: Implement custom behavior for data
	fmt.Println("Source: data")
}



type Source struct {
	phony.Inbox
	targets []*Source
	callbacks SourceCallbacks
	sendCount int
}

func (a *Source) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Source) Start() {
	a.callbacks = &DefaultSourceCallbacks{}
	go func() {
		ticker := time.NewTicker(20 * time.Millisecond)
		defer ticker.Stop()
		for range ticker.C {
			a.Act(nil, func() { a.Data() })
		}
	}()
}

func (a *Source) Data() {
	a.callbacks.OnData()
	// Send to targets
	for _, target := range a.targets {
		target.Act(a, func() { target.Data() })
	}
	a.sendCount++
}

