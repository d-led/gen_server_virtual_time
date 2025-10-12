// Generated from ActorSimulation DSL
// Actor: subscriber2

package main

import (
	"github.com/Arceliar/phony"
)

// Subscriber2Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Subscriber2Callbacks interface {

}

// DefaultSubscriber2Callbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultSubscriber2Callbacks struct{}




type Subscriber2 struct {
	phony.Inbox
	targets []*Subscriber2
	callbacks Subscriber2Callbacks
	sendCount int
}

func (a *Subscriber2) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Subscriber2) Start() {
	a.callbacks = &DefaultSubscriber2Callbacks{}
}


