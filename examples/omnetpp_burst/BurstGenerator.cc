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
        for (int i = 0; i < 10; i++) {
            for (int g = 0; g < 1; g++) {
                cMessage *outMsg = new cMessage(:batch);
                send(outMsg, "out", g);
                sendCount++;
            }
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
