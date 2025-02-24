const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = { 
        "si": { 
            "volume": "m^3",
            "pressure": "kPa"
        },
        "uscs": {
            "volume": "ft^3",
            "pressure": "psi"
        }
    };

    const unitSel = math.randomInt(0, 2); // Randomly select SI or USCS
    const unitsVolume = units[unitSystems[unitSel]].volume;
    const unitsPressure = units[unitSystems[unitSel]].pressure;

    // Randomly generate initial conditions
    const Volume1 = math.randomInt(1, 10);
    const Pressure1 = math.randomInt(100, 200);
    const Volume2 = math.round((Pressure1 * Volume1) / math.randomInt(50, 150), 2); // Using P1V1 = P2V2
    const Pressure2 = math.round((Pressure1 * Volume1) / Volume2, 2); // Using P1V1 = P2V2

    const data = {
        params: { 
            Volume1: Volume1,
            Pressure1: Pressure1,
            Volume2: Volume2,
            Pressure2: Pressure2,
            unitsVolume: unitsVolume,
            unitsPressure: unitsPressure,
        },
        correct_answers: {
            PressureAtVolume2: Pressure2,
            VolumeAtPressure2: Volume2,
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

module.exports = { generate };