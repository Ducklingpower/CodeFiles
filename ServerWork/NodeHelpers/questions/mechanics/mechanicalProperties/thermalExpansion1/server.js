const math = require('mathjs');
// const mathhelper = require('../../helpers/mathhelper.js');
//const mathhelper = require('../../mathhelper.js');
const generate = () => {

    unitSystems = ['si', "uscs"];
    masslabels = ["mass", "weight"];

    units = { 
        "si": { 
            "masslabel": "mass",
            "mass": "kg",
            "dist": "m",
            "force": "kN",
            "modulus": "GPa",
            "temp": "C",
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "ft",
            "force": "lbf",
            "modulus": "psi",
            "temp": "F",
        }
    }
    
    unitSel = math.randomInt(0,2);
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSmallDist = units[unitSystems[unitSel]].distSmall;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsModulus = units[unitSystems[unitSel]].modulus;
    unitForce = units[unitSystems[unitSel]].force; 
    unitsTemp = units[unitSystems[unitSel]].temp;


// assign values to parameters 
if (unitSel === 0) {
    alpha = 12; 
    initialLength = (math.randomInt(2,4));
    initialTemp = (math.randomInt(15,30));
    finalTemp = (math.randomInt(110,125));
} 

else {
    alpha = 7;
    initialLength = (math.randomInt(6,13));
    initialTemp = (math.randomInt(59,86)); 
    finalTemp = (math.randomInt(230,257));
}


//calculation

    deltaTemp = (finalTemp - initialTemp); 
    thermalStrain = ((alpha * 1e-6) * deltaTemp);
    deltaLength = (thermalStrain * initialLength); 
    finalLength = (initialLength + deltaLength);

data = {
    params: {
        initialLength:initialLength, 
        initialTemp:initialTemp,
        finalTemp:finalTemp,
        alpha:alpha, 
        
        unitsDist:unitsDist,
        unitsTemp:unitsTemp,
},

    correct_answers: { 
        thermalStrain:thermalStrain,
        finalLength:finalLength,
    


},
   nDigits: 2,
   sigfigs:2
}

console.log(data);
return data;
}
generate();
module.exports = {
    generate
}