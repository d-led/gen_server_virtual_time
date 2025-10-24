// Generated from ActorSimulation DSL

simple Database {
            gates:
                input in;}


simple LoadBalancer {
            gates:
                output out[3];}


simple Server1 {
            gates:
                input in;
                output out[1];}


simple Server2 {
            gates:
                input in;
                output out[1];}


simple Server3 {
            gates:
                input in;
                output out[1];}


network LoadBalancedSystem {
    submodules:
        database: Database;
        load_balancer: LoadBalancer;
        server1: Server1;
        server2: Server2;
        server3: Server3;
    connections:
        load_balancer.out[0] --> server1.in;
        load_balancer.out[1] --> server2.in;
        load_balancer.out[2] --> server3.in;
        server1.out[0] --> database.in;
        server2.out[0] --> database.in;
        server3.out[0] --> database.in;
}

