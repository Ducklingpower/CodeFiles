const math = require('mathjs');

const generate = () => {
    // Define unit systems available
    unitSystems = ['si', 'uscs'];

    // Units for each system
    units = {
        "si": {
            "dist": "m",
            "percentageStrain": "%"
        },
        "uscs": {
            "dist": "ft",
            "percentageStrain": "%"
        }
    };

    // Randomly select a unit system
    unitSel = 0;
    
    // Select units based on the chosen unit system
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsPercentageStrain = units[unitSystems[unitSel]].percentageStrain;

    // Value generation for wire length and percentage strain
    if (unitSel === 0) { // SI units
        length = math.randomInt(1, 10); // Length in meters
        percentageStrain = math.randomInt(1, 5); // Strain in percentage
    } else { // USCS units
        length = math.randomInt(3, 30); // Length in feet
        percentageStrain = math.randomInt(1, 5); // Strain in percentage
    }

    // Calculate extension based on selected units
    if (unitSel === 0) { // SI units
        extension = (percentageStrain / 100) * length; // Extension in meters
    } else { // USCS units
        extension = (percentageStrain / 100) * length; // Extension converted to feet to meters
    }

    // Return result in the specified format
    data = {
        params: {
            length: length,
            percentage_strain: percentageStrain,
            unitsDist: unitsDist,
            unitsPercentageStrain: unitsPercentageStrain
        },
        correct_answers: {
            extension: extension
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