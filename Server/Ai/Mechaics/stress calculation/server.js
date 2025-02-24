const math = require('mathjs');

const generate = () => {
    // Define possible unit systems
    const unitSystems = ['si', 'uscs'];
    
    // Define units for each system
    const units = {
        "si": {
            "area": "m^2",
            "force": "N"
        },
        "uscs": {
            "area": "ft^2",
            "force": "lbf"
        }
    };
    
    // Randomly select a unit system
    const unitSel = math.randomInt(0, 2);
    const unitsArea = units[unitSystems[unitSel]].area;
    const unitsForce = units[unitSystems[unitSel]].force;
    
    // Assign values to parameters based on the unit system selected
    let area, forceF;

    if (unitSel === 0) { // SI units
        area = (math.randomInt(10, 100) / 10.0); // area in m^2
        forceF = (math.randomInt(1000, 5000)); // force in N
    } else { // USCS units
        area = (math.randomInt(1, 10)); // area in ft^2
        forceF = (math.randomInt(500, 1200)); // force in lbf
    }

    // Calculate stress
    const stress = forceF / area; // Stress = Force / Area
    
    const data = {
        params: {
            area: area,
            forceF: forceF,
            unitsArea: unitsArea,
            unitsForce: unitsForce
        },

        correct_answers: {
            stress: stress
        },

        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

module.exports = {
    generate
};