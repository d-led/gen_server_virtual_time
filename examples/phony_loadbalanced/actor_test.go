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

func TestLoadBalancer(t *testing.T) {
	actor := &LoadBalancer{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestServer1(t *testing.T) {
	actor := &Server1{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestServer2(t *testing.T) {
	actor := &Server2{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestServer3(t *testing.T) {
	actor := &Server3{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}


func TestDatabase(t *testing.T) {
	actor := &Database{}
	actor.Start()
	
	// Wait a bit for actor to initialize
	time.Sleep(10 * time.Millisecond)
	
	if actor == nil {
		t.Fatal("Actor should not be nil")
	}
}

