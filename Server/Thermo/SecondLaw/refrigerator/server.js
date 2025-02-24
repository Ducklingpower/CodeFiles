const math = require('mathjs');

const generate = () => {
    // Variables from the problem statement
   T_L = math.randomInt(-10, 5); // Temperature of freezer compartment in degrees Celsius
   T_H = math.randomInt(20, 30); // Ambient temperature in degrees Celsius
   Q_L = math.randomInt(7000, 9001); // Heat transfer rate in kJ/h
   W_in = math.randomInt(3000, 3501); // Power input in kJ/h





    // Conversion of temperatures to Kelvin
   T_L_K = T_L + 273.15;
   T_H_K = T_H + 273.15;

    // Coefficient of Performance (Actual)
   COP_actual = Q_L / W_in;

    // Coefficient of Performance (Reversible)
   COP_reversible = T_L_K / (T_H_K - T_L_K);

    // Prepare data for the response
   data = {
        params: {
            T_L: T_L,
            T_H: T_H,
            Q_L: Q_L,
            W_in: W_in,
            T_L_K:T_L_K,
            T_H_K:T_H_K,
        },
        correct_answers: {
            cop_actual: math.round(COP_actual, 3),
            cop_reversible: math.round(COP_reversible, 3)
        },
        nDigits: 3,
        sigfigs: 3
    };

    console.log(data);
    return data;
}

generate();

module.exports = {
    generate
};