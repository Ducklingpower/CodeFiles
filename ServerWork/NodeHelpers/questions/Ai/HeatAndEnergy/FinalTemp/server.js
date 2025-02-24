const math = require('mathjs');

const generate = () => {
    // Define unit systems
    const unitSystems = ['si', "uscs"];

    // Define measurement units for each category
    const units = { 
        "si": { 
            "mass": "kg",
            "energy": "J",
            "temperature": "°C",
            "Cp": "J/kg°C"
        },
        "uscs": {
            "mass": "lb",
            "energy": "BTU",
            "temperature": "°F",
            "Cp": "BTU/lb°F"
        }
    };

    // Randomly select a unit system (SI or USCS)
    const unitSel = 0; // math.randomInt(0, 2); // For example, choose SI
    const chosenUnits = units[unitSystems[unitSel]];

    // Define material properties
    const materialProperties = { 
        "aluminium": {
            "si": {
                "Cp": 900 // J/kg°C
            },
            "uscs": {
                "Cp": 0.215 // BTU/lb°F
            }
        }
    };

    // Select material and its properties
    const material = "aluminium";
    const Cp = materialProperties[material][unitSystems[unitSel]].Cp;
    
    // Generate random values for the problem
    const m = math.randomInt(1, 10); // Mass in kg (SI) or lb (USCS)
    const Ti = math.randomInt(15, 25); // Initial temperature in °C (SI) or °F (USCS)
    const Q = math.randomInt(2000, 10000); // Heat energy in J (SI) or BTU (USCS)

    // Compute final temperature using the formula: Q = mcΔT
    const Tf = Ti + (Q / (m * Cp)); // Calculate final temperature

    const data = {
        params: { 
            Q: Q,
            m: m,
            Ti: Ti,
            Cp: Cp,
            unitsMass: chosenUnits.mass,
            unitsEnergy: chosenUnits.energy,
            unitsTemperature: chosenUnits.temperature,
            unitsCp: chosenUnits.Cp
        },
        correct_answers: {
            Tf: math.round(Tf, 3) // Round to three significant figures
        },
        nDigits: 3,  // Define the number of digits after the decimal place
        sigfigs: 3   // Define the number of significant figures for the answer
    };

    console.log(data); // For debugging
    return data;
};

module.exports = {
    generate
};