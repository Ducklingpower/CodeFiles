const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = { 
        "si": { 
            "length": "m",
            "temperature": "degree C",
            "alpha": "1/C"
        },
        "uscs": {
            "length": "ft",
            "temperature": "degree F",
            "alpha": "1/F"
        }
    };

    const unitSel = math.randomInt(0, 2); // Randomly select SI or USCS
    const unitsLength = units[unitSystems[unitSel]].length;
    const unitsTemperature = units[unitSystems[unitSel]].temperature;
    const unitsAlpha = units[unitSystems[unitSel]].alpha;

    // Properties of iron for linear expansion
    const alpha = (unitSel === 0) ? 12e-6 : 6.67e-6; // SI: 12 x 10^-6 1/C, USCS: 6.67 x 10^-6 1/F

    // Generate random values for initial length and temperature
    const L0 = math.randomInt(1, 10); // Length in meters or feet
    const T0 = (unitSel === 0) ? math.randomInt(0, 100) : math.randomInt(32, 212); // Temperature in degree C or degree F
    const Tf = (unitSel === 0) ? math.randomInt(100, 200) : math.randomInt(212, 400); // Working temperature

    // Calculate the length under working conditions
    const deltaT = Tf - T0;
    const L = L0 * (1 + alpha * deltaT);

    return {
        params: {
            L0: L0,
            T0: T0,
            Tf: Tf,
            alpha: alpha,
            unitsLength: unitsLength,
            unitsTemperature: unitsTemperature,
            unitsAlpha: unitsAlpha
        },
        correct_answers: {
            L: L
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = { generate };