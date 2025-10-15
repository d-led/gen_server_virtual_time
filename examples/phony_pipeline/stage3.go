// Generated from ActorSimulation DSL
// Actor: stage3
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
)

// Stage3Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Stage3Callbacks interface {

}


type Stage3 struct {
	phony.Inbox
	targets []*Stage3
	callbacks Stage3Callbacks
	sendCount int
}

func (a *Stage3) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Stage3) Start() {
	a.callbacks = &DefaultStage3Callbacks{}
}


