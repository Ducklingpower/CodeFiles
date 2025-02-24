const math = require('mathjs');

const MACRS = {
    '5': [0.2, 0.32, 0.192, 0.1152, 0.1152,0.0576],
    '7': [0.1429, 0.2449, 0.1749, 0.1249, 0.0893, 0.0892, 0.0893,0.0446],
};

const generate = () => {
    // 1. Dynamic Parameter Selection
    const propertyClasses = ['7'];
    const selectedClass = propertyClasses[math.randomInt(0, propertyClasses.length)];
    const usefulLife = selectedClass === '5' ? 5 : 7;

    // 2. Value Generation
    cost = math.round(math.randomInt(20000,50000), 2); // Random cost between $5000 and $50000
    salvage = math.round(cost*0.6,2);
    salvageLow = math.round(cost*0.05,2);
    year = math.round(4,6)
    tax = math.randomInt(15,25);


   
    i = tax/100;
    // 3. Solution Synthesis
    const depreciationExpenses = MACRS[selectedClass].map(rate => math.round(cost * rate, 2));
    const bookValues = depreciationExpenses.reduce((acc, dep, index) => {
        const previousValue = index === 0 ? cost : acc[index - 1];
        acc.push(math.round(previousValue - dep, 2));
        return acc;
    }, []);


    // part 1 
    taxLiability = (salvage-0)*i;

    // part 2 

    taxpayed = (salvage-bookValues[year-1])*i;


    // part 3 

    taxpayedLow = (salvageLow - bookValues[year-1])*i





    dp1 = math.round(cost* 0.1429,2)
    dp2 = math.round(cost* 0.2449,2)
    dp3 = math.round(cost* 0.1749,2)
    dp4 = math.round(cost* 0.1249,2)
    dp5 = math.round(cost* 0.0893,2)
    dp6 = math.round(cost* 0.0892,2)
    dp7 = math.round(cost* 0.0893,2)
    dp8 = math.round(cost* 0.0446,2)



     bvyear = bookValues[year-1]
    // Return the structured data
    return {
        params: {
            cost: cost,
            propertyClass: selectedClass,
            usefulLife: usefulLife,
            unitsCurrency: '$',
            tax:tax,
            salvage:salvage,
            salvageLow:salvageLow,
            year:year,

            dp1:dp1,
            dp2:dp2,
            dp3:dp3,
            dp4:dp4,
            dp5:dp5,
            dp6:dp6,
            dp7:dp7,
            dp8:dp8, 

            bvyear:bvyear,

        },
        correct_answers: {

            
            bookValueEndYear1: bookValues[0],
            bookValueEndYear2: bookValues[1],
            bookValueEndYear3: bookValues[2],
            bookValueEndYear4: bookValues[3],
            bookValueEndYear5: bookValues[4],
            bookValueEndYear6: bookValues[5],
            bookValueEndYear7: bookValues[6],
            bookValueEndYear8: 0,






            taxLiability:taxLiability,
            taxpayed:taxpayed,
            taxpayedLow:taxpayedLow,

            
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};