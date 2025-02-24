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

    // Constants
    R = 2.077; // kJ/kg-K for Helium
    cp = 5.1954; // kJ/kg-K for Helium

    // Randomized Inputs
    T1 = math.randomInt(900, 1100); // K
    P1 = math.randomInt(900, 1100); // kPa
    P2 = math.randomInt(100, 200); // kPa
    W = math.randomInt(5,15)*10**5; // kW
    n = math.randomInt(12,15)/10; // polytropic index

    
   

    // Exit Temperature Calculation (T2)
    T2 = T1 * Math.pow((P2 / P1), (n - 1) / n);

    // Mass Flow Rate Calculation (m_dot)
    numerator = W * (n - 1);
    denominator = n * R * T1 * (1 - Math.pow((P2 / P1), (n - 1) / n));
    m_dot = numerator / denominator;

    // Heat Transfer Calculation (Q_dot)
    Q_dot = W + m_dot * cp * (T2 - T1);

    // Prepare Data
    data = {
        params: {
            T1: T1,
            P1: P1,
            P2: P2,
            W: W,
            n: n
        },
        correct_answers: {
            T2: math.round(T2, 3),
            m_dot: math.round(m_dot, 3),
            Q: math.round(Q_dot, 3)
        },
        nDigits: 3,
        sigfigs: 3
    };

    console.log(data);
    return data;
};

generate();

module.exports = {
    generate
};
