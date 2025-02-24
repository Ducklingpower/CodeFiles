const math = require('mathjs');

const generate = () => {
    // Define possible unit systems
    const unitSystems = ['si', 'uscs'];
    // Define units for each system
    const units = {
        "si": {
            "dist": "mm",
            "force": "N",
            "stress": "Pa"
        },
        "uscs": {
            "dist": "in",
            "force": "lbf",
            "stress": "psi"
        }
    };
    
    // Randomly select a unit system
    const unitSel = 0;
    const unitSystem = unitSystems[unitSel];
    const unitsDist = units[unitSystem].dist;
    const unitsForce = units[unitSystem].force;
    const unitsStress = units[unitSystem].stress;

    // Generate random parameters
    const length = math.randomInt(10, 100);  // in mm or in
    const width = math.randomInt(10, 100);   // in mm or in
    const height = math.randomInt(10, 30);   // in mm or in
    const force = math.randomInt(5, 100);    // in N or lbf
    const displacement = math.randomInt(1, 5);  // in mm or in
    
    // Calculate shear stress
    const area = (length/1000) * (width/1000);  // Cross-sectional area in mm^2 or in^2
    const shearStress = force / area; // in Pa or psi

    // Calculate shear strain
    const shearStrain = displacement / height; // dimensionless

    // Assemble data object
    const data = {
        params: {
            length,
            width,
            height,
            force,
            displacement,
            unitsDist,
            unitsForce,
            unitsStress
        },
        correct_answers: {
            shearStress: shearStress.toFixed(3),
            shearStrain: shearStrain.toFixed(3)
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
}