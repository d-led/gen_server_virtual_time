// Generated from ActorSimulation DSL
// Actor: server1

#ifndef SERVER1_H
#define SERVER1_H

#include <omnetpp.h>

using namespace omnetpp;

class Server1 : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
