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
 g = 9.81;
 m = math.randomInt(10,100);
 w = m*g
 L = math.randomInt(1,10);

 r = Math.sqrt((L/2)**2+(L/2)**2);
 I = (m/12*(L**2 + L**2))+(m*r**2);
 radt = (45*Math.PI)/(180);
 a = (w*r*Math.cos(radt))/(I);
 Ax = m*a*r*Math.cos(radt);
 Ay = w - m*a*r*Math.sin(radt);


data = {
    params: {
w:w,
L:L,
unitsForce:unitsForce,
unitsDist:unitsDist,
a:a,


       
      
},

    correct_answers: { 
Ax:Ax,
Ay:Ay,


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
