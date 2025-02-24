const math = require('mathjs');

const generate = () => {

    units = {
        dist: "m",
        speed: "m/s",
        pressure: "bar",
        temperature: "K",
        area: "m^2",
        heat: "kJ/min",
        power: "kW"
    };


    T1 = math.randomInt(1000, 1300); 
    T2 = math.randomInt(300, 500);  
    m = math.random(0.3, 0.5);  
    N = math.randomInt(400, 600);    
    P1 = math.randomInt(1400, 1600); 
    P2 = math.randomInt(700, 800);  
    R = 0.287; 



    efficiency = 1 - (T2 / T1);

    Qin = m * R * T1 * Math.log(P1 / P2);
    Wnet = efficiency * Qin;
    
    cyclesPerSec = N / 60; 
    Power = cyclesPerSec * Wnet;

  
    V1 = (m * R * T1) / (P1);
    V2 = V1 * (P1 / P2);

    // Heat Rejected
    Qout = Wnet - Qin;

    // Mean Effective Pressure
    V3 = V2 * Math.pow((T1 / T2), 1 / 0.4);
    V_PD = V3 - V1;
    MEP = Wnet / V_PD;

 
    data = {
        params:
        {
            T1:T1,
            T2:T2,
             m:m,
             N:N,
            P1:P1,
            P2:P2,
        },
        correct_answers: {
            Qin: math.round(Qin, 3),
            Qout: math.round(Qout, 3),
            Power: math.round(Power, 3),
            V2: math.round(V2, 3),
            MEP: math.round(MEP, 3),
            Efficiency: math.round(efficiency * 100, 3)
        },
        nDigits: 3,
        sigfigs: 3
    };

    console.log(data);
    return data;
}

generate();

module.exports = { generate };
