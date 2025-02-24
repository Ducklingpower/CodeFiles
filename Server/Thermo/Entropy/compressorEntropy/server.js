const math = require('mathjs');

const generate = () => {
    // Units
    const unitSystems = ['si', 'uscs'];
    const units = {
        si: {
            temperature: 'K',
            pressure: 'kPa',
            massFlow: 'kg/min',
            entropy: 'kJ/K',
        },
    };

    const unitSel = 0; 
    const unitsTemp = units[unitSystems[unitSel]].temperature;
    const unitsPressure = units[unitSystems[unitSel]].pressure;
    const unitsMassFlow = units[unitSystems[unitSel]].massFlow;
    const unitsEntropy = units[unitSystems[unitSel]].entropy;


    power = math.randomInt(7, 30); 
    massFlow = math.randomInt(2, 20); 
    p1 = math.randomInt(100, 200); 
    T1 = math.randomInt(100, 300); 
    p2 = math.randomInt(400, 700); 
    T2 = math.randomInt(400, 500); 
    T_surroundings = T1; 





 
    cp = 1.0047;
    R = 0.287;

    
massFlowRate = massFlow / 60;

    
   deltaS_air =  massFlowRate *cp *Math.log(T2 / T1) -massFlowRate *R *Math.log(p2 / p1);

    
   Q_dot = -power + massFlowRate * cp *(T2 - T1);

     deltaS_surroundings = math.abs(Q_dot / T_surroundings);

    entropy_production = - math.abs(deltaS_air) + math.abs(deltaS_surroundings);

  
    data = {
        params: {
            power: parseFloat(power.toFixed(2)),
            mass_flow: parseFloat(massFlow.toFixed(2)),
            p1: parseFloat(p1.toFixed(2)),
            T1: parseFloat(T1.toFixed(2)),
            p2: parseFloat(p2.toFixed(2)),
            T2: parseFloat(T2.toFixed(2)),
            T_surroundings: T_surroundings,
        },
        correct_answers: {
            deltaS_air: math.abs(parseFloat(deltaS_air.toFixed(4))),
            deltaS_surroundings: math.abs(parseFloat(deltaS_surroundings.toFixed(4))),
            entropy_production: math.abs(parseFloat(entropy_production.toFixed(4))),
        },
        units: {
            temperature: unitsTemp,
            pressure: unitsPressure,
            massFlow: unitsMassFlow,
            entropy: unitsEntropy,
        },
    };

    console.log(data);
    return data;
};

generate();

module.exports = {
    generate,
};
