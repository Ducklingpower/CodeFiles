const math = require('mathjs');

const generate = () => {
    const unitSystems = {
        usd: {
            currency: 'USD'
        },
        eur: {
            currency: 'USD'
        }
    };

    // 1. Dynamic Parameter Selection
    const selectedSystem = math.randomInt(0, 2) === 0 ? 'usd' : 'eur';
    const units = unitSystems[selectedSystem];


// 2. Value Generation
 mortgageInitial = math.randomInt(100000, 500000); // Mortgage amount between $100,000 and $500,000
 interestRate = math.randomInt(3, 6); // Interest rate between 3% and 5%

// 3. Solution Synthesis
 monthlyInterestRate = (interestRate / 100) / 12;
 im = math.round(monthlyInterestRate,7);
 numberOfPayments = 30 * 12; // 30 years of monthly payments
 monthlyPayment = (mortgageInitial * monthlyInterestRate) / (1 - Math.pow(1 + monthlyInterestRate, -numberOfPayments));

// Threshold for interest portion
 interestThreshold = monthlyPayment / 3;

// Initialize variables
let mortgage = mortgageInitial; // Remaining mortgage balance
let month = 0;

// Calculate the month in which interest portion is less than one third of the total payment
for (let i = 1; i <= numberOfPayments; i++) {
    // Calculate the interest portion for this month
    const interestPortion = mortgage * monthlyInterestRate;

    // Check if the interest portion is less than one-third of the monthly payment
    if (interestPortion < interestThreshold) {
        month = i; // Record the first month meeting the condition
        break;
    }

    // Update the remaining mortgage balance
    mortgage -= (monthlyPayment - interestPortion);
}
A = monthlyPayment ;
    // Return the structured data
    return {
        params: {
            mortgage: math.round(mortgage,2),
            interestRate: interestRate,
            unitsCurrency: units.currency,
            A:math.round(A,2),
            im:im,

        },
        correct_answers: {
            month: month
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};