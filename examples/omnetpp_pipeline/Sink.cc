// Generated from ActorSimulation DSL
// Actor: sink

#include "Sink.h"

Define_Module(Sink);

void Sink::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined
}

void Sink::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // No send pattern

    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Sink::finish() {
    EV << "Sink sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
