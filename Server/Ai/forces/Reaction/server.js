const math = require('mathjs');

const generate = () => {
    unitSystems = ['si', 'uscs'];

    units = {
        "si": {
            "dist": "m",
            "force": "N"
        },
        "uscs": {
            "dist": "ft",
            "force": "lb"
        }
    }
    
    let unitSel = math.randomInt(0, 2);
    let unitsDist = units[unitSystems[unitSel]].dist;
    let unitsForce = units[unitSystems[unitSel]].force;

    let length = math.round(math.randomInt(500, 1000) / 100, 2); // Length of the bar
    let force1 = math.round(math.randomInt(100, 500), 2); // Force 1
    let force2 = math.round(math.randomInt(100, 500), 2); // Force 2
    let distance1 = math.round(math.randomInt(100, length * 100) / 100, 2); // Distance of force1 from A
    let distance2 = math.round(math.randomInt(distance1 * 100 / 2, length * 100) / 100, 2); // Distance of force2 from A

    // Calculate equilibrium reactions at supports A and B:
    let reactionA = (force1 * (length - distance1) + force2 * (length - distance2)) / length;
    let reactionB = force1 + force2 - reactionA;

    const data = {
        params: {
            length: length,
            force1: force1,
            force2: force2,
            distance1: distance1,
            distance2: distance2,
            unitsDist: unitsDist,
            unitsForce: unitsForce,
        },
        correct_answers: {
            reactionA: math.round(reactionA, 2),
            reactionB: math.round(reactionB, 2)
        },
        nDigits: 2,
        sigfigs: 2
    };

    console.log(data);
    return data;
}

generate();

module.exports = {
    generate
}