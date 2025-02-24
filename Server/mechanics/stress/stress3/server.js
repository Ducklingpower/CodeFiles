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
            "dist": "mm",
            "force": "N",
            "angSpeed": "rad/s",
            "angle": "degrees",
            "speed": "m/s",
            "acc": "m/s^2"
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "ft",
            "force": "lb",
            "angSpeed": "rpm",
            "angle": "degrees",
            "speed": "feet/s",
            "acc": "ft/s^2"
        }
    }
    
    unitSel = 0;
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngSpeed = units[unitSystems[unitSel]].angSpeed;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsAcc = units[unitSystems[unitSel]].acc;
    masslabel = units[unitSystems[unitSel]].masslabel;
 
	weight = math.randomInt(650,900);
    d1 = math.randomInt(7,12);
    d2= math.randomInt(9,15);
theta1 = math.randomInt(50,70);
theta2 = math.randomInt(30,40);
rad1 = theta1*Math.PI/180;
rad2 = theta2*Math.PI/180;
/////////////////////////////////


r1 = (d1)/2
r2 = (d2)/2



T2 = (weight)/((math.cos(rad2)*math.sin(rad1))/(math.cos(rad1))+math.sin(rad2));
T1 = (T2*math.cos(rad2))/(math.cos(rad1));
stress1 = (T1)/(Math.PI*r1**2);
stress2 = (T2)/(Math.PI*r2**2);





    

data = {
    params: {
       theta1:theta1,
       theta2:theta2,
       weight:weight,
        d1:d1,
        d2:d2,

        unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 

      stress1:stress1,
      stress2:stress2,

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