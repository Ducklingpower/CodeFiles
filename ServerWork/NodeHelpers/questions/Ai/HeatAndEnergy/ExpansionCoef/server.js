const math = require('mathjs');

const generate = () => {
    const unitSystems = {
        si: {
            distance: 'm',
            distanceSmall: 'mm',
            temperature: '°C'
        },
        uscs: {
            distance: 'ft',
            distanceSmall: 'in',
            temperature: '°F'
        }
    };

    // Dynamic Parameter Selection
    const selectedSystem = math.randomInt(0, 2) === 0 ? 'si' : 'uscs';
    const units = unitSystems[selectedSystem];

    // Value Generation
    const length = math.randomInt(100, 301); // Length of the wire (100 to 300)
    const initialTemperature = math.randomInt(0, 101); // Initial temperature (0 to 100 °C or °F)
    const increase = math.randomInt(1, 11); // Increase in length (1 to 10 mm or in)
    const finalTemperature = initialTemperature + math.randomInt(10, 51); // Final temperature (10 to 50 °C or °F increase)

    // Coefficient of Linear Expansion Calculation
    // Formula: alpha = (ΔL / L0) / ΔT
    const deltaL = increase / (selectedSystem === 'si' ? 1000 : 12); // convert mm to m for SI or in to ft for USC
    const deltaT = finalTemperature - initialTemperature;
    const coefficientExpansion = deltaL / deltaT;

    // Rounding off the final value
    const roundedCoefficient = coefficientExpansion; // rounding to 3 decimal places

    // Return the structured data
    return {
        params: {
            length: length,
            initialTemperature: initialTemperature,
            increase: increase,
            finalTemperature: finalTemperature,
            unitsDist: units.distance,
            unitsDistSmall: units.distanceSmall
        },
        correct_answers: {
            coefficientExpansion: roundedCoefficient
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};