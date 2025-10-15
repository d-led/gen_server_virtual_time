// Generated from ActorSimulation DSL
// Actor: database
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
)

// DatabaseCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type DatabaseCallbacks interface {

}


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


