// Generated from ActorSimulation DSL
// Actor: server3

#ifndef SERVER3_H
#define SERVER3_H

#include <omnetpp.h>

using namespace omnetpp;

class Server3 : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
