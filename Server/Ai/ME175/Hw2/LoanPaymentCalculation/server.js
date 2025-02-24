const math = require('mathjs');

const generate = () => {
    const unitSystems = {
        currency: 'USD',
        // You can add other currencies if needed
    };

    // 1. Dynamic Parameter Selection
    const units = unitSystems.currency;

    // 2. Value Generation
    const loan_amount = math.randomInt(1000, 50000); // Loan amount between $1000 and $50000
    const years = math.randomInt(1, 21); // Payment period between 1 and 20 years
    const interest_rate = math.randomInt(1, 11); // Interest rate between 1% and 10%

    // 3. Solution Synthesis
    const r = interest_rate / 100; // Convert percentage to decimal
    const annual_payment = (loan_amount * r) / (1 - Math.pow(1 + r, -years)); // Calculate annual payment using formula

    // Return the structured data
    return {
        params: {
            loan_amount: loan_amount,
            years: years,
            interest_rate: interest_rate,
            unitsCurrency: units
        },
        correct_answers: {
            annual_payment: math.round(annual_payment, 3) // Round to 3 decimal places
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};