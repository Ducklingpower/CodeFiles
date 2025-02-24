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
	
    force = math.randomInt(80,100);
    l1 = math.randomInt(1000,2000);
    l2 = math.randomInt(150,100);
    l3 = l2/2;




    ll1 = l1/1000;
    ll2 = l2/1000;
    ll3 = l3/1000;




    forcee = force*1000
    stress = forcee/(ll2*ll3);
    strainz = stress/(200*10**9);
    z = strainz*ll1*10**6;
    strainx = 0.32*strainz;
    strainy = strainx;
    x = -strainx*ll2*10**6;
    y = -strainy*ll3*10**6;
    
   
data = {
    params: {

        
        unitsDist1:unitsDist1,
        unitsForce:unitsForce,
        l1:l1,
        l2:l2,
        l3:l3,
       force:force,

      
},

    correct_answers: { 

        z:z,
        x:x,
        y:y,


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
