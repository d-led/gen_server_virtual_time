// Generated from ActorSimulation DSL
// Actor: consumer

#include "Consumer.h"

Define_Module(Consumer);

void Consumer::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined
}

void Consumer::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // No send pattern

    } else {
        // Handle received message
        // EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Consumer::finish() {
    // EV << "Consumer sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
