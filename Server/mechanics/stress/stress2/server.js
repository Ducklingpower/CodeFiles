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
    
    unitSel = math.randomInt(0,2);
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngSpeed = units[unitSystems[unitSel]].angSpeed;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsAcc = units[unitSystems[unitSel]].acc;
    masslabel = units[unitSystems[unitSel]].masslabel;
 
	forced = math.randomInt(50,200);
    l1 = math.randomInt(3,10);

    l2 = math.round(10*(l1/3))/10;

   theta = math.randomInt(27,40);

  
   rad = theta * Math.PI/180;
   F = .5*forced*l1;
    T = (F*l1)/(3*math.sin(rad)*(l1+2*l2));
    n = T*Math.cos(rad);
    v = T*math.sin(rad);
    m = T*math.sin(rad)*l2;

    

data = {
    params: {
        forced:forced,
        l1:l1,
        l2:l2,
        theta:theta,
        

        unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 

        n:n,
        v:v,
        m:m,


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