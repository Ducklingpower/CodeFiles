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

  fg = math.randomInt(400,700);
  fr = math.randomInt(400,700);
  l2 = math.randomInt(3,15);
  l1 = math.round(l2*(2/3)*10)/10;




  Bx = (2*l1*fg + (l2+(l2/2))*fr)/(l2);
  Ax = (fr-Bx);
  Ay = fg;
  By = 0;

  Bx = math.abs(Bx);
  Ax = math.abs(Ax);

  Dx = -fr*2;
  Ex = -Dx-Bx;
  Ex = math.abs(Ex)
  Ey = fg
pinE = math.sqrt(Ex**2+Ey**2);

  


data = {
    params: {
       
       l1:l1,
       l2:l2,
       fg:fg,
       fr:fr,
       unitsForce:unitsForce,
       unitsDist:unitsDist,
     



       
},

    correct_answers: { 
  Ax:Ax,
  Bx:Bx,
  Ay:Ay,
  By:By,
  pinE:pinE,

  
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