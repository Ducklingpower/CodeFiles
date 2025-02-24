const math = require('mathjs');

const generate = () => {

    mw = math.randomInt(80, 120)/10;
    cw = 4.2; 
    Twi = math.randomInt(100, 310); 
    mm = math.randomInt(2, 10)/10; 
    cm = 0.42; 
    Tmi = math.randomInt(1100, 1800); 
//practice values
    //mw = 9 
   // cw = 4.2; 
    //Twi = 300; 
   // mm = 0.3;
    //cm = 0.42; 
    //  Tmi = 1200; 
    Tf = ((mw * cw * Twi) + (mm * cm * Tmi)) / ((mw * cw) + (mm * cm));
    deltaS_water = mw * cw * math.log(Tf / Twi);
    deltaS_metal = mm * cm * math.log(Tf / Tmi);
    sigma = deltaS_water + deltaS_metal;

    // Data object to return
    const data = {
        params: {
            mass_water: mw,
            cw: cw,
            initial_temp_water: Twi,
            mass: mm,
            cm: cm,
            initial_temp_bar: Tmi
        },
        correct_answers: {
            final_temperature: math.round(Tf, 3),
            entropy_production: math.round(sigma, 3)
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
