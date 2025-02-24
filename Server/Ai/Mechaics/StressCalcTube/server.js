const math = require('mathjs');

const generate = () => {

    const unitSystems = ['si', 'uscs'];

    const units = {
        "si": {
            "diameter": "m",
            "length": "m",
            "load": "N",
            "shortening": "mm"
        },
        "uscs": {
            "diameter": "ft",
            "length": "ft",
            "load": "lb-force",
            "shortening": "in"
        }
    };
    
    // Randomly select unit system
    const unitSel = math.randomInt(0, 2);
    const currentUnits = units[unitSystems[unitSel]];

    // Generate random values based on the selected unit system
    let outsideDiameter, insideDiameter, length, load, shortening;

    if (unitSel === 0) { // SI
        outsideDiameter = math.random(0.1, 0.5); // meters
        insideDiameter = math.random(0.05, outsideDiameter); // meters
        length = math.random(1, 5); // meters
        load = math.random(10000, 50000); // Newtons
        shortening = math.random(1, 10); // millimeters
    } else { // USCS
        outsideDiameter = math.random(0.3, 1.6); // feet
        insideDiameter = math.random(0.1, outsideDiameter); // feet
        length = math.random(1, 15); // feet
        load = math.random(2000, 11000); // pound-force
        shortening = math.random(0.1, 0.4); // inches
    }

    // Calculate cross-sectional area (A = π/4 * (D_o^2 - D_i^2))
    const area = math.pi / 4 * (math.pow(outsideDiameter, 2) - math.pow(insideDiameter, 2));

    // Calculate compressive stress (σ = F / A)
    const compressiveStress = load / area;

    const data = {
        params: {
            outside_diameter: outsideDiameter,
            inside_diameter: insideDiameter,
            length: length,
            load: load,
            shortening: shortening,
            unitsDiameter: currentUnits.diameter,
            unitsLength: currentUnits.length,
            unitsLoad: currentUnits.load,
            unitsShortening: currentUnits.shortening
        },
        correct_answers: {
            compressive_stress: compressiveStress
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