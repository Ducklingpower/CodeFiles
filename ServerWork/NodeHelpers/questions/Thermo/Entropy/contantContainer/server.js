
const math = require('mathjs');

const generate = () => {
  
    const massLabel = "mass";
    const cpLabel = "specific_heat";
    const tInitialLabel = "initial_temperature";
    const heightLabel = "height";


    const units = {
        mass: "kg",
        cp: "kJ/kg·K",
        temperature: "K",
        height: "km",
        entropy: "kJ/K"
    };

  
     mass = math.randomInt(10,100)/10; 
     cp = math.randomInt(30, 60)/10; 
     tInitial = math.randomInt(100, 320); 
     height = math.randomInt(100, 500)/100; 


    // Convert height to meters
    heightInMeters = height * 1000; 

  
    g = 9.81; 
    tFinal = tInitial + (g * heightInMeters) / (cp*1000);

    deltaS = mass * cp * math.log(tFinal / tInitial); 

  
    const data = {
        params: {
            mass: mass,
            cp: cp,
            t_initial: tInitial,
            height: height
        },
        correct_answers: {
            deltaS: math.round(deltaS, 3) 
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