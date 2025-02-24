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
            "angSpeed": "rad/s",
            "angle": "degrees",
            "speed": "m/s",
            "acc": "m/s^2",
            "forcee":"N/m",
            "mod_elasticity": "pa"
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "feet",
            "force": "lb",
            "angSpeed": "rpm",
            "angle": "degrees",
            "speed": "feet/s",
            "acc": "ft/s^2",
            "forcee":"lb/ft",
            "mod_elasticity": "psi"
        }
    }
    
    unitSel = math.randomInt(0,2);
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsMod = units[unitSystems[unitSel]].mod_elasticity;
  

    // Determinest the values of units of elasticity either PA or Psi
    unitsElasticity = units[unitSystems[unitSel]].mod_elasticity

    // COLLECTION of modulus of elasticity of various metals
    const modulusOfElasticity= {
        steel:{
            pa:200e9,
            psi: 29e6
        },
        copper:{
            pa:117e9,
            psi:17e6
        }
    };

    // Select random metal 
    const metal_names = Object.keys(modulusOfElasticity)
    metal_id = math.floor(math.random()*metal_names.length)
    metal = metal_names[metal_id]

    // Determine modules of elesticity for metal
    metal_elasticity = modulusOfElasticity[metal][unitsElasticity]
    //console.log(metal_elasticity)

    // Check
    //console.log("The metal is ", metal, " The modulus of elasticity is," , metal_elasticity,unitsElasticity)
    
	diameter = math.round((math.random())*10)/10;//diameter of bars
    length = (math.randomInt(1,10)); //length of bar
    elongation = math.round((math.random())*10)/10; // length of elongation of rod 







    
// solve 
strain = (elongation/length);
sigma = (metal_elasticity*strain);
area = ((math.pi/4)*diameter);
force = (sigma*area); 
    
data = {
    params: {
         diameter:diameter,
         length:length,
         elongation:elongation,
         metal_elasticity:metal_elasticity,
        
        
        unitsForce:unitsForce,
        unitsDist:unitsDist,
        unitsMod:unitsMod,
        
},

    correct_answers: { 
    force:force
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