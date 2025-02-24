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
	
 m = math.randomInt(700,900);
 r = math.randomInt(3,8)/10;
 mu =math.randomInt(10,20)/100;
 theta = math.randomInt(40,50);
 phi = Math.round(theta*0.7*10)/10;
g = 9.81;
w = g*m;


radt = theta*Math.PI/180
radp = phi*Math.PI/180

a = ((mu*r*w*Math.cos(radt))/(m*(r*Math.sin(radt-radp)+mu*r*Math.sin(radt))))  -  ((mu*w)/(m))  +  ((mu*r*w*mu*Math.sin(radt))/(m*(r*Math.sin(radt-radp)+mu*r*Math.sin(radt))))


data = {
    params: {

mu:mu,
m:m,
theta:theta,
phi:phi,
r:r,

       
      
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
