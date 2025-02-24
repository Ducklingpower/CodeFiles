//const { data } = require('cheerio/lib/api/attributes.js');
const math = require('mathjs');
//const mathhelper = require('../../mathhelper.js');
const mathhelper = require('../../helpers/mathhelper.js');

const generate = () => {

    unitSystems = ['si', "uscs"];
    masslabels = ["mass", "weight"];
    
    units = { 
        "si": { 
            "masslabel": "mass",
            "mass": "kg",
            "speed": "m/s",
            "dist": "m",
            "force": "N",
            "angle": "degrees",
            "work": "J",
            "springConst": "N/cm",
            "springLength": "cm",
            "modulusElasticity": "GPa",
            "stress": "MPa",
            "dLength": "mm",
            "dDiameter": "\\(  \\mu m \\) ",
            "diameter" : "mm"
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "speed": "ft/s",
            "dist": "ft",
            "force": "lb",
            "angle": "degrees",
            "work": "ft-lb",
            "springConst": "lb/in",
            "springLength": "in",
            "modulusElasticity": "Mpsi",
            "stress": "Kpsi",
            "dLength": "inch",
            "dDiameter": "\\( \\mu \\,inch\\) ",
            "diameter" : "inch"
        }
    }
    
    unitSel = 1; //SI
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

md = 10*math.randomInt(4,16);
Ld = 0.5*math.randomInt(2,12);
dd = 0.0625*math.randomInt(4,12);
Ed = math.randomInt(8,32);
nud  = math.round(100*math.random(0.25, 0.35))/100;
fs = math.random(15,35)/10;


convToMega = 1e-6;
convToGiga = 1e-9;
convToKilo = 1e-3;
convToMilli = 1e3;
convToMicro = 1e6;

d = dd;
g = 1;
E = Ed/convToMega;
m = md;
L = Ld;


W = m*g;
A = math.pi/4*d*d;
sigma = W/A;
eps = sigma/E;
epslat = nud*eps;

dL = eps*L*12;
deltaD = epslat*d;
smaxd = math.round((sigma*fs))/1000;
factorSafety = smaxd/(sigma*convToKilo);

console.log(`fs = ${fs} and Ed = ${Ed} and E = ${E}`);

data = {
    params: { 
        mass: md,
        Ld: Ld,
        dd: dd,
        Ed: Ed,
        nud: nud,
        smaxd: smaxd,
        masslabel: masslabel,
        unitsMass: unitsMass,
        unitsModulusElasticity: unitsModulusElasticity,
        unitsStress: unitsStress,
        unitsDLength: unitsDLength,
        unitsDDiameter: unitsDDiameter,
        unitsDiameter: unitsDiameter,
        unitsDist: unitsDist
    },
    correct_answers: {
        sigma: sigma*convToKilo,
        eps: eps,
        dL: dL,
        factorSafety: factorSafety,
        deltaD: deltaD*convToMicro
    },
    nDigits: 2,
    sigfigs: 2
}

console.log(data);
return data;
}

//generate();

module.exports = {
    generate
}