// Generated from ActorSimulation DSL
// Actor: database

#include "Database.h"

Define_Module(Database);

void Database::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined
}

void Database::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // No send pattern

    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Database::finish() {
    EV << "Database sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
