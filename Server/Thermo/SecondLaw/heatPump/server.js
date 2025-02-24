const math = require('mathjs');

const generate = () => {

    Q_H = math.randomInt(450000, 550000);
    T_in_Celsius = math.randomInt(20, 40);
    T_out_Celsius = math.randomInt(1, 15); 

    T_in_Celsius = 22
    T_out_Celsius = 10
    Q_H = 5*10**5

  
    T_in = T_in_Celsius + 273.15;
    T_out = T_out_Celsius + 273.15;

  
    W_cycle = Q_H * (1 - T_out / T_in);

    data = {
        params: {
            energy: Q_H,
            temp_in: T_in_Celsius,
            temp_out: T_out_Celsius
        },
        correct_answers: {
            work_input: math.round(W_cycle, 3) 
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
