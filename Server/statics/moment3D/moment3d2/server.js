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

 force = math.randomInt(10,100);
 l1 = math.randomInt(5,50);
 l2 = math.round(l1*.2*100)/100;
 l3 = math.round(l1*.8*100)/100;



 Fx = force* (l2/Math.sqrt(l1**2+l2**2+l3**2));
 Fy = force* (-l1/Math.sqrt(l1**2+l2**2+l3**2));
 Fz = force* (-l3/Math.sqrt(l1**2+l2**2+l3**2));

 momenti = (l3*Fy);
 momentj = -((Fz*(l2+l1))+Fx*l3);
 momentk = Fy*(l1+l2);




 
    
    


data = {
    params: {
       force:force,
       l1:l1,
       l2:l2,
       l3:l3,
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