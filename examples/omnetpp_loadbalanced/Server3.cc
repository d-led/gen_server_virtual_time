// Generated from ActorSimulation DSL
// Actor: server3

#include "Server3.h"

Define_Module(Server3);

void Server3::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined}

void Server3::handleMessage(cMessage *msg) {
    // Receive only
    EV << "Received message: " << msg->getName() << "\n";
    delete msg;
}

void Server3::finish() {
    EV << "Server3 sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
