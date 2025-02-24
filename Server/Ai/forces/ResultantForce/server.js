const math = require('mathjs');

const generate = () => {
    // Define random range for forces and angles
    const force1 = math.randomInt(10, 100); // Newtons
    const force2 = math.randomInt(10, 100); // Newtons
    const angle = math.randomInt(0, 180); // Degrees, inclination to force1

    // Calculate the resultant force using the law of cosines
    const resultantMagnitude = math.sqrt(
        math.pow(force1, 2) + math.pow(force2, 2) +
        2 * force1 * force2 * math.cos(math.unit(angle, 'deg').to('rad'))
    );

    // Calculate the direction of the resultant using the law of sines
    const direction = math.atan2(
        force2 * math.sin(math.unit(angle, 'deg').to('rad')),
        force1 + force2 * math.cos(math.unit(angle, 'deg').to('rad'))
    );
    const directionDegrees = math.unit(direction, 'rad').to('deg').toNumber();

    const data = {
        params: {
            force1: force1,
            force2: force2,
            angle: angle
        },
        correct_answers: {
            resultantMagnitude: math.round(resultantMagnitude, 3),
            resultantDirection: math.round(directionDegrees, 3)
        },
        nDigits: 3,  // Number of decimal places
        sigfigs: 3  // Number of significant figures
    };

    console.log(data);
    return data;
};

module.exports = {
    generate
};