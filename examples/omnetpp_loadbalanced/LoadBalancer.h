// Generated from ActorSimulation DSL
// Actor: load_balancer

#ifndef __LOADBALANCER_H
#define __LOADBALANCER_H

#include <omnetpp.h>

using namespace omnetpp;

class LoadBalancer : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
