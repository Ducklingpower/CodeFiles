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
            "forcee":"N/m"
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

 //-----------------------math
weight = math.randomInt(100,500);
l1 = math.randomInt(1,10);
l2 = math.round(l1*2*100)/100;
l3 = math.round(l1*6*100)/100;


length = math.sqrt((l2+l2-l1)**2+l3**2+l2**2);
x = (l2+l2-l1)/(length);
y = (-l3)/(length);
z = (l2)/(length);

T = weight/z;
Mx = 0
My = weight*l2-(2*l2*T*z);
Mz = -((2*l2*T*y)+(T*x*l3));
Ax = -T*x;
Ay = T*y;
Az = weight-T*z;



 //----------------------


data = {
    params: {
   unitsDist:unitsDist,
   unitsForce:unitsForce,
weight:weight,
l1:l1,
l2:l2,
l3:l3
       
},

    correct_answers: { 
        Mx:Mx,
        My:My,
        Mz:Mz,
        Ax:Ax,
        Ay:Ay,
        Az:Az,
        T:T,
 
   

  
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