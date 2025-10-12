// Generated from ActorSimulation DSL
// Actor: stage2

#include "Stage2.h"

Define_Module(Stage2);

void Stage2::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined
}

void Stage2::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // No send pattern

    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Stage2::finish() {
    EV << "Stage2 sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
