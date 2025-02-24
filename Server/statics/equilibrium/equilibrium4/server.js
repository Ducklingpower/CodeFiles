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
            "force": "N",
            "angSpeed": "rad/s",
            "angle": "degrees",
            "speed": "m/s",
            "acc": "m/s^2",
            "forcee":"N/m",

        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "feet",
            "force": "lb",
            "angSpeed": "rpm",
            "angle": "degrees",
            "speed": "feet/s",
            "acc": "ft/s^2",
            "forcee":"lb/ft"
        }
    }
    
    unitSel = math.randomInt(0,2);
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngSpeed = units[unitSystems[unitSel]].angSpeed;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsAcc = units[unitSystems[unitSel]].acc;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsForcee=units[unitSystems[unitSel]].forcee

   

k = math.randomInt(100,500);
weight = math.randomInt(100,500);

l1 = math.randomInt(5,25);
l2 = math.round(l1*(4/6)*10)/10;
l3 = l1*2




//vec oc
//(l1,l2,l3)
length = math.sqrt(l1**2+l2**2+l3**2);
xc = l1/length;
yc = l2/length;
zc = l3/length;

TC = weight/zc;
TB = TC*xc;
TA = TC*yc;

Xa = TA/k;
Xb = TB/k;




data = {
    params: {
       weight:weight,
       l1:l1,
       l2:l2,
       l3:l3,
       k:k,
       unitsForce:unitsForce,
       unitsDist:unitsDist,
       unitsForcee:unitsForcee,
     



       
},

    correct_answers: { 
       
        Xa:Xa,
        Xb:Xb,
  
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