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

    let volumeInitial, volumeFinal, Pressure1, Pressure2, T1;

    if (unitSel === 0) { // SI
        volumeInitial = math.randomInt(1, 5); // m^3
        volumeFinal = math.randomInt(5, 10); // m^3
        Pressure1 = math.randomInt(100, 200); // kPa
        Pressure2 = math.randomInt(50, 150); // kPa
        T1 = math.randomInt(20, 100); // degree C
    } else { // USCS
        volumeInitial = math.randomInt(10, 20); // ft^3
        volumeFinal = math.randomInt(20, 30); // ft^3
        Pressure1 = math.randomInt(15, 30); // psi
        Pressure2 = math.randomInt(5, 15); // psi
        T1 = math.randomInt(70, 150); // degree F
    }

    // Using ideal gas law: (P1 * V1) / T1 = (P2 * V2) / T2
    const T2 = (Pressure2 * volumeFinal * T1) / (Pressure1 * volumeInitial);

    const data = {
        params: { 
            volumeInitial: volumeInitial,
            volumeFinal: volumeFinal,
            Pressure1: Pressure1,
            Pressure2: Pressure2,
            T1: T1,
            unitsVolume: unitsVolume,
            unitsPressure: unitsPressure,
            unitsTemperature: unitsTemperature
        },
        correct_answers: {
            T2: math.round(T2, 3)
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

module.exports = { generate };