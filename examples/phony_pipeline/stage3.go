// Generated from ActorSimulation DSL
// Actor: stage3

package main

import (
	"fmt"
	"time"
	"github.com/Arceliar/phony"
)

// Stage3Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Stage3Callbacks interface {

}

// DefaultStage3Callbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultStage3Callbacks struct{}




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


