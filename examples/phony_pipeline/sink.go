// Generated from ActorSimulation DSL
// Actor: sink
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
)

// SinkCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type SinkCallbacks interface {

}


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


