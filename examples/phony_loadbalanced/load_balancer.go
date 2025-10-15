// Generated from ActorSimulation DSL
// Actor: load_balancer
// DO NOT EDIT - This file is auto-generated

package main

import (
	"github.com/Arceliar/phony"
	"time"
)

// LoadBalancerCallbacks defines the callback interface
// Implement this interface to customize actor behavior
type LoadBalancerCallbacks interface {
	OnRequest()
}


type LoadBalancer struct {
	phony.Inbox
	targets []*LoadBalancer
	callbacks LoadBalancerCallbacks
	sendCount int
}

func (a *LoadBalancer) Actor() *phony.Inbox {
	return &a.Inbox
}

func (a *LoadBalancer) Start() {
	a.callbacks = &DefaultLoadBalancerCallbacks{}
	go func() {
		ticker := time.NewTicker(10 * time.Millisecond)
		defer ticker.Stop()
		for range ticker.C {
			a.Act(nil, func() { a.Request() })
		}
	}()
}

func (a *LoadBalancer) Request() {
	a.callbacks.OnRequest()
	// Send to targets
	for _, target := range a.targets {
		target.Act(a, func() { target.Request() })
	}
	a.sendCount++
}

