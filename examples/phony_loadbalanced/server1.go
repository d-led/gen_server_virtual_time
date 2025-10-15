// Generated from ActorSimulation DSL
// Actor: server1
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
)

// Server1Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Server1Callbacks interface {

}


type Server1 struct {
	phony.Inbox
	targets []*Server1
	callbacks Server1Callbacks
	sendCount int
}

func (a *Server1) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Server1) Start() {
	a.callbacks = &DefaultServer1Callbacks{}
}


