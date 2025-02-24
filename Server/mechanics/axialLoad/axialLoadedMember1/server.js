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
            "dist": "mm",
            "force": "kN",
            "modulus": "GPa",
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "in",
            "force": "lb",
            "modulus": "psi", 
        }
    }
    
    unitSel = math.randomInt(0,2);
    unitsDist = units[unitSystems[unitSel]].dist;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsModulus = units[unitSystems[unitSel]].modulus;
    unitsForce = units[unitSystems[unitSel]].force; 


// assign values for modulus of Elasticity 
if (unitSel === 0) {
    modulusElasticitySteel = 205; 
    n = 0; 
    area = (math.randomInt(5000,9000));
    length = (math.randomInt(400,800));
    delta = (math.random()).toFixed(2);

   
} else {
    modulusElasticitySteel = 30;
    n = 6;
    area = (math.randomInt(200,350));
    length = (math.randomInt(15,30));
    delta = (math.randomInt(1,30))/1000;
    
}

    
//calculation
if (unitSel ===0) {
    forceP = ((((modulusElasticitySteel * 1e11) * area * delta) / length)/1e11).toFixed(2);
    

} else {
    forceP = ((((modulusElasticitySteel * 1e6) * area * delta) / length)).toFixed(2);

}

 




data = {
    params: {
        area:area,
        length:length,
        modulusElasticitySteel:modulusElasticitySteel,
        n:n, 
        delta:delta,
        
        unitsDist:unitsDist,
        unitsModulus:unitsModulus, 
        unitsForce:unitsForce,
        
        
},

    correct_answers: { 
    forceP:forceP,

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