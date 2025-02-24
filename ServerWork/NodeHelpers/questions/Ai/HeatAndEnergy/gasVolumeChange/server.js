

const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const units = {
        "si": {
            "volume": "m^3",
            "temperature": "degree C"
        },
        "uscs": {
            "volume": "ft^3",
            "temperature": "degree F"
        }
    };

    const unitSel = math.randomInt(0, 2); // Randomly select unit system
    const unitsVolume = units[unitSystems[unitSel]].volume;
    const unitsTemperature = units[unitSystems[unitSel]].temperature;

    // Initial parameters
    const Volume1 = math.randomInt(1, 10);  // Initial volume
    const T1 = math.randomInt(15, 25);      // Initial temperature in range 15 to 25
    const T2 = math.randomInt(30, 50);      // Final temperature in range 30 to 50

    // Using Charles's Law: V1/T1 = V2/T2, so V2 = V1 * (T2/T1)
    const Volume2 = Volume1 * (T2 / T1);

    const data = {
        params: {
            Volume1: Volume1,
            T1: T1,
            T2: T2,
            unitsVolume: unitsVolume,
            unitsTemperature: unitsTemperature
        },
        correct_answers: {
            Volume2: math.round(Volume2, 3) // Round the answer to 3 decimal places
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

module.exports = { generate };