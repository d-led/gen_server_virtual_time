// Generated from ActorSimulation DSL
// Network: PipelineNetwork

simple Source {
    gates:
        output out[1];
}


simple Stage1 {
    gates:
        output out[1];
}


simple Stage2 {
    gates:
        output out[1];
}


simple Stage3 {
    gates:
        output out[1];
}


simple Sink {
    gates:
        input in;
}


network PipelineNetwork {
    submodules:
        source: Source;
        stage1: Stage1;
        stage2: Stage2;
        stage3: Stage3;
        sink: Sink;
    connections:
        source.out[0] --> stage1.in;
        stage1.out[0] --> stage2.in;
        stage2.out[0] --> stage3.in;
        stage3.out[0] --> sink.in;
}

