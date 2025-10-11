// Generated from ActorSimulation DSL
// Actor: load_balancer

#include "LoadBalancer.h"

Define_Module(LoadBalancer);

void LoadBalancer::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    selfMsg = new cMessage("selfMsg");
    scheduleAt(simTime() + 0.01, selfMsg);
}

void LoadBalancer::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // Send messages
        for (int i = 0; i < 3; i++) {
            cMessage *outMsg = new cMessage("msg");
            send(outMsg, "out", i);
            sendCount++;
        }

        
        // Reschedule
        scheduleAt(simTime() + 0.01, msg);
    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void LoadBalancer::finish() {
    EV << "LoadBalancer sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
