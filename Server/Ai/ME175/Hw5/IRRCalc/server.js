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



 // Net annual cash flow (income - expenses)
 function calculateNPV(rate) {
    let annualFactor = ((Math.pow(1 + rate, annualYears) - 1) / (rate * Math.pow(1 + rate, annualYears)));
    let npv = -investment + annualCashFlow * annualFactor + lumpsum / Math.pow(1 + rate, totalYears);
    return npv;
}

// IRR calculation using binary search
let lowerBound = 0; // 0% interest rate
let upperBound = 1; // 100% interest rate
let tolerance = 1e-6; // Accuracy tolerance for IRR

while ((upperBound - lowerBound) > tolerance) {
    let midPoint = (upperBound + lowerBound) / 2;
    let npv = calculateNPV(midPoint);

    if (npv > 0) {
        lowerBound = midPoint;
    } else {
        upperBound = midPoint;
    }
}

// IRR result
 irr = (lowerBound * 100).toFixed(2); // Convert to percentage
   


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
            presentWorth: math.round(presentWorth, 3) ,// Round to 3 decimal places
            irr:irr,
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};