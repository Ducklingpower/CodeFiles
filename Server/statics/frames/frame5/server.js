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



    l2 = math.randomInt(2,20);
    l1 = math.round(l2*.75*100)/100;
    l3 = math.round(l2/6*100)/100;
    r =  math.round(l3*.75*100)/100;
    weight = math.randomInt(200,1000);





    theta = Math.atan((l1/l2));
     
Br = (weight*(l2+l3+r)-(weight*r))/(math.sin(theta)*l2);

Bx = Br*math.cos(theta);
By = Br*math.sin(theta);

Cy = -weight+By;
Cx = -weight+Bx;






  
data = {
    params: {
       
       l1:l1,
       l2:l2,
       l3:l3,
      weight:weight,
      r:r,
      

       unitsForce:unitsForce,
       unitsDist:unitsDist,
     



       
},

    correct_answers: { 
  Cx:Cx,
  Bx:Bx,
  Cy:Cy,
  By:By,
  

  
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