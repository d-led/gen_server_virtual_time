// Generated from ActorSimulation DSL
// Actor: source
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
	"time"
)

// SourceCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type SourceCallbacks interface {
	OnData()
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

