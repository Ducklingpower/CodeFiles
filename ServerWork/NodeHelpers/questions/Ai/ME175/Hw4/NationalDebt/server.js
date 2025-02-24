const math = require('mathjs');

const generate = () => {
    // 1. Define constants for the national debt and revenue
   
debt = math.randomInt(20,50);
taxrev = math.randomInt(10,30)/10;
ii = math.randomInt(1,5);
i = ii/100;

debt1 = debt;
interest = (taxrev / debt)*100
let years = 0;

// Iterative calculation
while (debt1 > 0) {
    debt1 = debt1 * (1 + i) - taxrev;
    years++;
}




    // Return the structured data
    return {
        params: {
           
            debt: debt,
            taxrev: taxrev,
            ii:ii,
            i:i,
        },
        correct_answers: {
            years: math.round(years, 3), // Rounded to 3 decimal places
            interest:math.round(interest,3)
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};