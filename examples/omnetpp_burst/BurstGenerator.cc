// Generated from ActorSimulation DSL
// Actor: burst_generator

#include "BurstGenerator.h"

Define_Module(BurstGenerator);

void BurstGenerator::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    selfMsg = new cMessage("selfMsg");
    scheduleAt(simTime() + 1.0, selfMsg);
}

void BurstGenerator::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // Send messages
        for (int i = 0; i < 1; i++) {
            cMessage *outMsg = new cMessage("msg");
            send(outMsg, "out", i);
            sendCount++;
        }


        // Reschedule
        scheduleAt(simTime() + 1.0, msg);

    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void BurstGenerator::finish() {
    EV << "BurstGenerator sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
