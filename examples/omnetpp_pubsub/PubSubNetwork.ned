// Generated from ActorSimulation DSL

simple Publisher {
            gates:
                output out[3];}


simple Subscriber1 {
            gates:
                input in;}


simple Subscriber2 {
            gates:
                input in;}


simple Subscriber3 {
            gates:
                input in;}


network PubSubNetwork {
    submodules:
        publisher: Publisher;
        subscriber1: Subscriber1;
        subscriber2: Subscriber2;
        subscriber3: Subscriber3;
    connections:
        publisher.out[0] --> subscriber1.in;
        publisher.out[1] --> subscriber2.in;
        publisher.out[2] --> subscriber3.in;
}

