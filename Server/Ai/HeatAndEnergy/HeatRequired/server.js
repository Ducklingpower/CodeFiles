const math = require('mathjs');

const generate = () => {

    const unitSystems = ['si', 'uscs'];
    
    const units = {
        "si": { 
            "mass": "kg",
            "temperature": "degree C",
            "Cp": "kJ/kg C",
            "heat": "kJ"
        },
        "uscs": {
            "mass": "lb",
            "temperature": "degree F",
            "Cp": "BTU/lb F",
            "heat": "BTU"
        }
    }
  
    const unitSel = math.randomInt(0, 2); // Randomly select between SI and USCS
    const selectedUnits = units[unitSystems[unitSel]];
    
    // Generate random parameters for the problem
    let m, Ti, Tf, Cp;
    if (unitSel === 0) { // SI
        m = math.randomInt(1, 10); // kilograms
        Ti = math.randomInt(15, 25); // degrees Celsius
        Tf = math.randomInt(30, 100); // degrees Celsius
        Cp = 4.18; // kJ/kg C, specific heat capacity of water
    } else { // USCS
        m = math.randomInt(2, 20); // pounds
        Ti = math.randomInt(60, 80); // degrees Fahrenheit
        Tf = math.randomInt(100, 200); // degrees Fahrenheit
        Cp = 1.0; // BTU/lb F, specific heat capacity of water
    }

    // Calculation of heat required
    const deltaT = Tf - Ti;
    const Q = m * Cp * deltaT; // Heat energy

    // Return the data structure
    return {
        params: {
            m: m,
            Ti: Ti,
            Tf: Tf,
            Cp: Cp,
            unitsMass: selectedUnits.mass,
            unitsTemperature: selectedUnits.temperature,
            unitsCp: selectedUnits.Cp,
            unitsHeat: selectedUnits.heat
        },
        correct_answers: {
            Q: Q // Ensure the answer has 3 significant figures
        },
        nDigits: 3,
        sigfigs: 3
    };
}

generate();

module.exports = {
    generate
};