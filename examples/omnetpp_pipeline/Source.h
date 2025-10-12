// Generated from ActorSimulation DSL
// Actor: source

#ifndef SOURCE_H
#define SOURCE_H

#include <omnetpp.h>

using namespace omnetpp;

class Source : public cSimpleModule {
  private:
    cMessage *selfMsg;
    int sendCount;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
