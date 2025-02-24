const math = require('mathjs');

const generate = () => {
 
    const units = {
        dist: "m",
        speed: "m/s",
        pressure: "bar",
        temperature: "K",
        area: "m^2",
        heat: "kJ/min",
        power: "kW"
    };


       v1 = math.randomInt(5, 10);   
       A1 = math.randomInt(1, 5) / 10;  
       Q_dot = math.randomInt(-300, -100);  
       p1 = 1; 
       T1 = 290; 
       p2 = 7; 
       T2 = 450; 
       v2 = math.randomInt(1, 5); //  m/s

    
       R = 8314; 
       M = 28.97;
       Q_dot_s = Q_dot / 60;

    
       rho1 = (p1 * 1e5) / (R / M * T1); 
       m_dot = rho1 * v1 * A1; 
       h1 = T1 * 1.005; 
       h2 = T2 * 1.005; 
      

       W_dot = Q_dot_s + m_dot * ((h1 - h2) + (math.pow(v1, 2) - math.pow(v2, 2)) / 2 / 1000);
   
   
       data = {
   
        params: {
            v1: v1,
            A1: A1,
            Q_dot: Q_dot,
            p1: p1,
            T1: T1,
            p2: p2,
            T2: T2,
            v2: v2,
        },
        correct_answers: {
            Power: math.round(W_dot, 3),
            m_dot:math.round(m_dot,3),
            h1:math.round(h1,3),
            h2:math.round(h2,3),
        },
        units: units
    };

    console.log(data);
    return data;
};

generate();

module.exports = {
    generate
};
