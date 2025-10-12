// Generated from ActorSimulation DSL
// Actor: subscriber3

package main

import (
	"github.com/Arceliar/phony"
)

// Subscriber3Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Subscriber3Callbacks interface {

}

// DefaultSubscriber3Callbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultSubscriber3Callbacks struct{}




type Subscriber3 struct {
	phony.Inbox
	targets []*Subscriber3
	callbacks Subscriber3Callbacks
	sendCount int
}

func (a *Subscriber3) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Subscriber3) Start() {
	a.callbacks = &DefaultSubscriber3Callbacks{}
}


