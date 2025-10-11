// Generated from ActorSimulation DSL
// Actor: subscriber3

#include "Subscriber3.h"

Define_Module(Subscriber3);

void Subscriber3::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined}

void Subscriber3::handleMessage(cMessage *msg) {
    // Receive only
    EV << "Received message: " << msg->getName() << "\n";
    delete msg;
}

void Subscriber3::finish() {
    EV << "Subscriber3 sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
