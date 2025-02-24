const math = require('mathjs');

const generate = () => {
    const unitSystems = {
        currency: 'USD',  // Assuming a single currency for the example
        time: 'months'
    };

    // 1. Dynamic Parameter Selection
     P = math.randomInt(300000, 500000); // Loan amount between 1000 and 50000
     i = math.randomInt(1, 8); // Annual interest rate between 1% and 10%
     t = math.randomInt(12, 121); // Loan term between 12 and 120 months


    // 2. Value Generation
    im = i / 100 / 12; // Convert annual rate to monthly
    
    A = P * ( (im*(im+1)**(360))/( (im+1)**(360) - 1));
    amountOwed = A * ( ((im+1)**(360-t) - 1)/( im*(im+1)**(360-t)));
    AmountPayed = A*t;
    PrincipalPayed = P-amountOwed;
    IntrestPayed = AmountPayed-PrincipalPayed;

    // 3. Solution Synthesis
 
   
AmountPayed = math.round(AmountPayed,2)
    // Return the structured data
    im = math.round(im,6)
    A = math.round(A,2)
    return {
        params: {
          
           i:i,
           P:P,
           A:A,
           t:t,
           im:im,
            unitsCurrency: unitSystems.currency,
            unitsTime: unitSystems.time
        },
        correct_answers: {
            amountOwed: math.round(amountOwed, 3), // Round to 3 decimal places
            AmountPayed:Math.round(AmountPayed,2),
            PrincipalPayed:math.round(PrincipalPayed,2),
            IntrestPayed:math.round(IntrestPayed,2),
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};