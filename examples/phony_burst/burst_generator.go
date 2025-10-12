// Generated from ActorSimulation DSL
// Actor: burst_generator

package main

import (
	"fmt"
	"time"
	"github.com/Arceliar/phony"
)

// BurstGeneratorCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type BurstGeneratorCallbacks interface {
	OnBatch()
}

// DefaultBurstGeneratorCallbacks provides default implementations
// CUSTOMIZE THIS to add your own behavior!
type DefaultBurstGeneratorCallbacks struct{}

func (c *DefaultBurstGeneratorCallbacks) OnBatch() {
	// TODO: Implement custom behavior for batch
	fmt.Println("BurstGenerator: batch")
}



type BurstGenerator struct {
	phony.Inbox
	targets []*BurstGenerator
	callbacks BurstGeneratorCallbacks
	sendCount int
}

func (a *BurstGenerator) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *BurstGenerator) Start() {
	a.callbacks = &DefaultBurstGeneratorCallbacks{}
	go func() {
		ticker := time.NewTicker(1000 * time.Millisecond)
		defer ticker.Stop()
		for range ticker.C {
			for i := 0; i < 10; i++ {
				a.Act(nil, func() { a.Batch() })
			}
		}
	}()
}

func (a *BurstGenerator) Batch() {
	a.callbacks.OnBatch()
	// Send to targets
	for _, target := range a.targets {
		target.Act(a, func() { target.Batch() })
	}
	a.sendCount++
}

