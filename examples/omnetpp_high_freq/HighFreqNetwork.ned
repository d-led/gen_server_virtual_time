// Generated from ActorSimulation DSL

simple Consumer {
            gates:
                input in;}


simple Producer {
            gates:
                output out[1];}


network HighFreqNetwork {
    submodules:
        consumer: Consumer;
        producer: Producer;
    connections:
        producer.out[0] --> consumer.in;
}

