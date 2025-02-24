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

 w = math.randomInt(100,500);
L = math.randomInt(1,10);

 
 
 length2 =  math.sqrt((2*L)*(2*L) + (2*L)*(2*L)+ L*L);

 x1 = -2*L/length2;
 y1 = -2*L/length2;
 z1 = L/length2;

 x2 = L/length2;
 y2 = -2*L/length2;
 z2 = 2*L/length2;

 T1 = -(w*L)/(2*L*z1+(2*L*x1/x2));
 T2 = (-T1*x1/x2);

 Ax = -T1*x1-T2*x2;
 Ay = -T1*y1-T2*y2;
 Az = -T1*z1-T2*z2+w;

    
    


data = {
    params: {
    w:w,
    L:L,
    unitsForce:unitsForce,
    unitsDist:unitsDist,
       
},

    correct_answers: { 
   Ax:Ax,
   Ay:Ay,
   Az:Az,
   T1:T1,
   T2:T2,
   

  
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