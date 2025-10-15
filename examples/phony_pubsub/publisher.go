// Generated from ActorSimulation DSL
// Actor: publisher
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
	"time"
)

// PublisherCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type PublisherCallbacks interface {
	OnEvent()
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

