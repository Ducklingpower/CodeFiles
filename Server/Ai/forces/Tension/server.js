const math = require('mathjs');

const generate = () => {

    const unitSystems = ['si', 'uscs'];
    const units = {
        "si": {
            "force": "N",
            "angle": "degrees"
        },
        "uscs": {
            "force": "lb",
            "angle": "degrees"
        }
    };
    
    const unitSel = math.pickRandom([0, 1]);
    const unitsForce = units[unitSystems[unitSel]].force;
    const unitsAngle = units[unitSystems[unitSel]].angle;

    const F1 = math.randomInt(1000, 5000); // Randomly generate load force in the chosen unit
    const theta1 = math.randomInt(20, 70); // Angle with the vertical for rope 1
    const theta2 = math.randomInt(20, 70); // Angle with the vertical for rope 2

    // Solve for the tensions using trigonometric equilibrium equations
    const T1 = F1 / (math.sin(math.unit(theta1, unitsAngle)) + (math.sin(math.unit(theta2, unitsAngle)) * math.cos(math.unit(theta1, unitsAngle)) / math.cos(math.unit(theta2, unitsAngle))));
    const T2 = T1 * math.cos(math.unit(theta1, unitsAngle)) / math.cos(math.unit(theta2, unitsAngle));

    const data = {
        params: {
            F1: F1,
            theta1: theta1,
            theta2: theta2,
            unitsForce: unitsForce,
            unitsAngle: unitsAngle
        },
        correct_answers: {
            Tension1: T1,
            Tension2: T2
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

console.log(generate());

module.exports = {
    generate
};