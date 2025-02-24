const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = { 
        "si": { 
            "temperature": "degree C",
            "pressure": "kPa"
        },
        "uscs": {
            "temperature": "degree F",
            "pressure": "psi"
        }
    };

    const unitSel = math.randomInt(0, 2); // Randomly select SI or USCS
    const unitsTemperature = units[unitSystems[unitSel]].temperature;
    const unitsPressure = units[unitSystems[unitSel]].pressure;

    // Generate random initial temperature and pressure
    const T1 = math.randomInt(20, 100); // Initial temperature in range 20 to 100
    const Pressure1 = unitSel === 0 ? math.randomInt(100, 200) : math.randomInt(15, 30); // Pressure in kPa or psi
    const T2 = T1 + math.randomInt(10, 30); // Final temperature is higher than initial

    // Using the ideal gas law: P1/T1 = P2/T2 ==> P2 = P1 * (T2/T1)
    const PressureFinal = Pressure1 * (T2 / T1);

    const data = {
        params: { 
            T1: T1,
            T2: T2,
            Pressure1: Pressure1,
            unitsTemperature: unitsTemperature,
            unitsPressure: unitsPressure,
        },
        correct_answers: {
            PressureFinal: math.round(PressureFinal * 1000) / 1000, // Round to 3 decimal places
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

module.exports = { generate };