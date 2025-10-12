// Generated from ActorSimulation DSL
// Actor: publisher

#include "Publisher.h"

Define_Module(Publisher);

void Publisher::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    selfMsg = new cMessage("selfMsg");
    scheduleAt(simTime() + 0.1, selfMsg);
}

void Publisher::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // Send messages
        EV << getName() << ": Processing message\n";
        for (int i = 0; i < 3; i++) {
            cMessage *outMsg = new cMessage("msg");
            send(outMsg, "out", i);
            sendCount++;
        }
        EV << getName() << ": Sent " << 3 << " messages\n";

        // Reschedule
        scheduleAt(simTime() + 0.1, msg);

    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Publisher::finish() {
    EV << "Publisher sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
