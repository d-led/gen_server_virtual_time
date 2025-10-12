// Generated from ActorSimulation DSL
// Actor: source

#include "Source.h"

Define_Module(Source);

void Source::initialize() {
    sendCount = 0;
    selfMsg = nullptr;
    selfMsg = new cMessage("selfMsg");
    scheduleAt(simTime() + 0.02, selfMsg);
}

void Source::handleMessage(cMessage *msg) {
    if (msg->isSelfMessage()) {
        // Send messages
        EV << getName() << ": Processing message\n";
        for (int i = 0; i < 1; i++) {
            cMessage *outMsg = new cMessage("msg");
            send(outMsg, "out", i);
            sendCount++;
        }
        EV << getName() << ": Sent " << 1 << " messages\n";

        // Reschedule
        scheduleAt(simTime() + 0.02, msg);

    } else {
        // Handle received message
        EV << "Received message: " << msg->getName() << "\n";
        delete msg;
    }
}

void Source::finish() {
    EV << "Source sent " << sendCount << " messages\n";
    if (selfMsg != nullptr) {
        cancelAndDelete(selfMsg);
        selfMsg = nullptr;
    }
}
