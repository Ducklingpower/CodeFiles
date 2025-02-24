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

 forceG = math.randomInt(100,900);
 forceR = forceG*0.5
 l1 = math.randomInt(5,10);
 l2 = math.round(l1*0.4*100)/100
 l3 = math.round(l1*0.7*100)/100



FRx= forceR*(l2/Math.sqrt(l2**2+l3**2+l1**2))
FRy= forceR*(-l3/Math.sqrt(l2**2+l3**2+l1**2))
FRz= forceR*(-l1/Math.sqrt(l2**2+l3**2+l1**2))

FGx= 0
FGy= forceG*(l3/Math.sqrt(l3**2+l1**2))
FGz= forceG*(-l1/Math.sqrt(l3**2+l1**2))








 momentiR = (-l1*FRy);
 momentjR = -(-l1*FRx);
 momentkR = (0);

 momentiG = (-l1*FGy);
 momentjG = -(-l1*FGx);
 momentkG = (0);

 momenti = momentiG+ momentiR
 momentj = momentjG+ momentjR
 momentk = momentkG+ momentkR





 
    
    


data = {
    params: {
       forceG:forceG,
       forceR:forceR,
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