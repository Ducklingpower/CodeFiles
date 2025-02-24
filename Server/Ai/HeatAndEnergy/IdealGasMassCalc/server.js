const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = { 
        "si": { 
            "mass": "kg",
            "volume": "m^3",
            "pressure": "kPa",
            "temperature": "&degC",
            "gasConstant": "J/(kg K)"
        },
        "uscs": {
            "mass": "lb",
            "volume": "ft^3",
            "pressure": "psi",
            "temperature": "&degF",
            "gasConstant": "BTU/(lb R)"
        }
    };

    const unitSel = math.randomInt(0, 2); // Randomly select unit system
    const unitsVolume = units[unitSystems[unitSel]].volume;
    const unitsPressure = units[unitSystems[unitSel]].pressure;
    const unitsTemperature = units[unitSystems[unitSel]].temperature;
    const unitsMass = units[unitSystems[unitSel]].mass;
    const unitsGasConstant = units[unitSystems[unitSel]].gasConstant;

    let Pressure, Volume, Temperature, R;

    if (unitSel === 0) { // SI units
        Pressure = math.randomInt(90, 110); // Pressure in kPa
        Volume = math.randomInt(100, 200); // Volume in m^3
        Temperature = math.randomInt(15, 30); // Temperature in °C
        R = 287.05; // Gas constant for air in J/(kg K)
    } else { // USCS units
        Pressure = math.randomInt(14, 16); // Pressure in psi
        Volume = math.randomInt(35, 50); // Volume in ft^3
        Temperature = math.randomInt(60, 90); // Temperature in °F
        R = 53.34; // Gas constant for air in BTU/(lb R)
    }

    // Convert Temperature to Kelvin or Rankine based on unit system
    const TInKelvin = unitSel === 0 ? Temperature + 273.15 : (Temperature + 459.67) * (5 / 9);

    // Calculate mass using the ideal gas law: mass = (Pressure * Volume) / (R * Temperature)
    const mass = (Pressure * Volume) / (R * TInKelvin);

    const data = {
        params: { 
            Temperature: Temperature,
            Pressure: Pressure,
            Volume: Volume,
            R: R,
            unitsVolume: unitsVolume,
            unitsPressure: unitsPressure,
            unitsTemperature: unitsTemperature,
            unitsMass: unitsMass,
            unitsGasConstant: unitsGasConstant
        },
        correct_answers: {
            mass: math.round(mass * 1000) / 1000 // Round to 3 decimal places
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

module.exports = { generate };
