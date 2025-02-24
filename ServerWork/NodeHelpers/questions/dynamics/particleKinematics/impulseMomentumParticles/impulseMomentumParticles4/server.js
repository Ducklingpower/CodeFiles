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
mb = math.randomInt(1,5)/100;
m = math.randomInt(1,5);
vb = math.randomInt(350,800);
mu = math.randomInt(20,30)/100;
g = 9.81



v = (vb*mb)/(mb+m);
t = (v)/(mu * g);
s = (v**2)/(2*mu*g);



data = {
    params: {
mb:mb,
mu:mu,
vb:vb,
m:m,

       
      
},

    correct_answers: { 
v:v,
t:t,
s:s,
     
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