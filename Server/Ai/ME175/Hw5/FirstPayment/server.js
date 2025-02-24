const math = require('mathjs');

const generate = () => {
    const unitSystems = {
        currency: 'USD',
        time: 'years'
    };

    // 1. Dynamic Parameter Selection
     cost = math.randomInt(10000, 50000); // Cost of the press between $10,000 and $50,000
     n = math.randomInt(5, 11); // Payment period between 1 and 10 years
     interestRate = math.round(math.random(3, 10), 2); // Annual interest rate between 3% and 10%
    // 2. Value Generation

    // 3. Payment decrease logic
    // Assume the payments decrease by a fixed amount, let's say $500

     paymentDecrease = 5000+math.randomInt(1000,5000);

     
     interestRate = interestRate/100;

 

   
   


     // Calculate the first payment (A) using the formula
      firstTerm = (1 - Math.pow(1 + interestRate, -n)) / interestRate; // Uniform series factor
      secondTerm = (1 - Math.pow(1 + interestRate, -n) - n * interestRate * Math.pow(1 + interestRate, -n)) / (interestRate * interestRate); // Gradient series factor
     
     // Rearrange the formula to solve for A
     firstPayment = (cost + paymentDecrease * secondTerm) / firstTerm;




    // Using the formula for the first payment in terms of the arithmetic series
    // If the first payment is P, then the series is P, P-paymentDecrease, P-2*paymentDecrease, ..., until the total payments equal totalAmount
    // Total payments = n/2 * (2P - (n-1) * paymentDecrease) = totalAmount
    // where n is the number of payments (years)
    // Return the structured data
    return {
        params: {
            cost: cost,
            n:n,
            interestRate: math.round(interestRate,6),
            paymentDecrease: paymentDecrease,
            unitsCurrency: unitSystems.currency,
            unitsTime: unitSystems.time
        },
        correct_answers: {
            firstPayment: math.round(firstPayment,3) // First payment rounded to 3 decimal places
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};