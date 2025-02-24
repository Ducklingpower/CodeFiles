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

    R = 2.077; // kJ/kg-K for Helium
    m = math.randomInt(1,3); // kg
    p1 = math.randomInt(75,150); // kPa
    T1 = math.randomInt(250,400); // K
    v1_v3 = math.randomInt(3,7);

    // State 1
    v1 = (R * T1) / p1; // m^3/kg

    // State 3
    v3 = v1 / v1_v3;
    T3 = T1; // Isothermal process
    p3 = (R * T3) / v3;

    // State 2
    p2 = p3;
    v2 = v1; // Constant volume process
    T2 = (p2 * v2) / R;

    // Work calculations
    W12 = 0; // Constant volume

    W23 = m * p2 * (v3 - v2); // Constant pressure

    W31 = m * R * T3 * Math.log(v1 / v3); // Isothermal

    // Heat calculations
    cv = 3.1189; // kJ/kg-K for Helium
    cp = 5.1954; // kJ/kg-K for Helium

    Q12 = m * cv * (T2 - T1);
    Q31 = W31; // For isothermal process, Q = W
    Q23 = m * cp * (T3 - T2);

    Q_total = Q12 + Q31; // Total heat added

    data = {
        params: {
            p1: p1,
            T1: T1,
            v1_v3: v1_v3,
            m:m,

        },
        correct_answers: {
            P1: math.round(p1,3),
            T1: math.round(T1,3),
            V1: math.round(v1,3),
            P2: math.round(p2,3),
            T2: math.round(T2,3),
            V2: math.round(v2,3),
            P3: math.round(p3,3),
            T3: math.round(T3,3),
            V3: math.round(v3,3),
            W12: math.round(W12,3),
            W23: math.round(W23,3),
            W31: math.round(W31,3),
            Q_total: math.round(Q_total,3),
            Q12:math.round(Q12,3),
            Q31:math.round(Q31,3),
            Q23:math.round(Q23,3),
        },
        nDigits: 2,
        sigfigs: 3
    };

    console.log(data);
    return data;
};

generate();

module.exports = {
    generate
};