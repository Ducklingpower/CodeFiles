const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = { 
        "si": { 
            "mass": "kg",
            "volume": "m^3",
            "temperature": "K",
            "pressure": "kPa",
            "R": "J/(kg K)"
        },
        "uscs": {
            "mass": "lb",
            "volume": "ft^3",
            "temperature": "&degR",
            "pressure": "psi",
            "R": "BTU/(lb &degR)"
        }
    };

    const unitSel = math.randomInt(0, 2); // Randomly select unit system
    const unitsVolume = units[unitSystems[unitSel]].volume;
    const unitsMass = units[unitSystems[unitSel]].mass;
    const unitsTemperature = units[unitSystems[unitSel]].temperature;
    const unitsPressure = units[unitSystems[unitSel]].pressure;
    const unitsR = units[unitSystems[unitSel]].R;

    // Generate random values for parameters
    let Volume = 0, Mass = 0, T = 0, R = 0;

    if (unitSel === 0) { // SI Units
        Volume = math.randomInt(1, 10); // m^3
        Mass = (math.randomInt(1, 30) / 10); // kg
        T = math.randomInt(250, 300); // K
        R = 2077; // J/(kg K) for helium
    } else { // USCS Units
        Volume = math.randomInt(10, 100); // ft^3
        Mass = (math.randomInt(10, 60) / 10); // lb
        T = math.randomInt(60, 80); // &degR
        R = 53.34; // BTU/(lb &degR) for helium
    }

    // Calculate pressure using ideal gas law: P = (mass * R * T) / Volume
    const Pressure = (Mass * R * T) / Volume;
    const PressureRounded = math.round(Pressure * 1000) / 1000; // Round to 3 decimal places

    const data = {
        params: {
            Volume: Volume,
            Mass: Mass,
            T: T,
            R: R,
            unitsVolume: unitsVolume,
            unitsMass: unitsMass,
            unitsTemperature: unitsTemperature,
            unitsPressure: unitsPressure,
            unitsR: unitsR
        },
        correct_answers: {
            Pressure: PressureRounded
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

module.exports = { generate };