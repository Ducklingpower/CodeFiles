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
    fg = math.randomInt(100,500);
    fr = math.randomInt(100,500);
    fp = math.randomInt(100,500);
    l1 = math.randomInt(1,10);
    l2 = l1*.75;
    l3 = l1*.5;


    Ax = fp;
    Ay = -fr;
    Az = fg;
    Mx = (l3+l2)*fr + l1*fg;
    My = l2*fp + l2*fg;
    Mz = 0


 //----------------------


data = {
    params: {
   unitsDist:unitsDist,
   unitsForce:unitsForce,
   fg:fg,
   fp:fp,
   fr:fr,
   l1:l1,
   l2:l2,
   l3:l3,
       
},

    correct_answers: { 
        Ax:Ax,
        Ay:Ay,
        Az:Az,
        Mx:Mx,
        My:My,
        Mz:Mz,
 
   

  
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