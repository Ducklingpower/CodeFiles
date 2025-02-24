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
            "force": "kN",
            "angSpeed": "rad/s",
            "angle": "degrees",
            "speed": "m/s",
            "acc": "m/s^2",
            "dist1": "mm",
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "in",
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
    unitsDist1 = units[unitSystems[unitSel]].dist1;


    l1 = math.randomInt(10,100)/10;
    l2 = math.round(1.7*l1*10)/10;
    theta = math.randomInt(40,55);
    phi = math.randomInt(25,35);
  w1 = math.randomInt(20,100);



    radt = theta*(Math.PI/180);
    radp = phi*(Math.PI/180);

    
w2 = (w1*l1*Math.cos(radp))/(l2*math.sin(radt));
v = w1*l1*( ( (Math.cos(radp)*Math.cos(radt))/(Math.sin(radt)) ) - Math.sin(radp) );



data = {
    params: {

l1:l1,
l2:l2,
phi:phi,
theta:theta,
w1:w1,
       
      
},

    correct_answers: { 
  v:v,
   w2:w2,


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
