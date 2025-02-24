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
	
 
theta = math.randomInt(50,70);

v = math.randomInt(2,8);
acc  =math.randomInt(1,6);
w = math.randomInt(1,3);
a = math.randomInt(1,3);
l = math.randomInt(1,10)/10;




radt = theta*Math.PI/180;
vx = v*Math.cos(radt)+l*Math.sin(radt)*w;
vy = l*w*Math.cos(radt)-v*Math.sin(radt);
velocity  = math.sqrt(vx**2+vy**2);

ax = l*a*Math.sin(radt)-(w**2)*l*Math.cos(radt)+2*w*v*Math.sin(radt)+acc*math.cos(radt);
ay = l*a*Math.cos(radt)+w**2*l*Math.sin(radt)+2*w*v*Math.cos(radt)-acc*Math.sin(radt);
accel = Math.sqrt(ax**2+ay**2);


data = {
    params: {

theta:theta,
l:l,
v:v,
a:a,
acc:acc,
w:w,


       
      
},

    correct_answers: { 
velocity:velocity,
accel:accel,

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
