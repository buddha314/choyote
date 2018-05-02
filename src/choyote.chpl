use Chrest,
    ChrestWebsockets,
    ChrestUtils,
    Random,
    NumSuch,
    Relch;

config const EMIT: bool,              // Push data to the socket?
             REPORT_INTERVAL: int,    // How often to push data?
             API_HOST: string,
             API_PORT: int,
             WS_PORT: int,
             EPOCHS: int,
             WORLD_WIDTH: int,
             WORLD_HEIGHT: int,
             N_RABBITS: int,
             N_COYOTES: int;

class ChoyoteController: ChrestController {
  proc Get(ref req:Request,ref res:Response) {
    //runSim();
  }

}

proc runWithEmissions() {
  var srv = new Chrest(API_HOST,API_PORT);
  var ws = new ChrestWebsocketServer(WS_PORT);
  srv.Routes().setServeFiles(true);
  srv.Routes().setFilePath("www");
  var choyoteController = new ChoyoteController();
  srv.Routes().Get("/data", choyoteController);

  
  // Now run the sim
  begin runSim();
  
  begin srv.Listen(); //Here you run the http server in one thread

  ws.Listen(); //Here you run you websocket server this blocks the simulation making loop as a server
  ws.Close();
  srv.Close();
}


proc main() {
  // Decide if we are pushing to the client
  if EMIT {
    runWithEmissions();
  } else {
    runSim();
  }
}

record AgentDTO {
  var x: real,
      y: real;
}

proc runSim() {
  var sim = new Simulation(name="simulating amazing", epochs=EPOCHS);
  sim.world = new World(width=WORLD_WIDTH, height=WORLD_HEIGHT);
  for i in 1..N_RABBITS {
    const randx = rand(a=0, b=WORLD_WIDTH),
          randy = rand(a=0, b=WORLD_HEIGHT);
    var ifs:[1..0] Sensor,
        wfs:[1..0] Sensor;
    ifs.push_back(new RabbitHerdCentroid(size=7));
    wfs.push_back(new CurrentWeather(size=5));
    var a = new Agent(name="rabbit_" + i:string
      , internalSensors= ifs
      , worldSensors = wfs
      , position=new Position(randx, randy));
    sim.add(a);
  }
  for x in sim.run() {
    writeln(x);
    var ad = new AgentDTO(x=x.position.x, y= x.position.y);
    //Use the function chrestPubSubPublish(channel:string,obj) to send obj parameter as json to the clients.
    chrestPubSubPublish("data",ad); //Here you are sending data to the websocket channel "data" queue that will send them to the websocket clients.

  }
}

class NearestRabbit : Sensor {
  proc init(size:int) {
    super.init(size=size);
    this.complete();
  }

  // Computationally inefficient, we'll get there
  proc v(me: Agent, them:[] Agent) {
    var ds: [them.domain] real;
    forall t in them.domain {
      ref you = them[t];
      ds[t] = sqrt((me.position.x - t.position.x)**2 + (me.position.y - t.position.y)**2);
    }
    var mn = min reduce ds;
    var v: [1..this.size] int;
    v[3] = 1;
    return v;
  }
}

class CurrentWeather: Sensor {
  proc init(size:int) {
    super.init(size=size);
    this.complete();
  }
  proc v(me:Agent, them:[] Agent) {
    var v: [1..this.size] int = [1];
    return v;
  }
}

class RabbitHerdCentroid: Sensor {
  proc init(size:int) {
    super.init(size=size);
    this.complete();
  }

  proc v(me:Agent, them:[] Agent) {
    var v:[1..this.size] int;
    v[2] = 1;
    return v;
  }
}
