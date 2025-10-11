// Generated from ActorSimulation DSL
// Actor: source

#ifndef __SOURCE_H
#define __SOURCE_H

#include <omnetpp.h>

using namespace omnetpp;

class Source : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
