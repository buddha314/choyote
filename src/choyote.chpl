use Relch,
    moschitto,
    Time;

config const WORLD_WIDTH: int,
             WORLD_HEIGHT: int,
             N_ANGLES: int,
             N_DISTS: int,
             STEPS: int,
             EPOCHS: int,
             DOG_STARTING_POSITION_X: int,
             DOG_STARTING_POSITION_Y: int,
             CAT_STARTING_POSITION_X: int,
             CAT_STARTING_POSITION_Y: int,
             DOG_SPEED: real,
             CAT_SPEED: real;

proc buildSim() {

  var sim = new Environment(name="simulatin' amazing!"),
     boxWorld = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT, wrap=false),
     //dog = new Agent(name="dog", position=new Position(x=25, y=25), speed=DOG_SPEED),
     dog = new Agent(name="dog"
      , position=new Position(x=DOG_STARTING_POSITION_X, y=DOG_STARTING_POSITION_Y)
      , speed=DOG_SPEED),
     //cat = new Agent(name="cat", position=new Position(x=150, y=130), speed=CAT_SPEED);
     cat = new Agent(name="cat"
       , position=new Position(x=CAT_STARTING_POSITION_X, y=CAT_STARTING_POSITION_Y), speed=CAT_SPEED);

   // Create the simulation
  sim.world = boxWorld;
  dog = sim.add(dog);
  cat = sim.add(cat);
  dog = sim.setAgentTarget(agent=dog, target=cat, sensor=boxWorld.getDefaultAngleSensor());
  cat = sim.setAgentTarget(agent=cat, target=dog, sensor=boxWorld.getDefaultAngleSensor(), avoid=true);
  dog = sim.addAgentServo(dog, boxWorld.getDefaultMotionServo());
  cat = sim.addAgentServo(cat, boxWorld.getDefaultMotionServo());
  dog = sim.addAgentSensor(agent=dog, target=cat,
    sensor=boxWorld.getDefaultDistanceSensor(), reward=boxWorld.getDefaultProximityReward());

  return sim;
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

  for a in sim.run(epochs=EPOCHS, steps=STEPS) {
    cli.PublishObj("/data/agent", a.writeRecord());
    writeln(a.writeRecord());
  }
}
