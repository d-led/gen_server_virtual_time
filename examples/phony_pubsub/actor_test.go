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

func TestPublisher(t *testing.T) {
	actor := &Publisher{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestSubscriber1(t *testing.T) {
	actor := &Subscriber1{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestSubscriber2(t *testing.T) {
	actor := &Subscriber2{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestSubscriber3(t *testing.T) {
	actor := &Subscriber3{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}

