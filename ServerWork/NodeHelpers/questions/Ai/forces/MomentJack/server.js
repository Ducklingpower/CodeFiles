const math = require('mathjs');

const generate = () => {
    // Define the unit systems. Here, we'll use SI units.
    const unitSystems = ['si', "uscs"];
    const units = { 
        "si": { 
            "force": "N",
            "forceLarge": "kN", // Large force unit
            "moment": "N*m",
            "length": "m"
        },
        "uscs": { 
            "force": "lb",
            "forceLarge": "kips", // Large force unit
            "moment": "lb*ft",
            "length": "ft"
        }
    };

    // Randomly select a unit system.
    const unitSel = math.randomInt(0, 2);
    const system = unitSystems[unitSel];
    const unitConversion = (system === "si") ? 1000 : 1000; // Conversion factor from "kN" to "N" or "kips" to "lb"
    
    const unitsForce = units[system].force;
    const unitsForceLarge = units[system].forceLarge;
    const unitsMoment = units[system].moment;
    const unitsLength = units[system].length;

    // Generate problem values
    const moment = math.round(math.random(500, 5000), 2);
    const force1 = math.round(math.random(100, 500), 2);
    const force2 = math.round(math.random(0.1, 5), 2); // kN or kips

    // Calculate the effective lengths of the handle
    const lengthHandleF1 = math.round(moment / force1, 3); // L = M / F
    const lengthHandleF2 = math.round(moment / (force2 * unitConversion), 3); // L = M / (F*1000)

    const data = {
        params: {
            moment: moment,
            force1: force1,
            force2: force2,
            unitsMoment: unitsMoment,
            unitsForce: unitsForce,
            unitsForceLarge: unitsForceLarge,
            unitsLength: unitsLength
        },

        correct_answers: { 
            lengthHandleF1: lengthHandleF1,
            lengthHandleF2: lengthHandleF2,
        },

        nDigits: 3,   // Number of digits after the decimal place.
        sigfigs: 3    // Number of significant figures.
    };

    console.log(data);
    return data;
};

module.exports = {
    generate
};