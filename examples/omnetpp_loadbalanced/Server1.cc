// Generated from ActorSimulation DSL
// Actor: server1

#include "Server1.h"

Define_Module(Server1);

void Server1::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined}

void Server1::handleMessage(cMessage *msg) {
    // Receive only
    EV << "Received message: " << msg->getName() << "\n";
    delete msg;
}

void Server1::finish() {
    EV << "Server1 sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
