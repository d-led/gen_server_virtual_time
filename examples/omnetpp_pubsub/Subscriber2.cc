// Generated from ActorSimulation DSL
// Actor: subscriber2

#include "Subscriber2.h"

Define_Module(Subscriber2);

void Subscriber2::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined}

void Subscriber2::handleMessage(cMessage *msg) {
    // Receive only
    EV << "Received message: " << msg->getName() << "\n";
    delete msg;
}

void Subscriber2::finish() {
    EV << "Subscriber2 sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
