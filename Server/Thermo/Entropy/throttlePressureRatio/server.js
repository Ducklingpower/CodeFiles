const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];

    const units = {
        "si": {
            "mass": "kg",
            "entropy": "kW/K",
        },
        "uscs": {
            "mass": "lb",
            "entropy": "Btu/°R",
        }
    };

    const unitSel = 0; 
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsEntropy = units[unitSystems[unitSel]].entropy;

   
    mass = math.randomInt(10,100)/10; 
    entropyChange = math.randomInt(50, 800)/1000;

  
    R = 0.287; 


    lnPressureRatio = -entropyChange / (mass * R);
    pressureRatio = math.exp(lnPressureRatio).toFixed(3); // P2/P1

    const data = {
        params: {
            mass: mass,
            entropy_change: entropyChange,
        },
        correct_answers: {
            pressure_ratio: pressureRatio,
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
