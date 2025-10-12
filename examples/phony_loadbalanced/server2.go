// Generated from ActorSimulation DSL
// Actor: server2

package main

import (
	"github.com/Arceliar/phony"
)

// Server2Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Server2Callbacks interface {

}

// DefaultServer2Callbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultServer2Callbacks struct{}




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


