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
	
    w = math.randomInt(2,8)

l1 = math.randomInt(5,20)
l2 = math.round(l1*1.3*100)/100
l3 = math.round(l1*.6*100)/100

theta = math.randomInt(45,55);
phi = math.randomInt(30,43);



radt  =theta*Math.PI/180;
radp  =phi*Math.PI/180;









wcd = (w*l1)/(((l2*math.cos(radt)*l3*math.sin(radp))/(l2*math.sin(radt)))+l3*math.cos(radp))




data = {
    params: {
theta:theta,
phi:phi,
w:w,
l1:l1,
l2:l2,
l3:l3,


       
      
},

    correct_answers: { 
       
    wcd:wcd

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
