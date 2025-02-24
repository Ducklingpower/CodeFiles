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
	
va = math.randomInt(15,30);
vb = math.randomInt(10,35);

r1 = math.randomInt(60,75);
r2 = math.randomInt(60,75);
   
theta = math.randomInt(15,20);
phi = math.randomInt(25,35);

radt = theta*Math.PI/180
radp = phi*Math.PI/180

vx = -(va*Math.cos(radp)+vb*Math.cos(radt))
vy = -(va*Math.sin(radp)+vb*Math.sin(radt))

ax = -((va**2*Math.sin(radp))/(r1)+(vb**2*Math.sin(radt))/(r2))
ay = (va**2*Math.cos(radp))/(r1)+(vb**2*Math.cos(radt))/(r2)



data = {
    params: {
va:va,
vb:vb,
r1:r1,
r2:r2,
theta:theta,
phi:phi,

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