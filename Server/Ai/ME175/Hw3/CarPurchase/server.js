const math = require('mathjs');

const generate = () => {
    const unitSystems = {
        currency: 'USD',
        time: 'months'
    };

    // 1. Dynamic Parameter Selection
    const purchasePrice = math.randomInt(20000, 100001); // price between $20,000 and $100,000
    const downPayment = math.randomInt(2000, 20001); // down payment between $2,000 and $20,000
    const loanTerm = math.randomInt(12, 73); // loan term between 12 and 72 months
    const interestRate = math.randomInt(3, 11); // interest rate between 3% and 10%

    // 2. Value Generation
    const loanAmount = purchasePrice - downPayment; // amount to be financed
    const monthlyInterestRate = (interestRate / 100) / 12; // monthly interest rate

    // 3. Solution Synthesis
    const monthlyPayment = (loanAmount * monthlyInterestRate) / (1 - math.pow(1 + monthlyInterestRate, -loanTerm));

    scam  = monthlyPayment + 300*math.randomInt(5,10)/10;
    over = scam-monthlyPayment;
    // Return the structured data
    return {
        params: {
            purchasePrice: purchasePrice,
            downPayment: downPayment,
            loanTerm: loanTerm,
            interestRate: interestRate,
            unitsCurrency: unitSystems.currency,
            unitsTime: unitSystems.time,
            scam:math.round(scam,1),
            
        },
        correct_answers: {
            monthlyPayment: math.round(monthlyPayment, 3), // Round to 3 decimal places
            over:over,
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};