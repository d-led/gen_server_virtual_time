// Generated from ActorSimulation DSL
// Actor: subscriber1
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
)

// Subscriber1Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Subscriber1Callbacks interface {

}


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


