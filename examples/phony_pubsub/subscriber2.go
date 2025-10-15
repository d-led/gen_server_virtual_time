// Generated from ActorSimulation DSL
// Actor: subscriber2
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
)

// Subscriber2Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Subscriber2Callbacks interface {

}


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


