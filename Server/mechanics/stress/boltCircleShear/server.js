//const { data } = require('cheerio/lib/api/attributes.js');
const math = require('mathjs');
//const mathhelper = require('../../mathhelper.js');
const props = require('./properties.js');
//const mathhelper = require('../../helpers/mathhelper.js');

const generate = () => {

    unitSystems = ['si', "uscs"];
    masslabels = ["mass", "weight"];
    
    units = { 
        "si": { 
            "masslabel": "mass",
            "mass": "kg",
            "speed": "m/s",
            "dim": "cm",
            "dist": "m",
            "force": "kN",
            "angle": "degrees",
            "work": "J",
            "springConst": "N/cm",
            "springLength": "cm",
            "modulusElasticity": "GPa",
            "stress": "MPa",
            "dLength": "mm",
            "dDiameter": "\\(  \\mu m \\) ",
            "diameter" : "mm",
            "energy": "J",
            "torque": "N-m",
            "power": "kW"
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "speed": "ft/s",
            "dim": "in",
            "dist": "ft",
            "force": "lb",
            "angle": "degrees",
            "work": "ft-lb",
            "springConst": "lb/in",
            "springLength": "in",
            "modulusElasticity": "Mpsi",
            "stress": "Kpsi",
            "dLength": "inch",
            "dDiameter": "\\(\mu inch\\) ",
            "diameter" : "inch",
            "energy": "ft-lb",
            "torque": "lb-ft",
            "power": "hp"
        }
    }
    
    unitSel = math.randomInt(0,2);
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsWork = units[unitSystems[unitSel]].work;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsSpringConst = units[unitSystems[unitSel]].springConst;
    unitsSpringLength = units[unitSystems[unitSel]].springLength;
    unitsModulusElasticity = units[unitSystems[unitSel]].modulusElasticity;
    unitsStress = units[unitSystems[unitSel]].stress;
    unitsDLength = units[unitSystems[unitSel]].dLength;
    unitsDDiameter = units[unitSystems[unitSel]].dDiameter;
    unitsDiameter = units[unitSystems[unitSel]].diameter;
    unitsTorque = units[unitSystems[unitSel]].torque;
    unitsPower = units[unitSystems[unitSel]].power;


convToMega = 1e-6;
convToGiga = 1e-9;
convToKilo = 1e-3;
convToCenti = 1e2;
convToMilli = 1e3;
convToMicro = 1e6;


materialProperties = props.materialProperties;
matKeys = Object.keys(materialProperties);
numMats = matKeys.length;
matIndex = math.randomInt(0,numMats);
materialName = matKeys[matIndex];
matprop = props.getMaterialProperties(materialName, unitSel);

E = matprop.E;
nud = matprop.nud;
G = matprop.G;
sultd = matprop.sult;
tultd = matprop.tult;
console.log(`materialName = ${materialName}, E = ${E}, nud = ${nud}, G = ${G} tult = ${tult}\n`);

rpm = 10*math.randomInt(10,120);
omega = rpm*2*math.pi/60;
power = 0.25*math.randomInt(4,20);



if (unitSel === 0){
    R = 5*math.randomInt(10,20); // shaft radius in mm
    D = 2*R;
    torque = power*1000/omega;
    F = torque/(R*1e-3);
    G = G/convToGiga;
    sult = sultd/convToMega;
    tult = tultd/convToMega;
} else {
    R = 0.25*math.randomInt(6,13);
    D = 2*R;
    torque = (power*550)/omega;
    F = torque/(R/12);
    G = G/convToMega;
    sult = sultd/convToKilo;
    tult = tultd/convToKilo;
}

fs = 1.25*math.randomInt(2,12);
tau = tult/fs;
nBolts = 4;
Fperbolt = F/nBolts;

d = math.sqrt(4*Fperbolt/(tau*math.pi));

console.log(`power = ${power}; torque = ${torque}; rpm = ${rpm}`);

console.log(`F = ${F}, tau = ${tau}, fs = ${fs}`);
if (unitSel === 0) {
    tau = tau*convToMega;
    d = d*convToMilli;

} else {
    tau = tau*convToKilo;
}

data = {
    params: { 
        power: power,
        rpm: rpm,
        D: D,
        fs: fs,
        nBolts: nBolts,
        E: E,
        nud: nud,
        sult: sultd,
        tult: tultd,
        materialName: materialName,
        masslabel: masslabel,
        unitsMass: unitsMass,
        unitsModulusElasticity: unitsModulusElasticity,
        unitsStress: unitsStress,
        unitsDLength: unitsDLength,
        unitsDDiameter: unitsDDiameter,
        unitsDiameter: unitsDiameter,
        unitsDist: unitsDist,
        unitsTorque: unitsTorque,
        unitsPower: unitsPower
    },
    correct_answers: {
       d: d 
    },
    nDigits: 2,
    sigfigs: 2
}

console.log(data);
return data;
}

generate();

module.exports = {
    generate
}