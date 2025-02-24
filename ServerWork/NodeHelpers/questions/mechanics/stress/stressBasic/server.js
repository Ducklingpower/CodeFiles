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
            "forcee":"N/m"
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "feet",
            "force": "lb-force",
            "angSpeed": "rpm",
            "angle": "degrees",
            "speed": "feet/s",
            "acc": "ft/s^2",
            "forcee":"lb/ft"
        }
    }
    
    unitSel = math.randomInt(0,2);
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngSpeed = units[unitSystems[unitSel]].angSpeed;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsAcc = units[unitSystems[unitSel]].acc;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsForcee=units[unitSystems[unitSel]].forcee

 
//assign value to parameters

  if (unitSel === 0) {
    diameter = (math.randomInt(1,3));
    forceP = (math.randomInt(10000,30000));
  }  
  else {
    diameter = (math.randomInt(1,9));
    forceP = (math.randomInt(2200,4400))
  }
	




    
//calculate stress 
sigma = (4 * forceP) / ((3.14) * (diameter)^2)
    

data = {
    params: {
         diameter:diameter,
         forceP:forceP,
        
        
        unitsForce:unitsForce,
        unitsDist:unitsDist,
        
},

    correct_answers: { 
    sigma:sigma
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