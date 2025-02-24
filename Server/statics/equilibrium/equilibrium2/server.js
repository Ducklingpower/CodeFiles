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

   weight = math.randomInt(50,200);
   l3 = math.randomInt(5,20);
   l1 = math.round(l3*math.randomInt(125,135)/100);
   l2 = math.round(l3*math.randomInt(200,220)/100);

//vec Tab
//(0,-l3,l2)
lengthb = math.sqrt(l3**2+l2**2);
xb=0
yb = -l3/lengthb;
zb = l2/lengthb;

// vec Tad
//(-l1/2,l1,0)'
lengthd = math.sqrt((l1/2)**2+l1**2);
xd = (-l1/2)/lengthd;
yd = l1/lengthd;
zd=0;

//vec Tac
//(l1/2,l1,-)
lengthc = lengthd;
xc = (l1/2)/lengthc;
yc = l1/lengthc;
zc = 0;

TAB = weight/zb;
TAD = -(TAB*yb)/(yd+yc);
TAC=TAD;






data = {
    params: {
       
       l1:l1,
       l2:l2,
       l3:l3,
     weight:weight,
       unitsForce:unitsForce,
       unitsDist:unitsDist,
     



       
},

    correct_answers: { 
        TAB:TAB,
        TAD:TAD,
        TAC:TAC,
  
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