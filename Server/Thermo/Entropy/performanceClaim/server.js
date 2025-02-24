const math = require('mathjs');

const generate = () => {
  
  const cp = 1.0; 
  const R = 8.314 / 28.97;

 
 T_in = math.randomInt(35, 45); // °C
 P_in = math.randomInt(5,10); // bar
 T_cold = math.randomInt(-20, -10); // °C
 T_hot = math.randomInt(75, 85); // °C
 P_out = math.randomInt(1,3); // bar

 m_dot_cold_fraction = 0.6; 
 m_dot_hot_fraction = 0.4; 

 T_in_K = T_in + 273.15;
 T_cold_K = T_cold + 273.15;
 T_hot_K = T_hot + 273.15;

   energy_balance = m_dot_cold_fraction * cp * (T_in_K - T_cold_K) + m_dot_hot_fraction * cp * (T_in_K - T_hot_K);
   delta_s_cold =  cp * math.log(T_cold_K / T_in_K) - R * math.log(P_out / P_in);
   delta_s_hot = cp * math.log(T_hot_K / T_in_K) - R * math.log(P_out / P_in);
   entropy_generation = m_dot_cold_fraction * delta_s_cold +  m_dot_hot_fraction * delta_s_hot;

   data = {
    params: {
      T_in,
      P_in,
      T_cold,
      T_hot,
      P_out,
    },
    correct_answers: {
      entropy_generation: entropy_generation.toFixed(3),
    },
    nDigits: 3,
    sigfigs: 3,
  };

  console.log(data);
    return data;
};

generate();

module.exports = {
  generate,
};
