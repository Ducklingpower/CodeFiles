const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = { 
        "si": { 
            "volume": "m^3",
            "pressure": "kPa",
            "temperature": "degree C"
        },
        "uscs": {
            "volume": "ft^3",
            "pressure": "psi",
            "temperature": "degree F"
        }
    };

    const unitSel = math.randomInt(0, 2); // Randomly select SI or USCS
    const unitsVolume = units[unitSystems[unitSel]].volume;
    const unitsPressure = units[unitSystems[unitSel]].pressure;
    const unitsTemperature = units[unitSystems[unitSel]].temperature;

    let Volume1, Pressure1, Pressure2, T1, T2;

    // Generate random values for the parameters
    if (unitSel === 0) { // SI
        Volume1 = math.randomInt(1, 5); // in m^3
        Pressure1 = math.randomInt(100, 200); // in kPa
        Pressure2 = math.randomInt(200, 300); // in kPa
        T1 = math.randomInt(273, 373); // in degree C
        T2 = math.randomInt(273, 373); // in degree C
    } else { // USCS
        Volume1 = math.randomInt(1, 15); // in ft^3
        Pressure1 = math.randomInt(10, 30); // in psi
        Pressure2 = math.randomInt(30, 60); // in psi
        T1 = math.randomInt(32, 212); // in degree F
        T2 = math.randomInt(32, 212); // in degree F
    }

    // Apply the Combined Gas Law: (P1 * V1) / T1 = (P2 * V2) / T2
    const Volume2 = (Pressure1 * Volume1 * T2) / (Pressure2 * T1);

    // Prepare the output data structure
    const data = {
        params: { 
            Volume1: Volume1,
            Pressure1: Pressure1,
            Pressure2: Pressure2,
            T1: T1,
            T2: T2,
            unitsVolume: unitsVolume,
            unitsPressure: unitsPressure,
            unitsTemperature: unitsTemperature,
        },
        correct_answers: {
            Volume2: math.round(Volume2, 3),
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

module.exports = { generate };