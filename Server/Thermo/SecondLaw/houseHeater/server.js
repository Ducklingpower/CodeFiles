const math = require('mathjs');

const generate = () => {
    
  
    qh = math.randomInt(500, 900) * 1000; //kJ/day
    t_in = math.randomInt(20, 25); //  °C
    t_out = math.randomInt(5, 15); // °C

    // -----------------checking 
    //qh = 5*10**5;
    //t_in = 22;
    //t_out = 10;
   
    T_H = t_in + 273.15; 
    T_C = t_out + 273.15; 

   
    w_cycle = qh * (1 - T_C / T_H);

  
    data = {
        params: {
            qh: qh / 1000, 
            t_in: t_in,
            t_out: t_out,
        },
        correct_answers: {
            Work: math.round(w_cycle, 2),
        },
        nDigits: 2,
        sigfigs: 3,
    };

    console.log(data);
    return data;
};

generate();

module.exports = {
    generate
};