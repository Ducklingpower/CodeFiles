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

forceP =math.randomInt(10,50);
forceG =math.randomInt(10,50);
forceR =math.randomInt(10,50);

l1 = math.randomInt(5,20);
l2 = math.round(l1*1.3*100)/100;

momentx = l1*forceR+l1*forceP+l1*forceG-l1*forceP
momenty = -forceG*l2-forceG*l1;
momentz = forceP*l2-forceG*l1-forceR*l1;

data = {
    params: {
       forceG:forceG,
       forceR:forceR,
       forceP:forceP,
       l1:l1,
       l2:l2,
       unitsForce:unitsForce,
       unitsDist:unitsDist,
     



       
},

    correct_answers: { 
    momentx:momentx,
    momenty:momenty,
    momentz:momentz,

  
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