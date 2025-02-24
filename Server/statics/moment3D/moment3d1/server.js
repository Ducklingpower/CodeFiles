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

 force = math.randomInt(5,50);
 l1= math.randomInt(5,20);
 l2= math.round(l1*.5 *100) /100;
 l3= math.round(l1*.7*100)/100;
 v1= math.round(l1*1.3*100)/100;
 v2= math.round(v1*1.3*100)/100;
 v3= math.round(l3*.7*100)/100;


// force = 5
// l1= 10
// l2= 5
// l3 = 7

// v1 = 13
// v2 = 15
// v3 = 5


  //R= [l2,l1,l3];

  //F= [v1-l1,v2-v2,v3-l3]
  Fx = force * ((v2-l2)/math.sqrt((v1-l1)**2+(v2-l2)**2+(v3-l3)**2));
  Fy = force * ((v1-l1)/math.sqrt((v1-l1)**2+(v2-l2)**2+(v3-l3)**2));
  Fz = force * ((v3-l3)/math.sqrt((v1-l1)**2+(v2-l2)**2+(v3-l3)**2));

 momenti= (l1*Fz-l3*Fy);
momentj = -(l2*Fz - l3*Fx);
 momentk = (l2*Fy-l1*Fx);

 
    
    


data = {
    params: {
       force:force,
       l1:l1,
       l2:l2,
       l3:l3,
       v1:v1,
       v2:v2,
       v3:v3,
       unitsForce:unitsForce,
       unitsDist:unitsDist,
       
},

    correct_answers: { 
    momenti:momenti,
    momentj:momentj,
    momentk:momentk,

  
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