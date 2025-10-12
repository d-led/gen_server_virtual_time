// Generated from ActorSimulation DSL
// Actor: stage2

package main

import (
	"fmt"
	"time"
	"github.com/Arceliar/phony"
)

// Stage2Callbacks defines the callback interface
// Implement this interface to customize actor behavior
type Stage2Callbacks interface {

}

// DefaultStage2Callbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultStage2Callbacks struct{}




type Stage2 struct {
	phony.Inbox
	targets []*Stage2
	callbacks Stage2Callbacks
	sendCount int
}

func (a *Stage2) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Stage2) Start() {
	a.callbacks = &DefaultStage2Callbacks{}
}


