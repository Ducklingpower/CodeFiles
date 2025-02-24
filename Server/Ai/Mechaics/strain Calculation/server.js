const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = {
        "si": {
            "dist": "m",
            "distSmall": "mm"
        },
        "uscs": {
            "dist": "feet",
            "distSmall": "in"
        }
    };

    // Select unit system randomly
    const unitSel = math.randomInt(0, 2);
    const unitsDist = units[unitSystems[unitSel]].dist;
    const unitsDistSmall = units[unitSystems[unitSel]].distSmall;

    // Assign values
    let length, contraction;

    if (unitSel === 0) {  // SI units
        length = (math.randomInt(10, 100));  // in meters
        contraction = ((math.randomInt(1, 50)) + math.random()).toFixed(2);  // in mm
    } else { // USCS units
        length = (math.randomInt(30, 300));  // in feet
        contraction = ((math.randomInt(1, 12)) + math.random()).toFixed(2);  // in inches
    }

    // Calculate strain
    let epsilon;
    if (unitSel === 0) {
        epsilon = ((contraction / 1000) / length);
    } else {
        epsilon = ((contraction / 12) / length);
    }

    // Calculate percentage strain
    const percentStrain = epsilon * 100;

    const data = {
        params: {
            length: length,
            contraction: contraction,
            unitsDist: unitsDist,
            unitsDistSmall: unitsDistSmall
        },
        correct_answers: {
            epsilon: epsilon,
            percent_strain: percentStrain
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

module.exports = {
    generate
};