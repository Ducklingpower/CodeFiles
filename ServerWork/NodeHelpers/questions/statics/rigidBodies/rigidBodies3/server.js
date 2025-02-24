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
    fb = math.randomInt(100,500);

    l1 = math.randomInt(1,10);
    l2 = math.round(l1*2/3*100)/100;



    
    Cy = fg;
    Cz = (fp*l1-fb*l2)/(l1+l1);
    Cx = 0;

    Bz = (fp*(l1+l1+l1)-Cz*(l1+l1+l1)-fg*l2+fb*l1)/(l1+l1);
    Bx = (fr*l1+fg*l1-Cy*(l1+l1))/(l1+l1);
    By = 0;


    Ax = fr-Bx;
    Az = fb+fp-Cz-Bz;
    Ay = 0;




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
   fb:fb,
       
},

    correct_answers: { 
        Ax:Ax,
        Ay:Ay,
        Az:Az,
        Bx:Bx,
        By:By,
        Bz:Bz,
        Cx:Cx,
        Cy:Cy,
        Cz:Cz,
 
   

  
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