// Generated from ActorSimulation DSL
// Actor: processor

package main

import (
	"fmt"
	"time"
	"github.com/Arceliar/phony"
)

// ProcessorCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type ProcessorCallbacks interface {

}

// DefaultProcessorCallbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultProcessorCallbacks struct{}




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


