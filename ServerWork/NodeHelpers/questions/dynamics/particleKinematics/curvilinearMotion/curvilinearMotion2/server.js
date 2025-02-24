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
	

v = math.randomInt(5,30);
t = math.randomInt(5,20)/10
g= 9.81



alpha = -(g)/(2*v**2)
x = t*v;
r = Math.abs((1+(alpha*2*x)**2)**(3/2)/(alpha*2));
vy = -g*t;
velocity = Math.sqrt(v**2+vy**2)
accelorationC = (velocity**2)/(r)
accelorationT = Math.sqrt(g**2-(accelorationC)**2)








data = {
    params: {

       v:v,
       t:t,
        x:x,
        r:r,
      
},

    correct_answers: { 
       
accelorationC:accelorationC,
accelorationT:accelorationT

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
