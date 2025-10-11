// Generated from ActorSimulation DSL
// Actor: database

#ifndef __DATABASE_H
#define __DATABASE_H

#include <omnetpp.h>

using namespace omnetpp;

class Database : public cSimpleModule {
private:
    int sendCount;
    cMessage *selfMsg;

protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
