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
	
    force = math.randomInt(6,11);//kN
    l = math.randomInt(600,900);//mm
    l2 = (math.randomInt(100,500)/100)+l;//mm
    radius = math.randomInt(50,95)/10;//mm
    
    f = force*1000;//N
    ll = l/1000;//m
    ll2=l2/1000;//m
    delta = ll2-ll;//m
    rr=radius/1000;//m
    a = Math.PI*rr**2;//m^2
    E = (f*ll)/(a*delta)*10**-9;


data = {
    params: {

    unitsDist1:unitsDist1,
       l:l,
       l2:l2,
       radius:radius,
       force:force,
       unitsForce:unitsForce,


      
},

    correct_answers: { 

E:E,



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
