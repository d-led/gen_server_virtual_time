// Generated from ActorSimulation DSL
// Actor: subscriber1

package main

import (
	"github.com/Arceliar/phony"
)

// Subscriber1Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Subscriber1Callbacks interface {

}

// DefaultSubscriber1Callbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultSubscriber1Callbacks struct{}




type Subscriber1 struct {
	phony.Inbox
	targets []*Subscriber1
	callbacks Subscriber1Callbacks
	sendCount int
}

func (a *Subscriber1) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Subscriber1) Start() {
	a.callbacks = &DefaultSubscriber1Callbacks{}
}


