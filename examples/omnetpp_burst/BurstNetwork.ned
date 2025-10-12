// Generated from ActorSimulation DSL

simple Processor {
    gates:
        input in;
}


simple BurstGenerator {
    gates:
        input in;
        output out[1];
}


network BurstNetwork {
    submodules:
        processor: Processor;
        burst_generator: BurstGenerator;
    connections:
        burst_generator.out[0] --> processor.in;
}

