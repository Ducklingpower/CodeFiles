const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];

    const units = {
        "si": {
            "force": "kN",
        },
        "uscs": {
            "force": "kip",
        }
    };

    // Randomly select a unit system
    const unitSel = math.randomInt(0, 2);
    const unitsForce = units[unitSystems[unitSel]].force;

    // Generate random force values
    const force1 = math.randomInt(1, 100); // Random force in kN
    const force2 = math.randomInt(1, 100); // Random force in kN

    // Calculate resultant forces
    const resultantSameDirection = force1 + force2; // Forces are additive
    const resultantOppositeDirection = Math.abs(force1 - force2); // Forces are subtractive

    // Prepare data to return
    const data = {
        params: {
            force1: force1,
            force2: force2,
            unitsForce: unitsForce
        },
        correct_answers: {
            resultant_same_direction: resultantSameDirection,
            resultant_opposite_direction: resultantOppositeDirection
        },
        nDigits: 3,
        sigfigs: 3
    };

    console.log(data);
    return data;
};

module.exports = {
    generate
};