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

func TestProcessor(t *testing.T) {
	actor := &Processor{}
	actor.Start()

	// The actor's inbox takes work: this returns when it has run it, which it
	// never does if the actor is broken.
	phony.Block(actor.Actor(), func() {})
}


func TestBurstGenerator(t *testing.T) {
	actor := &BurstGenerator{}
	actor.Start()

	// One burst is due an interval from now, and it is the count the DSL asked
	// for: wait for it, then hold the actor to it.
	waitFor(t, 2*1000*time.Millisecond, func() bool {
		phony.Block(actor.Actor(), func() {})
		return actor.sendCount >= 10
	})

	phony.Block(actor.Actor(), func() {})
	if actor.sendCount != 10 {
		t.Fatalf("the burst sent %d messages, want 10", actor.sendCount)
	}
}

