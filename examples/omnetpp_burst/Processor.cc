// Generated from ActorSimulation DSL
// Actor: processor

#include "Processor.h"

Define_Module(Processor);

void Processor::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined
}

void Processor::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // No send pattern

    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Processor::finish() {
    EV << "Processor sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
