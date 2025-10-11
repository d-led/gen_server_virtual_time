// Generated from ActorSimulation DSL
// Actor: stage3

#include "Stage3.h"

Define_Module(Stage3);

void Stage3::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined}

void Stage3::handleMessage(cMessage *msg) {
    // Receive only
    EV << "Received message: " << msg->getName() << "\n";
    delete msg;
}

void Stage3::finish() {
    EV << "Stage3 sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
