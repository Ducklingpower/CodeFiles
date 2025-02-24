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
            "torque": "N-m"
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
            "torque": "lb-ft"
        }
    }
    
    //unitSel = 1; //SI
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

convToMega = 1e-6;
convToGiga = 1e-9;
convToKilo = 1e-3;
convToCenti = 1e2;
convToMilli = 1e3;
convToMicro = 1e6;
convToInch = 12;


materialProperties = props.materialProperties;
matKeys = Object.keys(materialProperties);
numMats = matKeys.length;
matIndex = math.randomInt(0,numMats);
materialName = matKeys[matIndex];
matprop = props.getMaterialProperties(materialName, unitSel);

Ed = matprop.E;
nud = matprop.nud;
Gd = matprop.G;
sultd = matprop.sult;
tultd = matprop.tult;
console.log(`materialName = ${materialName}, E = ${E}, nud = ${nud}, G = ${G} tult = ${tult}\n`);


if (unitSel === 0 ) {
    g = 9.81;
    L = math.randomInt(4,10);
    Ldis = L*15;
    H = math.randomInt(3,8);
    Hdis = H*15;
} else {
    g = 1;
    L = math.randomInt(40,100);
    Ldis = L;
    H = math.randomInt(30,80);
    Hdis = H;
}

phi= 5*math.randomInt(3,15);
phirad = phi*math.pi/180;

Ls = math.sqrt( L*L + H*H - 2*L*H*math.cos(phirad));
thetarad = math.pi/2-math.acos( (H*H + Ls*Ls -L*L)/(2*Ls*H));
theta = thetarad*180/math.pi;

console.log(`Ls = ${Ls} Theta = ${theta}`);

m = 10*math.randomInt(10,120);





T = (m/2)*g*math.sin(phirad)/(math.cos(phirad - thetarad));
Ox = (m/2)*g*math.sin(phirad)*math.cos(thetarad)/(math.cos(phirad - thetarad));
Oy = m*g - (m/2)*g*math.sin(thetarad)*math.sin(phirad)/(math.cos(phirad - thetarad));

let svgString = `<svg
xmlns="http://www.w3.org/2000/svg"
xmlns:xlink="http://www.w3.org/1999/xlink"
width = "400" height = "400">
<defs>
   <marker id="arrowhead" markerWidth="10" markerHeight="7" 
   refX="10" refY="3.5" orient="auto">
     <polygon points="0 0, 10 3.5, 0 7" style="fill: red"/>
   </marker>
 </defs> \n`;

 boomVec = math.round([Ldis*math.sin(phirad), -Ldis*math.cos(phirad)]);
 boomVecText = math.round(math.multiply(1.1,boomVec));
 OA = [0, -Hdis];
svgString += `<g transform = 'matrix(1 0 0 1 100 200)'> \n`;
svgString += `<line x1 = "0" y1 = "${(0.5)*Hdis}" x2 = "0" y2 = "${-1.5*Hdis}" style = "stroke: brown;
stroke-width: 5;
stroke-linecap: round"/> \n`;
svgString += `<line x1 = "0" y1="0" x2="${boomVec[0]}" y2="${boomVec[1]}" style = "stroke: green;
stroke-width: 2.5;
stroke-linecap: round" /> \n`;
svgString += `<line x1 = "${OA[0]}" y1="${OA[1]}" x2="${boomVec[0]}" y2="${boomVec[1]}" style = "stroke: blue;
stroke-width: 1;
stroke-linecap: round" /> \n`;
svgString += `<circle cx="0" cy="0" r="4" style="fill: lightgrey" />`;
svgString += `<text x="-15" y="0" style="font: 11px sans-serif" > O </text> `;
svgString += `<text x="-15" y="${OA[1]}" style="font: 11px sans-serif" > A </text> `;
svgString += `<text x="${boomVecText[0]}" y="${boomVecText[1]}" style="font: 11px sans-serif" > B </text> `;
svgString += `</g> \n`;
svgString += `</svg> \n`;

//console.log('SVGSTRING is ', svgString);
fs = 0.25*math.randomInt(8,24);
if (unitSel === 0 ) {
    sult = sultd/convToMega;
    tult = tultd/convToMega;
    E = Ed/convToGiga;
}
else {
    sult = sultd/convToKilo;
    tult = tultd/convToKilo;
    E = Ed/convToMega;
}

sig = sult/fs;
d = math.sqrt(T*4/(math.pi*sig));
eps = sig/E;
dLs = eps*Ls;
epsl = nud*eps;
dd = epsl*d;


if (unitSel === 0) {
    d = d*convToMilli;
    dLs = dLs*convToMilli;
    dd = dd*convToMicro;
    T = T*convToKilo;
    Ox = Ox*convToKilo;
    Oy = Oy*convToKilo;
} else {
    dLs = dLs*convToInch;
    dd = dd*convToMicro;
}


data = {
    params: {
        masslabel:masslabel,
        unitsMass: unitsMass,
        unitsDist: unitsDist,
        unitsForce: unitsForce,
        mass: m,
        L : L,
        H : H,
        phi: phi,
        nud: nud,
        E: Ed,
        sult: sultd,
        tult: tultd,
        fs:fs,
        materialName: materialName,
        unitsDiameter: unitsDiameter,
        masslabel: masslabel,
        unitsModulusElasticity: unitsModulusElasticity,
        unitsStress: unitsStress,
        unitsDLength: unitsDLength,
        unitsDDiameter: unitsDDiameter,
        unitsDiameter: unitsDiameter,
        svgString: svgString
    },
    correct_answers: {
        tension: T,
        d:d,
        dLs: dLs,
        dd: dd,
        Ox: Ox,
        Oy: Oy
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