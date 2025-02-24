const math = require('mathjs');

const generate = () => {
   
     P1 = 7; 
     T1 = 200; 
     mdot1 = math.randomInt(15,40); 

     P2 = 7;
     T2 = 40; 
     A2 = math.randomInt(10, 40); 

     V3 = math.randomInt(50,100)/1000;




     // pracice 

     //P1 = 7; 
    // T1 = 200; 
     //mdot1 = 40; 

     //P2 = 7; 
    // T2 = 40; 
     //A2 = 25; 

    // V3 = 0.06;



     v3 = 1.108e-3; 
     v2 = 1.0078e-3;

    
     mdot3 = (V3 / v3);

  
     mdot2 = (mdot3 - mdot1);

    
     velocity2 = ((mdot2 * v2 * 10000) / A2); 

     data = {
        params: {
             P1: P1,
                T1: T1,
                mdot1: mdot1,
                P2: P2,
                T2: T2,
                A2: A2,
                V3: V3,
    },
    
        correct_answers: { 
      
            mdot2: math.round(mdot2,3),
            mdot3: math.round(mdot3,3),
            velocity2: math.round(velocity2,3)
        
    },
       nDigits: 2,
       sigfigs:2
    }
    console.log(data);
    return data;    
};


generate();
module.exports = {
    generate
}