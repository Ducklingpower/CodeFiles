const math = require('mathjs');

const generate = () => {

    // Define unit systems
    const unitSystems = ['si', 'uscs'];
    const units = {
        "si": {
            "temp": "C",
            "stress": "MPa",
            "modulus": "Pa",
            "alpha": "1/C"
        },
        "uscs": {
            "temp": "F",
            "stress": "psi",
            "modulus": "psi",
            "alpha": "1/F"
        }
    };

    // Randomly select a unit system
    const unitSel = math.randomInt(0, 2);
    const unitsTemp = units[unitSystems[unitSel]].temp;
    const unitsStress = units[unitSystems[unitSel]].stress;
    const unitsModulus = units[unitSystems[unitSel]].modulus;
    const unitsAlpha = units[unitSystems[unitSel]].alpha;

    // Assign random values to parameters
    const tempFree = math.randomInt(10, 30); // Temperature where rail is stress-free
    const stress = math.randomInt(10, 50); // Stress required to cause buckling

    // Assign values for modulus of elasticity and thermal expansion coefficient
    let modulusElasticity = 2.1; // Base value for modulusElasticity x 10^11
    let thermalExpansionCoeff = 12; // Base value for alpha x 10^-6

    if (unitSel === 1) {
        modulusElasticity = 30; // Adjust for USCS
        thermalExpansionCoeff = 7; // Adjust for USCS
    }

    // Calculate the buckling temperature
    // Using the formula: T_buckling = T_free + \(\frac{\sigma}{E \cdot \alpha} \)
    const deltaTemp = stress*10**6 / (modulusElasticity * 1e11 * thermalExpansionCoeff * 1e-6);
    const tempBuckling = tempFree + deltaTemp;

    // Structure the data to return
    const data = {
        params: {
            tempFree: tempFree,
            stress: stress,
            modulusElasticity: modulusElasticity,
            thermalExpansionCoeff: thermalExpansionCoeff,
            unitsTemp: unitsTemp,
            unitsStress: unitsStress,
            unitsModulus: unitsModulus,
            unitsAlpha: unitsAlpha,
        },

        correct_answers: {
            tempBuckling: math.round(tempBuckling, 3),
        },

        // Additional properties for display
        nDigits: 3,
        sigfigs: 3
    };

    console.log(data);
    return data;
};

module.exports = {
    generate
};

// Run the function to check output
// Uncomment for testing
// generate();