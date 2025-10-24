// Generated from ActorSimulation DSL

simple Sink {
            gates:
                input in;}


simple Source {
            gates:
                output out[1];}


simple Stage1 {
            gates:
                input in;
                output out[1];}


simple Stage2 {
            gates:
                input in;
                output out[1];}


simple Stage3 {
            gates:
                input in;
                output out[1];}


network PipelineNetwork {
    submodules:
        sink: Sink;
        source: Source;
        stage1: Stage1;
        stage2: Stage2;
        stage3: Stage3;
    connections:
        source.out[0] --> stage1.in;
        stage1.out[0] --> stage2.in;
        stage2.out[0] --> stage3.in;
        stage3.out[0] --> sink.in;
}

