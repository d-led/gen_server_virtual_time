// Generated from ActorSimulation DSL

simple BurstGenerator {
    gates:
        input in;
        output out[1];
}


simple Processor {
    gates:
        input in;
}


network BurstNetwork {
    submodules:
        burst_generator: BurstGenerator;
        processor: Processor;
    connections:
        burst_generator.out[0] --> processor.in;
}

