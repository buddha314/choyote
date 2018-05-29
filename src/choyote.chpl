use Relch,
    moschitto,
    Time;

config const WORLD_WIDTH: int,
             WORLD_HEIGHT: int,
             N_ANGLES: int,
             N_DISTS: int,
             STEPS: int,
             EPOCHS: int,
             EPOCH_EMIT_INTERVAL: int,
             EPOCH_SLEEP_INTERVAL: real,
             DOG_STARTING_POSITION_X: int,
             DOG_STARTING_POSITION_Y: int,
             CAT_STARTING_POSITION_X: int,
             CAT_STARTING_POSITION_Y: int,
             DOG_SPEED: real,
             CAT_SPEED: real,
             DOG_EPSILON: real,
             CAT_EPSILON: real;

proc buildSim() {
  var env = new Environment(name="simulatin' amazing!"),
      boxWorld = new BoxWorld(width=WORLD_WIDTH, height=WORLD_HEIGHT
        ,defaultDistanceBins = N_DISTS
        ,defaultAngleBins = N_ANGLES
        ,wrap=false),
      dog = boxWorld.addAgent(name="dog"
        , position=new Position2D(x=DOG_STARTING_POSITION_X, y=DOG_STARTING_POSITION_Y)
        , speed=DOG_SPEED): BoxWorldAgent,
      cat = boxWorld.addAgent(name="cat"
        , position=new Position2D(x=CAT_STARTING_POSITION_X, CAT_STARTING_POSITION_Y)
        , speed=CAT_SPEED): BoxWorldAgent,
      catSensor = boxWorld.getDefaultAngleSensor(),
      dogSensor = boxWorld.getDefaultAngleSensor();

  // Create the simulation
  env.world = boxWorld;

  //dog = boxWorld.setAgentTarget(agent=dog, target=cat, sensor=catSensor): BoxWorldAgent;
  dog = boxWorld.setAgentPolicy(agent=dog, policy=new DQPolicy(epsilon=DOG_EPSILON, avoid=false)): BoxWorldAgent;
  cat = boxWorld.setAgentTarget(agent=cat, target=dog, sensor=dogSensor, epsilon=CAT_EPSILON, avoid=true): BoxWorldAgent;
  dog = boxWorld.addAgentServo(agent=dog, sensor=catSensor, boxWorld.getDefaultMotionServo()): BoxWorldAgent;
  cat = boxWorld.addAgentServo(agent=cat, sensor=dogSensor, boxWorld.getDefaultMotionServo()): BoxWorldAgent;
  dog = boxWorld.addAgentSensor(agent=dog, target=cat,
   sensor=boxWorld.getDefaultDistanceSensor(), reward=boxWorld.getDefaultProximityReward()): BoxWorldAgent;

  return env;
}


proc main() {
  writeln("""
    Dog starts at (25, 25). The cat is now an agent and is
    positioned at (110,100).  The dog is using a FollowTargetPolicy and
    basically bum rushes the cat, overshoots, and comes back and forth.  The cat
    runs from the dog but is out-paced (speed 1 vs 3)

    Neither agent yet has a learning algorithm in place.  They are both too stupid for words.

    They make me sick they are so stupid. I'm ashamed I invented them...
    """);
  var sim = buildSim();

  var cli  = new MoschittoPublisher();

  cli.Connect();
  sleep(1);

  const
        WINDOW_START_MOD = 0,
        WINDOW_STOP_MOD  = 100;
  var emit: bool = false;
  for a in sim.run(epochs=EPOCHS, steps=STEPS) {
    if a: EpochDTO != nil {
        if a.id % EPOCH_EMIT_INTERVAL == 0 {
          cli.PublishObj("/data/epoch", a);
          emit = true;
        } else {
          emit = false;
        }
        writeln(a);
    }
    if emit && a: AgentDTO != nil {
      cli.PublishObj("/data/agent", a);
      sleep(EPOCH_SLEEP_INTERVAL);
      writeln(a);
    }
  }
}
