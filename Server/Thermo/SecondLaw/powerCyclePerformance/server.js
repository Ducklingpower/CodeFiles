const math = require('mathjs');

const generate = () => {

     T_hot = math.randomInt(450, 600); 
     T_cold = math.randomInt(250, 350); 
     Q_in = math.randomInt(900, 1100); 
     W_out = math.randomInt(350, 450); 

  
     thermal_efficiency = W_out / Q_in;
     max_efficiency = 1 - (T_cold / T_hot);

   
     claim_possible = thermal_efficiency <= max_efficiency ? 1 : 0; 


    data = {
        params: {
            temperature_hot: T_hot,
            temperature_cold: T_cold,
            heat_input: Q_in,
            work_output: W_out
        },
        correct_answers: {
            ThermalEfficiency: math.round(thermal_efficiency, 3), 
            max_efficiency:math.round(max_efficiency,3),
            claim: claim_possible
        },
        nDigits: 3,
        sigfigs: 3
    };

    console.log(data);
    return data;
}

generate();

module.exports = {
    generate
};
