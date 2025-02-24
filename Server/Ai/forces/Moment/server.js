const math = require('mathjs');

const generate = () => {

    // Define unit systems
    const unitSystems = ['si', 'uscs'];

    // Units configuration
    const units = { 
        si: { 
            length: 'm',
            force: 'N',
            moment: 'N*m'
        },
        uscs: {
            length: 'ft',
            force: 'lb',
            moment: 'lb*ft'
        }
    };
    
    // Randomly select a unit system
    const unitSelIndex = math.randomInt(0, unitSystems.length);
    const selectedUnitSystem = unitSystems[unitSelIndex];
    const selectedUnits = units[selectedUnitSystem];

    // Generate parameters
    const force = math.round(math.random(10, 100), 2);
    const l1 = math.round(math.random(0.5, 2), 2);
    const l2 = math.round(math.random(0.1, l1), 2);

    // Solution Synthesis
    const moment = force * l1; // Moment
    const requiredForce = moment / l2; // Force for reduced length

    const data = {
        params: {
            force: force,
            l1: l1,
            l2: l2,
            unitsForce: selectedUnits.force,
            unitsLength: selectedUnits.length,
            unitsMoment: selectedUnits.moment
        },
        correct_answers: {
            moment: math.round(moment, 3),
            requiredForce: math.round(requiredForce, 3)
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