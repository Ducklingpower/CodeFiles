const math = require('mathjs');

const generate = () => {

    
     P1 = 0.1; 
     x1 = math.randomInt(90,99)/100;
     P2 = 0.1;
     T2 = math.randomInt(30,60); 
     T3 = math.round(T2*0.45,2); 
     T4 = math.round(T2*0.75,2); 
   



   
     h1 = 2584.7 * x1 + 191.83 * (1 - x1);
     hf = 191.83
     h2 = T2*4.18; 
     h3 = T3*4.18; 
     h4 = T4*4.18; 





     massFlowRatio = (h1 - h2) / (h4 - h3);
     energyTransferRate = h2 - h1; 
 
     formattedMassFlowRatio = math.round(massFlowRatio, 3);
     formattedEnergyTransferRate = math.round(energyTransferRate, 3);

    // Data structure for output
 data = {
        params: {
            P1:P1,
            x1:x1,
            P2:P2,
            T2:T2,
            T3:T3,
            T4:T4
        },
        correct_answers: {
            ratio: formattedMassFlowRatio,
            heatTransfer: formattedEnergyTransferRate
        },
        nDigits: 3,
        sigfigs: 3
    };

    console.log(data);
    return data;
}

// Generate the data
generate();

module.exports = {
    generate
};
