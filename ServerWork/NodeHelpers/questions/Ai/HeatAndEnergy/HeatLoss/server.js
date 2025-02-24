const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = {
        "si": {
            "mass": "kg",
            "temperature": "°C",
            "heat": "J",
            "Cp": "J/(kg °C)"
        },
        "uscs": {
            "mass": "lb",
            "temperature": "°F",
            "heat": "BTU",
            "Cp": "BTU/(lb °F)"
        }
    };

    const unitSel = 0; // 0 for SI, 1 for USCS

    const unitsMass = units[unitSystems[unitSel]].mass;
    const unitsTemperature = units[unitSystems[unitSel]].temperature;
    const unitsHeat = units[unitSystems[unitSel]].heat;
    const unitsCp = units[unitSystems[unitSel]].Cp;

    const materialProperties = {
        "cast iron": { "Cp": 500 },
        "aluminum": { "Cp": 897 },
        "copper": { "Cp": 385 },
        "gold": { "Cp": 129 },
        "silver": { "Cp": 235 }
    };

    const materialNames = Object.keys(materialProperties);
    const materialName = materialNames[math.randomInt(0, materialNames.length)];
    const Cp = materialProperties[materialName].Cp;

    const m = math.randomInt(1, 20); // Mass in kg or lb
    const Ti = math.randomInt(30, 150); // Initial temperature in °C or °F
    const Tf = math.randomInt(10, Ti); // Final temperature in °C or °F (less than Ti)

    const Q_lost = m * Cp * (Ti - Tf); // Energy lost in J or BTU

    return {
        params: {
            m,
            Ti,
            Tf,
            Cp,
            materialName,
            unitsMass,
            unitsTemperature,
            unitsHeat,
            unitsCp
        },
        correct_answers: {
            Q_lost: Q_lost.toFixed(3) // Round to 3 decimal places
        },
        nDigits: 3,  // Define the number of digits after the decimal place.
        sigfigs: 3   // Define the number of significant figures for the answer.
    };
};

module.exports = {
    generate
};