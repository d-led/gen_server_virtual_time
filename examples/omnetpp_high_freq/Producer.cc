// Generated from ActorSimulation DSL
// Actor: producer

#include "Producer.h"

Define_Module(Producer);

void Producer::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    selfMsg = new cMessage("selfMsg");
    scheduleAt(simTime() + 0.001, selfMsg);
}

void Producer::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // Send messages
        // EV << getName() << ": Processing message\n";
        for (int i = 0; i < 1; i++) {
            cMessage *outMsg = new cMessage("msg");
            send(outMsg, "out", i);
            sendCount++;
        }
        // EV << getName() << ": Sent " << 1 << " messages\n";

        // Reschedule
        scheduleAt(simTime() + 0.001, msg);

    } else {
        // Handle received message
        // EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Producer::finish() {
    // EV << "Producer sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
