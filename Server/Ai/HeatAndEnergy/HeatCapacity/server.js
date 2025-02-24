const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = { 
        "si": { 
            "mass": "kg",
            "temperature": "\u00b0C",
            "Cp": "kJ/kg\u00b7\u00b0C",
        },
        "uscs": {
            "mass": "lb",
            "temperature": "\u00b0F",
            "Cp": "BTU/lb\u00b7\u00b0F",
        }
    };
    
    const unitSel = math.randomInt(0, 2); // Select either SI or USCS
    const selectedUnits = units[unitSystems[unitSel]];

    const materialProperties = {
        "Copper": { "Cp_si": 0.385, "Cp_uscs": 0.092 }, // Cp values specific to units
        "Aluminum": { "Cp_si": 0.897, "Cp_uscs": 0.215 },
        "Iron": { "Cp_si": 0.450, "Cp_uscs": 0.108 }
    };
    const materials = Object.keys(materialProperties);
    const selectedMaterial = materials[math.randomInt(materials.length)];
    const materialCp = materialProperties[selectedMaterial][`Cp_${unitSystems[unitSel]}`];

    // Random heat energy in appropriate units
    const Q = (unitSel === 0) ? math.randomInt(100, 500) : math.randomInt(5000, 20000);
    
    // Mass and temperature range
    const mass = (unitSel === 0) ? math.randomInt(1, 10) : math.randomInt(2, 20);
    let Ti, Tf;

    if (unitSel === 0) { 
        Ti = math.randomInt(15, 25);
        Tf = math.randomInt(70, 100);
    } else {
        Ti = math.randomInt(59, 77);
        Tf = math.randomInt(140, 212);
    }

    // Calculate specific heat capacity
    const temperatureChange = Tf - Ti; // Always in degrees of selected temperature unit
    const calculated_Cp = Q / (mass * temperatureChange);
    
    return {
        params: { 
            Q: Q,
            masslabel: mass,
            Ti: Ti,
            Tf: Tf,
            materialName: selectedMaterial,
            unitsTemperature: selectedUnits.temperature,
            unitsCp: selectedUnits.Cp
        },
        correct_answers: {
            Cp: math.round(calculated_Cp, 3) // Round to 3 decimal places for answer
        },
        nDigits: 3,
        sigfigs: 3
    };
}

module.exports = {
    generate
};