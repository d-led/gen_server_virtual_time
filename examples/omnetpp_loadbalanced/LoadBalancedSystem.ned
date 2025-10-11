// Generated from ActorSimulation DSL
// Network: LoadBalancedSystem

simple LoadBalancer {
    gates:
        output out[3];
}


simple Server1 {
    gates:
        output out[1];
}


simple Server2 {
    gates:
        output out[1];
}


simple Server3 {
    gates:
        output out[1];
}


simple Database {
    gates:
        input in;
}


network LoadBalancedSystem {
    submodules:
        load_balancer: LoadBalancer;
        server1: Server1;
        server2: Server2;
        server3: Server3;
        database: Database;
    connections:
        load_balancer.out[0] --> server1.in;
        load_balancer.out[1] --> server2.in;
        load_balancer.out[2] --> server3.in;
        server1.out[0] --> database.in;
        server2.out[0] --> database.in;
        server3.out[0] --> database.in;
}

