// Generated from ActorSimulation DSL
// Actor: server2
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
)

// Server2Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Server2Callbacks interface {

}


type Server2 struct {
	phony.Inbox
	targets []*Server2
	callbacks Server2Callbacks
	sendCount int
}

func (a *Server2) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Server2) Start() {
	a.callbacks = &DefaultServer2Callbacks{}
}


