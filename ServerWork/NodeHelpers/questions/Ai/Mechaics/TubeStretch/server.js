const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', "uscs"];

    const units = { 
        "si": { 
            "diameter": "m",
            "length": "m",
            "force": "N",
            "modulus": "pa"
        },
        "uscs": {
            "diameter": "in",
            "length": "ft",
            "force": "lb",
            "modulus": "psi"
        }
    };

    // Randomly select unit system
    const unitSel = math.randomInt(0, unitSystems.length);
    const currentUnits = units[unitSystems[unitSel]];

    // Define static ranges for parameters
    const internalDiameter = math.round(math.random(0.05, 0.2), 4);  // meters or inches
    const externalDiameter = internalDiameter + math.round(math.random(0.01, 0.05), 4);  // ensures it's larger than internal
    const length = math.round(math.random(1, 10), 3);  // meters or feet
    const load = math.round(math.random(1000, 10000), 2);  // Newtons or pounds

    // Predefined modulus of elasticity for brass
    const modulusOfElasticity = {
        si: 100e9,  // Pascals
        uscs: 14500e3  // Psi
    };
    const modulusElasticity = modulusOfElasticity[unitSystems[unitSel]];

    // Compute cross-sectional area
    const innerArea = (math.pi / 4) * math.pow(internalDiameter, 2);
    const outerArea = (math.pi / 4) * math.pow(externalDiameter, 2);
    const crossSectionalArea = outerArea - innerArea;  // m^2 or in^2

    // Calculate axial contraction using deltaL = (Force * Length) / (Area * Modulus)
    const contraction = (load * length) / (crossSectionalArea * modulusElasticity);

    // Assemble result in required object structure
    const data = {
        params: {
            internalDiameter,
            externalDiameter,
            length,
            load,
            modulusElasticity,
            unitsDiameter: currentUnits.diameter,
            unitsLength: currentUnits.length,
            unitsLoad: currentUnits.force,
            unitsModulus: currentUnits.modulus,
        },
        correct_answers: {
            contraction: contraction
        },
        nDigits: 3,  // Define the number of digits after the decimal place.
        sigfigs: 3  // Define the number of significant figures for the answer.
    };

    return data;
};

module.exports = {
    generate
};