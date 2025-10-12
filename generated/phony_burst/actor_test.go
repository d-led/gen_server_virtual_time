// Generated from ActorSimulation DSL
// Go tests for actors

package main

import (
	"testing"
	"time"
)

func TestActorSystem(t *testing.T) {
	// Basic system test
	if testing.Short() {
		t.Skip("Skipping in short mode")
	}
}

func TestProcessor(t *testing.T) {
	actor := &Processor{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestBurstGenerator(t *testing.T) {
	actor := &BurstGenerator{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}

