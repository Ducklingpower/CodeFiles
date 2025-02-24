const math = require('mathjs');

const generate = () => {
    
    // Define unit systems - in this case, focus on SI as that is specified
    const units = {
        "si": {
            "force": "N",
            "dist": "mm", // For diameter input, will convert
            "work": "J" // Joules for work output
        }
    };
    
    // Select SI units for this problem
    const unitSel = "si";
    const unitsForce = units[unitSel].force;
    const unitsDist = units[unitSel].dist;

    // Generate randomized parameters within a reasonable range
    const force = math.randomInt(10, 1000); // force in N
    const diameter = math.randomInt(200, 500); // diameter in mm
    const revolutions = math.randomInt(1, 20); // number of revolutions

    // Calculate the work done
    // Convert diameter from mm to meters for calculation purposes
    const radiusInMeters = (diameter / 1000) / 2;
    const distanceTravelledInMeters = 2 * math.pi * radiusInMeters * revolutions;
    const workDone = force * distanceTravelledInMeters;

    const data = {
        params: {
            force: force,
            diameter: diameter,
            revolutions: revolutions,
            unitsForce: unitsForce,
            unitsDist: unitsDist,
            unitsWork: units[unitSel].work
        },
        correct_answers: {
            workDone: math.round(workDone, 3) // Round to 3 significant figures
        },
        nDigits: 3,
        sigfigs: 3
    };

    console.log(data);
    return data;
};

generate();

module.exports = {
    generate
};