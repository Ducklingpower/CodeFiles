const math = require('mathjs');

const generate = () => {
    const unitSystems = {
        si: {
            currency: 'USD',
            time: 'years'
        },
        uscs: {
            currency: 'USD',
            time: 'years'
        }
    };

    // 1. Dynamic Parameter Selection
    const selectedSystem = math.randomInt(0, 2) === 0 ? 'si' : 'uscs';
    const units = unitSystems[selectedSystem];

    // 3. Value Generation
    const t1 = math.randomInt(1, 11); // Random time for first withdrawal (1 to 10 years)
    const t2 = t1 + math.randomInt(1, 6); // Second withdrawal time after the first (1 to 5 years later)
    const t3 = t2 + math.randomInt(1, 6); // Third withdrawal time after the second (1 to 5 years later)
    const withdraw1 = math.randomInt(1000, 5001); // Random amount for first withdrawal
    const withdraw2 = math.randomInt(1000, 5001); // Random amount for second withdrawal
    const withdraw3 = math.randomInt(1000, 5001); // Random amount for third withdrawal
    const rate = math.random(0.01, 0.1); // Interest rate between 1% and 10%
    const t0 = 0; // Initial investment time

    // 4. Solution Synthesis
    // Calculate the present value needed for each withdrawal
    const pv1 = withdraw1 / Math.pow(1 + rate, t1);
    const pv2 = withdraw2 / Math.pow(1 + rate, t2);
    const pv3 = withdraw3 / Math.pow(1 + rate, t3);

    const totalDeposit = pv1 + pv2 + pv3; // Total deposit needed

    // Return the structured data
    return {
        params: {
            t0: t0,
            t1: t1,
            t2: t2,
            t3: t3,
            withdraw1: withdraw1,
            withdraw2: withdraw2,
            withdraw3: withdraw3,
            rate: rate.toFixed(2), // Format rate to 2 decimal places
            currency: units.currency,
            time: units.time
        },
        correct_answers: {
            deposit_amount: math.round(totalDeposit, 2) // Round to 2 decimal places
        },
        nDigits: 2,
        sigfigs: 2
    };
};

module.exports = {
    generate
};