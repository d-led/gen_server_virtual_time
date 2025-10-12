// Generated from ActorSimulation DSL
// Actor: sink

package main

import (
	"fmt"
	"time"
	"github.com/Arceliar/phony"
)

// SinkCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type SinkCallbacks interface {

}

// DefaultSinkCallbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultSinkCallbacks struct{}




type Sink struct {
	phony.Inbox
	targets []*Sink
	callbacks SinkCallbacks
	sendCount int
}

func (a *Sink) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Sink) Start() {
	a.callbacks = &DefaultSinkCallbacks{}
}


