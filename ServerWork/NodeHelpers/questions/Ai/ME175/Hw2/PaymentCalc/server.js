const math = require('mathjs');

const generate = () => {
    // 1. Dynamic Parameter Selection
    const loanAmount = math.randomInt(10000, 50001); // Loan amount between $10,000 and $50,000
    const numPayments = math.randomInt(5, 21); // Number of payments between 5 and 20 years
    const interestRate = math.round(math.random(3, 10), 2); // Interest rate between 3% and 10%

    // 2. Value Generation
    const r = interestRate / 100; // Convert percentage to decimal

    // 3. Solution Synthesis
    // Using the formula for annuity payment: P = (r*PV) / (1 - (1 + r)^-n)

    const annualPayment = (loanAmount)/(1+((1+r)**(numPayments-1)-1) /(r*(1+r)**(numPayments-1)))
    // Return the structured data
    return {
        params: {
            loanAmount: loanAmount,
            numPayments: numPayments,
            interestRate: interestRate
        },
        correct_answers: {
            annualPayment: math.round(annualPayment, 3) // Round to 3 decimal places
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};