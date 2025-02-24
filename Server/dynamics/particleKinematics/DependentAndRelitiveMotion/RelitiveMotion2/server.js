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
            "dist": "ft",
            "force": "lb",
            "angSpeed": "rpm",
            "angle": "degrees",
            "speed": "feet/s",
            "acc": "ft/s^2"
        }
    }
    
   



    unitSel = math.randomInt(0,2)

    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngSpeed = units[unitSystems[unitSel]].angSpeed;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsAcc = units[unitSystems[unitSel]].acc;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsDist1 = units[unitSystems[unitSel]].dist1;
	

    va = math.randomInt(20,30);
    aa = math.randomInt(8,10);

    vb = math.randomInt(8,19);
    ab = math.randomInt(5,7);
 
    r = math.randomInt(80,100);
    theta = math.randomInt(20,35);
    phi = 90-theta;
    rad = theta*Math.PI/180
    radp = phi*Math.PI/180


vx = -(vb*Math.cos(rad));
vy = -(va+vb*Math.sin(rad));
ax = ab*Math.cos(rad)-(vb**2*Math.cos(radp))/(r);
ay = aa+ab*Math.sin(rad)+(vb**2*Math.sin(radp))/(r);


data = {
    params: {

r:r,
theta:theta,
va:va,
aa:aa,
vb:vb,
ab:ab,
unitsSpeed:unitsSpeed,
unitsAcc:unitsAcc,
unitsDist:unitsDist
},

    correct_answers: { 
     
    vx:vx,
    vy:vy,
    ax:ax,
    ay:ay,

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
