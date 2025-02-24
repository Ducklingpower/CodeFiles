const math = require('mathjs');

const generate = () => {
    const unitSystems = {
        currency: 'USD'
    };

    // 1. Dynamic Parameter Selection
    const units = unitSystems;

    // 2. Value Generation
    const deposit = math.randomInt(500, 2001); // monthly deposit between 500 and 2000
    const yearsDeposit = math.randomInt(10, 31); // deposit period between 10 and 30 years
    const interestRate1 = math.randomInt(3, 8); // first interest rate between 3% and 8%
    const interestRate2 = math.randomInt(5, 10); // second interest rate between 5% and 10%
    const yearsWithdraw = math.randomInt(5, 21); // withdrawal period between 5 and 20 years

    // 3. Solution Synthesis
    const monthsDeposit = yearsDeposit * 12;
    const monthsWithdraw = yearsWithdraw * 12;
    const monthlyRate1 = (interestRate1 / 100) / 12;
    const monthlyRate2 = (interestRate2 / 100) / 12;

    // Future Value of an Annuity formula for deposits
    const futureValue = deposit * (math.pow(1 + monthlyRate1, monthsDeposit) - 1) / monthlyRate1 * (1 + monthlyRate1);

    // Monthly withdrawal calculation using Present Value of an Annuity formula
    const withdrawal = futureValue * monthlyRate2 / (1 - math.pow(1 + monthlyRate2, -monthsWithdraw));

    // Return the structured data
    return {
        params: {
            deposit: deposit,
            yearsDeposit: yearsDeposit,
            interestRate1: interestRate1,
            interestRate2: interestRate2,
            yearsWithdraw: yearsWithdraw,
            unitsCurrency: units.currency
        },
        correct_answers: {
            withdrawal: math.round(withdrawal, 2) // Round to 2 decimal places
        },
        nDigits: 2,
        sigfigs: 2
    };
};

module.exports = {
    generate
};