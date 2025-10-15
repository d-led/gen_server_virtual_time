// Generated from ActorSimulation DSL
// Actor: processor
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
)

// ProcessorCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type ProcessorCallbacks interface {

}


type Processor struct {
	phony.Inbox
	targets []*Processor
	callbacks ProcessorCallbacks
	sendCount int
}

func (a *Processor) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Processor) Start() {
	a.callbacks = &DefaultProcessorCallbacks{}
}


