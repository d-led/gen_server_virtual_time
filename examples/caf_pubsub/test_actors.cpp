// Generated from ActorSimulation DSL
// Catch2 tests for PubSubActors

#include <catch2/catch_test_macros.hpp>
#include <caf/all.hpp>
#include "atoms.hpp"
#include "publisher_actor.hpp"
#include "subscriber1_actor.hpp"
#include "subscriber2_actor.hpp"
#include "subscriber3_actor.hpp"

using namespace caf;

// Simple compilation tests - verifying that generated code compiles
// The executable itself never creates an actor_system, so the atoms' type ID
// block is registered by CAF_MAIN(caf::id_block::ActorSimulation) in main.cpp

TEST_CASE("Headers compile successfully", "[compilation]") {
  // Just verify that all headers can be included without errors
  SUCCEED("All headers compiled successfully");
}

TEST_CASE("Atom definitions are valid", "[atoms]") {
  // Verify atoms are accessible (event_atom exists in all generated examples)
  [[maybe_unused]] auto test_atom = event_atom_v;
  SUCCEED("Atoms defined successfully");
}
