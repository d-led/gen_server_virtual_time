// Generated from ActorSimulation DSL
// Actor: stage1
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
)

// Stage1Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Stage1Callbacks interface {

}


type Stage1 struct {
	phony.Inbox
	targets []*Stage1
	callbacks Stage1Callbacks
	sendCount int
}

func (a *Stage1) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Stage1) Start() {
	a.callbacks = &DefaultStage1Callbacks{}
}


