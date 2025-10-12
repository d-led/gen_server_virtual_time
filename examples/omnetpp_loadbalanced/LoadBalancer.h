// Generated from ActorSimulation DSL
// Actor: load_balancer

#ifndef LOADBALANCER_H
#define LOADBALANCER_H

#include <omnetpp.h>

using namespace omnetpp;

class LoadBalancer : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
