const math = require('mathjs');

const generate = () => {
    // 1. Dynamic Parameter Selection
    const years = math.randomInt(15, 31); // Mortgage duration between 15 and 30 years
    const interestRate = math.randomInt(1, 7); // Interest rate between 3% and 7%
    const principal = math.randomInt(100000, 500000); // Principal between $100,000 and $500,000

    // 2. Value Generation
    const monthlyInterestRate = (interestRate) /(100*12); // Monthly interest rate
    const numberOfPayments = years * 12; // Total number of monthly payments

    // 3. Solution Synthesis
    // Monthly payment formula: M = P[r(1 + r)^n] / [(1 + r)^n – 1]
    const monthlyPayment = (principal * monthlyInterestRate * math.pow(1 + monthlyInterestRate, numberOfPayments)) / (math.pow(1 + monthlyInterestRate, numberOfPayments) - 1);

    // Total interest paid over the life of the mortgage
    const totalPaid = monthlyPayment * numberOfPayments;
    const totalInterest = totalPaid - principal;

    // Return the structured data
    return {
        params: {
            years: years,
            interestRate: interestRate,
            principal: principal
        },
        correct_answers: {
            monthlyPayment: math.round(monthlyPayment, 3), // Round to 3 decimal places
            totalInterest: math.round(totalInterest, 3) // Round to 3 decimal places
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};