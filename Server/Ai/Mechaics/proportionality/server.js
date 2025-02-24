const math = require('mathjs');

const generate = () => {

    const unitSystems = ['si', "uscs"];
    
    const units = { 
        "si": { 
            "dist": "m",
            "force": "N",
        },
        "uscs": {
            "dist": "feet",
            "force": "lb",
        }
    };
    
    // Random selection of either SI or USCS unit system
    const unitSel = math.randomInt(0,2);
    const unitsDist = units[unitSystems[unitSel]].dist;
    const unitsForce = units[unitSystems[unitSel]].force;

    // Generating random values for delta and force within a reasonable range
    let delta1 = math.random(0.05, 0.15);  // Initial stretch within 5cm to 15cm or equivalent
    let forceF = math.random(50, 200);  // Initial force within 50N (or 50lb) to 200N (or 200lb)

    // Calculate delta2 as a 20% increase over delta1 as an example
    let delta2 = delta1 * 1.2;

    // Calculating force needed to stretch to delta2 using proportionality (F1/d1 = F2/d2)
    let force_delta2 = math.round((forceF / delta1) * delta2, 3);  // Maintain 3 significant figures

    const data = {
        params: {
             delta1: delta1,
             forceF: forceF,
             delta2: delta2,
             unitsDist: unitsDist,
             unitsForce: unitsForce
        },

        correct_answers: { 
            force_delta2: force_delta2
        },

       nDigits: 3,
       sigfigs: 3
    };

    console.log(data);

    return data;
}
generate();
module.exports = {
    generate
};