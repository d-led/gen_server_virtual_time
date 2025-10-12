// Generated from ActorSimulation DSL
// Actor: subscriber1

#include "Subscriber1.h"

Define_Module(Subscriber1);

void Subscriber1::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined
}

void Subscriber1::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // No send pattern

    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Subscriber1::finish() {
    EV << "Subscriber1 sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
