// Generated from ActorSimulation DSL
// Actor: server2

#include "Server2.h"

Define_Module(Server2);

void Server2::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined
}

void Server2::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // No send pattern

    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Server2::finish() {
    EV << "Server2 sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
