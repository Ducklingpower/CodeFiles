const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = { 
        "si": { 
            "volume": "m^3",
            "pressure": "kPa",
        },
        "uscs": {
            "volume": "ft^3",
            "pressure": "psi",
        }
    };

    const unitSel = math.randomInt(0, 2); // Randomly select unit system
    const unitsVolume = units[unitSystems[unitSel]].volume;
    const unitsPressure = units[unitSystems[unitSel]].pressure;

    let VolumeInitial, VolumeFinal, PressureInitial, PressureFinal;

    if (unitSel === 0) {
        VolumeInitial = math.randomInt(1, 5);  // SI: 1 to 5 m^3
        VolumeFinal = math.randomInt(1, 5);    // SI: 1 to 5 m^3
        PressureInitial = math.randomInt(100, 200); // SI: 100 to 200 kPa
    } else {
        VolumeInitial = math.randomInt(10, 30); // USCS: 10 to 30 ft^3
        VolumeFinal = math.randomInt(10, 30);   // USCS: 10 to 30 ft^3
        PressureInitial = math.randomInt(15, 30); // USCS: 15 to 30 psi
    }

    // Using the ideal gas equation for isothermal process: P1 * V1 = P2 * V2
    PressureFinal = (PressureInitial * VolumeInitial) / VolumeFinal;

    // Round to 3 significant figures
    PressureFinal = math.round(PressureFinal, 3);

    const data = {
        params: { 
            VolumeInitial: VolumeInitial,
            VolumeFinal: VolumeFinal,
            PressureInitial: PressureInitial,
            unitsVolume: unitsVolume,
            unitsPressure: unitsPressure,
        },
        correct_answers: {
            PressureFinal: PressureFinal,
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

module.exports = { generate };