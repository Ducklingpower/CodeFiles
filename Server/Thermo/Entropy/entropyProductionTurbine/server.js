const math = require('mathjs');

const generate = () => {
  // Define units
  units = {
    "si": {
      "temperature": "K",
      "pressure": "bar",
      "speed": "m/s",
      "work": "kJ/kg",
      "entropy": "kJ/(kg·K)"
    }
  };

  unitSel = "si"; 
  unitsTemp = units[unitSel].temperature;
  unitsPressure = units[unitSel].pressure;
  unitsSpeed = units[unitSel].speed;
  unitsWork = units[unitSel].work;
  unitsEntropy = units[unitSel].entropy;


  P_in = 30; //  bar
  T_in = 400; // °C
  v_in = math.randomInt(200,250); // m/s
  T_out = 100; // °C
  v_out = math.randomInt(100,150); //  m/s
  W_turbine = math.randomInt(400,800); // kJ/kg
  T_surf = math.randomInt(200,500); //  K

// Practice numb

//P_in = 30; 
//T_in = 400; 
//v_in = 160;
//T_out = 100; 
//v_out = 100; 
//W_turbine = 540; 
//T_surf = 350; 


  s1 = 6.9212; // 30bar and 400 c
  s2 = 7.3549; // sg(100c)
  h1 = 3230.9; // 30bar and 400 c
  h2 = 2676.1; // hg(100c)

  
  Q_dot_per_m = W_turbine + (h2 - h1) + (Math.pow(v_out, 2) - Math.pow(v_in, 2)) / (2 * 1000);

  
  sigma_dot_per_m = -(Q_dot_per_m / T_surf) + (s2 - s1);

  data = {
    params: {
      P_in: P_in,
      T_in: T_in,
      v_in: v_in,
      T_out: T_out,
      v_out: v_out,
      W_turbine: W_turbine,
      T_surf: T_surf
    },
    correct_answers: {
      entropy_production_rate: math.round(sigma_dot_per_m, 4)
    },
    units: {
      entropy: unitsEntropy
    }
  };

  console.log(data);
  return data;
};

generate();

module.exports = {
  generate
};
