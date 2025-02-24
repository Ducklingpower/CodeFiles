const math = require('mathjs');

const generate = () => {
    const unitSystems = {
        currency: '$',
    };

    // 1. Dynamic Parameter Selection
    const units = unitSystems.currency;

    // 2. Value Generation
     investment = math.randomInt(30000, 50000); // investment between $1000 and $10000
     annualCashFlow = math.randomInt(6000, 10000); // annual cash flow between $100 and $1000
     annualYears = math.randomInt(5, 10); // cash flow duration between 1 and 5 years
     totalYears = annualYears + math.randomInt(15,20); // total years after investment
     marr = math.randomInt(5, 21); // MARR between 5% and 20%

    


    lumpsum=investment;
    i = marr;
    marr = marr/100;

   
    // Total present worth
     presentWorth  = -investment + annualCashFlow*(((1+marr)**(annualYears) - 1 )/( marr*(1+marr)**(annualYears))) + lumpsum/(1+marr)**(totalYears) 
    // Return the structured data
    return {
        params: {
            investment: investment,
            annualCashFlow: annualCashFlow,
            annualYears: annualYears,
            totalYears: totalYears,
            lumpsum: lumpsum, // lump sum between $5000 and $20000
            marr: marr,
            i:i,
            unitsCurrency: units
        },
        correct_answers: {
            presentWorth: math.round(presentWorth, 3) // Round to 3 decimal places
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};