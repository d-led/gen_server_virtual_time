// Generated from ActorSimulation DSL
// Go tests for actors

package main

import (
	"testing"
	"time"

	"github.com/Arceliar/phony"
)

func TestActorSystem(t *testing.T) {
	// Basic system test
	if testing.Short() {
		t.Skip("Skipping in short mode")
	}
}

// waitFor waits until what asks for holds, or until the time it was given is up.
func waitFor(t *testing.T, within time.Duration, what func() bool) {
	t.Helper()

	deadline := time.Now().Add(within)
	for time.Now().Before(deadline) {
		if what() {
			return
		}

		time.Sleep(time.Millisecond)
	}
}

func TestLoadBalancer(t *testing.T) {
	actor := &LoadBalancer{}
	actor.Start()

	const intervals = 3
	time.Sleep(intervals*10*time.Millisecond + 10/2*time.Millisecond)

	phony.Block(actor.Actor(), func() {})
	if actor.sendCount < intervals || actor.sendCount > intervals+1 {
		t.Fatalf("the actor sent %d messages in %d intervals, want %d or %d", actor.sendCount, intervals, intervals, intervals+1)
	}
}


func TestServer1(t *testing.T) {
	actor := &Server1{}
	actor.Start()

	// The actor's inbox takes work: this returns when it has run it, which it
	// never does if the actor is broken.
	phony.Block(actor.Actor(), func() {})
}


func TestServer2(t *testing.T) {
	actor := &Server2{}
	actor.Start()

	// The actor's inbox takes work: this returns when it has run it, which it
	// never does if the actor is broken.
	phony.Block(actor.Actor(), func() {})
}


func TestServer3(t *testing.T) {
	actor := &Server3{}
	actor.Start()

	// The actor's inbox takes work: this returns when it has run it, which it
	// never does if the actor is broken.
	phony.Block(actor.Actor(), func() {})
}


func TestDatabase(t *testing.T) {
	actor := &Database{}
	actor.Start()

	// The actor's inbox takes work: this returns when it has run it, which it
	// never does if the actor is broken.
	phony.Block(actor.Actor(), func() {})
}

