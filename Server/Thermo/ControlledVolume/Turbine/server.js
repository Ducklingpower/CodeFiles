const math = require('mathjs');

const generate = () => {

    // Unit System and Variables Setup
    const unitSystems = ['si', 'uscs'];
    const units = {
        "si": {
            "energy": "kJ",
            "power": "kW",
            "massFlow": "kg/h",
            "velocity": "m/s",
        }
    };

    unitSel = 0; 
    energyUnit = units[unitSystems[unitSel]].energy;
    powerUnit = units[unitSystems[unitSel]].power;
    massFlowUnit = units[unitSystems[unitSel]].massFlow;
    velocityUnit = units[unitSystems[unitSel]].velocity;

    m_dot = math.randomInt(5000, 6000); //  (kg/h)
    Q_out = math.randomInt(900, 1100);  // (kW)
    v1 = math.randomInt(10, 20);         //  (m/s)
    v2 = math.randomInt(45, 55);        // E(m/s)
    x = math.randomInt(10,100)/100;                         




    h1 = 3177.2; // (kJ/kg)
    h2f = 191.83; //  (kJ/kg)
    h2fg = 2392.8; // (kJ/kg)

    h2 = h2f + x * h2fg; 

  
    delta_h = h2 - h1; 
    delta_ke = ((v2 ** 2 - v1 ** 2) / 2) * (1 / 1000); 

    // Calculate heat transfer rate
    Q_dot = Q_out + (m_dot / 3600) * (delta_h + delta_ke); 

     data = {
        params: {
            m_dot: m_dot,
            Q_out: Q_out,
            v1: v1,
            v2: v2,
            x: x,
        },
        correct_answers: {
            heatTransfer: math.round(Q_dot, 3),
        },
       
        sigfigs: 3
    };

    console.log(data);
    return data;
};

generate();
module.exports = {
    generate
};
