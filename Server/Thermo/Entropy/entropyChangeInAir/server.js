const math = require('mathjs');

const generate = () => {


    mass = math.randomInt(10, 50)/10; 
    T1 = math.randomInt(100, 350); 
    P1 = math.randomInt(50, 120); 
    T2 = math.randomInt(500, 900); 
    P2 = math.randomInt(400, 600); 

    R = 0.287;
    cp = 1.005; 
    V1 = (mass * R * T1) / P1; 
    V2 = (mass * R * T2) / P2; 
    deltaS = mass * cp * math.log(T2 / T1) + mass * R * math.log(V2 / V1);

    const data = {
        params: {
            mass: mass,
            T1: T1,
            P1: P1,
            T2: T2,
            P2: P2
        },
        correct_answers: {
            deltaS: math.round(deltaS, 3) // rounded to 3 significant figures
        },
     
    };

    console.log(data);
    return data;
};

generate();

module.exports = {
    generate
};
