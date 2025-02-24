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
            "force": "lb",
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


    
	
    constant=math.randomInt(300,800)/1000;
   
	length1= ((math.randomInt(3,6))/constant)-1;
	length1=math.round(length1*10)/10;
    forceF=constant*(length1**3);
    forceF=math.round(forceF*10)/10;

   
F=(constant*(length1)**4)/4;
Fxx=(4*length1)/5;
momentA=F*Fxx;

data = {
    params: {
         forceF: forceF,
         constant:constant,
        length1: length1,
      
        unitsForcee:unitsForcee,
        unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 
    momentA:momentA,
  
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