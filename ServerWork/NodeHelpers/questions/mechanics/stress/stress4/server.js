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
            "distt":"m",
            "force": "N",
            "angSpeed": "rad/s",
            "angle": "degrees",
            "speed": "m/s",
            "acc": "m/s^2"
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "ft",
            "force": "lb",
            "angSpeed": "rpm",
            "angle": "degrees",
            "speed": "feet/s",
            "acc": "ft/s^2"
        }
    }
    
    unitSel = 0;
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngSpeed = units[unitSystems[unitSel]].angSpeed;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsAcc = units[unitSystems[unitSel]].acc;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsDistt = units[unitSystems[unitSel]].distt;

 

/////////////////////////////////

force = math.randomInt(5500,6500);
l1 = math.randomInt(75,150);
l2 = l1*1.25;
thickness = math.randomInt(125,200);
//fix this 


stressa= (force)/(2*l1*thickness)*1000;
stressb= (force)/(2*l2*thickness)*1000;










    

data = {
    params: {
   l1:l1,
   l2:l2,
   thickness:thickness,
   force:force,
        unitsForce:unitsForce,
        unitsDist:unitsDist,
        unitsDistt:unitsDistt
},

    correct_answers: { 

      stressa:stressa,
      stressb:stressb,

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