// Generated from ActorSimulation DSL
// Actor: database

#ifndef DATABASE_H
#define DATABASE_H

#include <omnetpp.h>

using namespace omnetpp;

class Database : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
