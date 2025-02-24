const math = require('mathjs');

const generate = () => {
   
    units = {
        dist: "m",
        speed: "m/s",
        pressure: "bar",
        temperature: "K",
        area: "m^2",
        heat: "kJ/min",
        power: "kW"
    };


    T_H = math.randomInt(800, 1200); 
    T_C = math.randomInt(250, 350); 
    N = math.randomInt(1500, 2500); 
    P = math.randomInt(150, 250); 
   

  
     efficiency = 1 - (T_C / T_H);

  
     heat_supplied = P / efficiency;


     cycles_per_sec = N / 60; 
     work_per_cycle = (P * 1000) / cycles_per_sec;// (j)

    
    data = {
        params: {
            T_H: T_H,
            T_C: T_C,
            N: N,
            P: P,
            
        },
        correct_answers: {
            efficiency: math.round(efficiency, 3),
            heat_supplied: math.round(heat_supplied, 3),
            work_per_cycle:math.round(work_per_cycle,3),
            
        },
        
        nDigits: 3,
        sigfigs: 3
    };

    console.log(data);
    return data;
};

generate();
module.exports = { generate };