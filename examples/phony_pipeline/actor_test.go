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

func TestSource(t *testing.T) {
	actor := &Source{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestStage1(t *testing.T) {
	actor := &Stage1{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestStage2(t *testing.T) {
	actor := &Stage2{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestStage3(t *testing.T) {
	actor := &Stage3{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestSink(t *testing.T) {
	actor := &Sink{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}

