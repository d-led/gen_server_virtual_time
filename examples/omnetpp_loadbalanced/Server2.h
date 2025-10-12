// Generated from ActorSimulation DSL
// Actor: server2

#ifndef SERVER2_H
#define SERVER2_H

#include <omnetpp.h>

using namespace omnetpp;

class Server2 : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
