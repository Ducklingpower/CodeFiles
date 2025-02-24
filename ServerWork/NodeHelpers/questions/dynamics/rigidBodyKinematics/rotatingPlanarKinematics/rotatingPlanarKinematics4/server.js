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
            "angSpeed": "rad/s",
            "angle": "degrees",
            "speed": "m/s",
            "acc": "m/s^2",
            "dist1": "mm",
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "in",
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
    unitsDist1 = units[unitSystems[unitSel]].dist1;
	
 
r = math.randomInt(10,40)/10
w = math.randomInt(1,5)
theta =math.randomInt(25,40);





phi = 90-theta
radt = phi*Math.PI/180;
radtt = theta*Math.PI/180;

L = 2*r*Math.cos(radtt);
velocity = (w*L)/(Math.sin(radt));
accel = (2*w*w*L*Math.cos(radt))/(Math.sin(radt)*Math.sin(radt));









data = {
    params: {
r:r,
w:w,
theta:theta,



       
      
},

    correct_answers: { 
accel:accel,
velocity:velocity,


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
