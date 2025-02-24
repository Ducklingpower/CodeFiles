const math = require('mathjs');

const generate = () => {
    const unitSystems = ['si', 'uscs'];
    const props = {
        specificHeats: {
            lead: {
                si: { Cp: 130, meltingPoint: 327 }, // J/(kg °C), °C
                uscs: { Cp: 0.031, meltingPoint: 621.5 } // BTU/(lb °F), °F
            }
        }
    };

    const unitSel = math.randomInt(0, 2); // Randomly select SI or USCS
    const selectedSystem = unitSystems[unitSel];

    const specificHeatData = props.specificHeats.lead[selectedSystem];
    const Cp = specificHeatData.Cp;
    const Tm = specificHeatData.meltingPoint;

    let unitsTemperature, unitsCp, unitsHeat, unitsMass;
    if (selectedSystem === 'si') {
        unitsTemperature = "°C";
        unitsCp = "J/(kg °C)";
        unitsHeat = "J";
        unitsMass = "kg";
    } else {
        unitsTemperature = "°F";
        unitsCp = "BTU/(lb °F)";
        unitsHeat = "BTU";
        unitsMass = "lb";
    }

    const Ti = selectedSystem === 'si' ? math.randomInt(20, Tm - 10) : math.randomInt(50, Tm - 10);
    const Q = selectedSystem === 'si' ? math.randomInt(100, 500) * 1000 : math.randomInt(200, 500);

    const mass = selectedSystem === 'si' ? Q / (Cp * (Tm - Ti)) : Q / (Cp * (Tm - Ti));

    const data = {
        params: {
            Ti: Ti,
            Tm: Tm,
            Q: Q,
            Cp: Cp,
            unitsTemperature: unitsTemperature,
            unitsCp: unitsCp,
            unitsHeat: unitsHeat,
            unitsMass: unitsMass
        },
        correct_answers: {
            mass: mass
        },
        nDigits: 3,
        sigfigs: 3
    };

    return data;
};

console.log(generate());

module.exports = {
    generate
};