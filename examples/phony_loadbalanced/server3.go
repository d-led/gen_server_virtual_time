// Generated from ActorSimulation DSL
// Actor: server3

package main

import (
	"fmt"
	"time"
	"github.com/Arceliar/phony"
)

// Server3Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Server3Callbacks interface {

}

// DefaultServer3Callbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultServer3Callbacks struct{}




type Server3 struct {
	phony.Inbox
	targets []*Server3
	callbacks Server3Callbacks
	sendCount int
}

func (a *Server3) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Server3) Start() {
	a.callbacks = &DefaultServer3Callbacks{}
}


