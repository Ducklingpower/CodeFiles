const math = require('mathjs');

const MACRS = {
    '3': [0.3333, 0.4445, 0.1481, 0.0741],
    '7': [0.1429, 0.2449, 0.1749, 0.1249, 0.0893, 0.0892, 0.0893,0.0446],
};

const generate = () => {
    // 1. Dynamic Parameter Selection
    const propertyClasses = ['3'];
    const selectedClass = propertyClasses[math.randomInt(0, propertyClasses.length)];
    const usefulLife = selectedClass === '3' ? 3 : 7;

    // 2. Value Generation
    cost = math.round(math.randomInt(50000,60000), 2); // Random cost between $5000 and $50000
    loan = math.round(cost*0.6,2); 
    payed = math.round(cost-loan,2);
    rate = math.randomInt(5,15);
    BTLCF = math.randomInt(20000,30000);
    taxrate = math.randomInt(15,22);
    
    taxing = taxrate/100;
    i = rate/100;
    // 3. Solution Synthesis
    const depreciationExpenses = MACRS[selectedClass].map(rate => math.round(cost * rate, 2));
    const bookValues = depreciationExpenses.reduce((acc, dep, index) => {
        const previousValue = index === 0 ? cost : acc[index - 1];
        acc.push(math.round(previousValue - dep, 2));
        return acc;
    }, []);


   


    A = loan*((i*(i+1)**5)/((1+i)**(5)-1))

    dp1 = math.round(cost* 0.3333,2) // dp = depreciation
    dp2 = math.round(cost* 0.4445,2)
    dp3 = math.round(cost* 0.1481,2)
    dp4 = math.round(cost* 0.0741,2)

    delta = loan         // delta_n = remaining principle at t = n

    ip1 = delta*i;       // ip = interest payed 
    pp1 = A-ip1;        // pp = principle payed
    delta1 = delta-pp1;
    ti1 = BTLCF - ip1-dp1
    tax1 = ti1*taxing;
    ATCF1 = BTLCF - A - tax1;


    ip2 = delta1*i;       // ip = interest payed 
    pp2 = A-ip2;        // pp = principle payed
    delta2 = delta1-pp2;
    ti2 = BTLCF - ip2-dp2
    tax2 = ti2*taxing;
    ATCF2 = BTLCF  - A - tax2;


    ip3 = delta2*i;       // ip = interest payed 
    pp3 = A-ip3;        // pp = principle payed
    delta3 = delta2-pp3;
    ti3 = BTLCF - ip3-dp3
    tax3 = ti3*taxing;
    ATCF3 = BTLCF - A - tax3;




    ip4 = delta3*i;       // ip = interest payed 
    pp4 = A-ip4;        // pp = principle payed
    delta4 = delta3-pp4;
    ti4 = BTLCF - ip4-dp4
    tax4 = ti4*taxing;
    ATCF4 = BTLCF  - A - tax4;


    ip5 = delta4*i;       // ip = interest payed 
    pp5 = A-ip5;        // pp = principle payed
    delta5 = delta4-pp5;
    ti5 = BTLCF - ip5-0
    tax5 = ti5*taxing;
    ATCF5 = BTLCF - A - tax5;




    

    // Return the structured data
    return {
        params: {
            cost: cost,
            propertyClass: selectedClass,
            usefulLife: usefulLife,
            unitsCurrency: '$',
            taxrate:taxrate,
         
            loan: math.round(loan, 2), 
            payed: payed, // Assuming this is already an integer
            rate: math.round(rate, 2), 
            BTLCF: math.round(BTLCF, 2),
        
            dp1: math.round(dp1, 2),
            dp2: math.round(dp2, 2),
            dp3: math.round(dp3, 2),
            dp4: math.round(dp4, 2),
        
            ip1: math.round(ip1, 2),
            ip2: math.round(ip2, 2),
            ip3: math.round(ip3, 2),
            ip4: math.round(ip4, 2),
            ip5: math.round(ip5, 2),
        
            pp1: math.round(pp1, 2),
            pp2: math.round(pp2, 2),
            pp3: math.round(pp3, 2),
            pp4: math.round(pp4, 2),
            pp5: math.round(pp5, 2),
        
            delta1: math.round(delta1, 2),
            delta2: math.round(delta2, 2),
            delta3: math.round(delta3, 2),
            delta4: math.round(delta4, 2),
            delta5: math.round(delta5, 2),
        
            ti1: math.round(ti1, 2),
            ti2: math.round(ti2, 2),
            ti3: math.round(ti3, 2),
            ti4: math.round(ti4, 2),
            ti5: math.round(ti5, 2),
        
            tax1: math.round(tax1, 2),
            tax2: math.round(tax2, 2),
            tax3: math.round(tax3, 2),
            tax4: math.round(tax4, 2),
            tax5: math.round(tax5, 2),
        
            ATCF1: math.round(ATCF1, 2),
            ATCF2: math.round(ATCF2, 2),
            ATCF3: math.round(ATCF3, 2),
            ATCF4: math.round(ATCF4, 2),
            ATCF5: math.round(ATCF5, 2),
        
            A: math.round(A, 2),
            i: math.round(i, 2)



         

     

        },
        correct_answers: {

            A: math.round(A, 2),

            ip1: math.round(ip1, 2),
            delta1: math.round(delta1, 2),
            ti1: math.round(ti1, 2),
            ATCF1: math.round(ATCF1, 2),

             ip3: math.round(ip3, 2),
            delta3: math.round(delta3, 2),
            ti3: math.round(ti3, 2),
            ATCF3: math.round(ATCF3, 2),

            ip5: math.round(ip5, 2),
            delta5: math.round(delta5, 2),
            ti5: math.round(ti5, 2),
            ATCF5: math.round(ATCF5, 2),


            
            bookValueEndYear1: bookValues[0],
            bookValueEndYear2: bookValues[1],
            bookValueEndYear3: bookValues[2],
            bookValueEndYear4: 0,
            bookValueEndYear5: 0,
         







            
        },
        nDigits: 3,
        sigfigs: 3
    };
};

module.exports = {
    generate
};