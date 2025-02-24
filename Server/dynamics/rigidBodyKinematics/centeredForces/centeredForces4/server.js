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
	
mu = math.randomInt(15,25)/100;
m = math.randomInt(15,25);
f = math.randomInt(25,35);
r = math.randomInt(100,150)/1000;
k  = math.randomInt(85,95)/1000;
l = math.randomInt(250,350)/1000;




g = 9.81





radt = Math.atan(l/r);

a = ((r*mu*f*Math.cos(radt) + r*mu*m*g*Math.cos(radt))/(k**2*m*Math.sin(radt) - k**2*m*mu*Math.cos(radt)))-((f*r)/(k**2*m))

a = Math.abs(a);



data = {
    params: {

  mu:mu,
  m:m,
  r:r,
  k:k,
  f:f,
  l:l,


       
      
},

    correct_answers: { 
    

   a:a,

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
