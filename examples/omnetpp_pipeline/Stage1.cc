// Generated from ActorSimulation DSL
// Actor: stage1

#include "Stage1.h"

Define_Module(Stage1);

void Stage1::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    // No send pattern defined}

void Stage1::handleMessage(cMessage *msg) {
    // Receive only
    EV << "Received message: " << msg->getName() << "\n";
    delete msg;
}

void Stage1::finish() {
    EV << "Stage1 sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
