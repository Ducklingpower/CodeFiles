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
            "force": "N",
            "modulus": "Pa",
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "feet",
            "force": "lb",
            "modulus": "psi", 
        }
    }
    
    unitSel = math.randomInt(0,2);
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsForce = units[unitSystems[unitSel]].force;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsModulus = units[unitSystems[unitSel]].modulus;



 
//assign numerical values to variables 
    forceP = (math.randomInt(5000,10000)); // vertical load P 
    massSteel = (math.randomInt(500,900)); // mass of steel bar
    massCopper = (math.randomInt(100,500)); // mass of copper bar
    areaSteel = (math.randomInt(10,15)); // cross sectional area of steel bar
    areaCopper = (math.randomInt(5,10)); // cross sectional area of copper bar 

// assign values for modulus of Elasticity 
if (unitSel === 0) {
    modulusElasticitySteel = 2.1; 
    modulusElasticityCopper = 1.2;
    n = 11; 
    g = 9.81;

   
} else {
    modulusElasticitySteel = 30;
    modulusElasticityCopper = 18;
    n = 6;
    g = 32.2 

    
}

    
//calculate for the sum of forces 

forceCopper = (g*massCopper) + forceP; 
forceSteel = (g*massSteel) + forceCopper;

//calculate max stress 

sigmaCopper = forceCopper/areaCopper; 
sigmaSteel = forceSteel/areaSteel; 





data = {
    params: {
        forceP:forceP,
        massSteel:massSteel,
        massCopper:massCopper,
        areaSteel:areaSteel,
        areaCopper:areaCopper,
        modulusElasticitySteel:modulusElasticitySteel,
        modulusElasticityCopper:modulusElasticityCopper,
        n:n, 
        
        unitsForce:unitsForce,
        unitsDist:unitsDist,
        unitsMass:unitsMass,
        unitsModulus:unitsModulus, 
        
        
},

    correct_answers: { 
    sigmaCopper:sigmaCopper,
    sigmaSteel:sigmaSteel,
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