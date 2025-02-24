const math = require('mathjs');

const generate = () => {

    const units = {
        dist: "m",
        speed: "m/s",
        pressure: "bar",
        temperature: "K",
        area: "m^2",
        heat: "kJ/min",
        power: "kW"
    };


  // Given Constants
  T_in = math.randomInt(10, 25); // Inlet air temperature (°C)
  P_in = 1; // Atmospheric pressure (atm)
  V_max = math.randomInt(10,20)/10; // Max inlet velocity (m/s)
  T_out = math.randomInt(30, 50); // Max outlet temperature (°C)
  P_comp = math.randomInt(70,90); // Power for electronics (W)
  P_fan = math.randomInt(10,20); // Power for fan (W)

  cp = 1.005; 
  R = 8.314; 
  M_air = 28.97;
  atm_to_pa = 101325; 


  W_dot = -(P_comp + P_fan); // Total power input (W)


  T1 = T_in + 273.15;
  T2 = T_out + 273.15;

 
  m_dot = -W_dot / (cp * 1000 * (T2 - T1));

  v1 = (R / (M_air / 1000)) * T1 / (P_in * atm_to_pa);


  A1 = m_dot * v1 / V_max; 
  A1_cm2 = A1 * 1e4; 

  // Prepare data output
  data = {
    params: {
      T_in:T_in,
      P_in:P_in,
      V_max:V_max,
      T_out:T_out,
      P_comp:P_comp,
      P_fan:P_fan
    },
    correct_answers: {
      A_fan: math.round(A1_cm2, 3)
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
