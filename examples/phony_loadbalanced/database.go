// Generated from ActorSimulation DSL
// Actor: database

package main

import (
	"fmt"
	"time"
	"github.com/Arceliar/phony"
)

// DatabaseCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type DatabaseCallbacks interface {

}

// DefaultDatabaseCallbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultDatabaseCallbacks struct{}




type Database struct {
	phony.Inbox
	targets []*Database
	callbacks DatabaseCallbacks
	sendCount int
}

func (a *Database) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *Database) Start() {
	a.callbacks = &DefaultDatabaseCallbacks{}
}


