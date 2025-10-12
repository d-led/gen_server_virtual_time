// Generated from ActorSimulation DSL
// Actor: server3

#include "Server3.h"

Define_Module(Server3);

void Server3::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined
}

void Server3::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // No send pattern

    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Server3::finish() {
    EV << "Server3 sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
