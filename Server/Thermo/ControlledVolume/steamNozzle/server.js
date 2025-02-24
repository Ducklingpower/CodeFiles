const math = require('mathjs');

const generate = () => {
  // Define unit system
  unitSystems = ['si'];

  units = {
    "si": {
      "mass": "kg",
      "dist": "m",
      "speed": "m/s",
      "pressure": "bar",
      "energy": "kJ/kg"
    }
  };

   unitsDist = units[unitSystems[0]].dist;
   unitsSpeed = units[unitSystems[0]].speed;
   unitsMass = units[unitSystems[0]].mass;
   unitsPressure = units[unitSystems[0]].pressure;
   unitsEnergy = units[unitSystems[0]].energy;

 
   p1 = 40   ;
   T1 = 400 ;
   m_dot = math.randomInt(10, 50)/10; 
   p2 =  15 ;
   V2 = math.randomInt(680, 700); 

   


   h1 = 3213.6; 


   kineticEnergyExit = (V2 ** 2) / (2 * 1000); 
   h2 = 2992.5 
   V1 = math.round((((h2-h1+kineticEnergyExit)*2000))**(1/2),0);

   
   kineticEnergyInlet = (V1 ** 2) / 2 / 1000; 


   h2 =math.round(h1 + kineticEnergyInlet - kineticEnergyExit,2);


  
   v2 = 0.1627; 

   a2 = (m_dot * v2) / V2;
   A2 = a2*1000000;


   data = {
    params: {
      p1: p1,
      T1: T1,
      V1: V1,
      m_dot: m_dot,
      p2: p2,
      V2: V2,
      h1:h1,
      h2:h2,
      v2:v2,
      a2:a2,
    },
    correct_answers: {
      exitArea: math.round(A2, 3) 
    },
    nDigits: 3,
    sigfigs: 3
  };

  console.log(data);
  return data;
};

generate();

module.exports = {
  generate
};
