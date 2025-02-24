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
            "moment":"Nm",
            "distt":"mm",
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
            "moment": "kip*in",
            "distt":"mm",

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
    unitsMoment = units[unitSystems[unitSel]].moment;
    unitsDistt = units[unitSystems[unitSel]].distt;



l2 = math.randomInt(2,5);
l3 = math.round(l2*0.4*10)/10;
l1 = math.round(l2*0.5*10)/10;

t2 = math.randomInt(750,900);
t1 = math.round(t2*.625*10)/10;



reactionB = (t2*l2+((t2-t1)*l1))/(l1+l2+l3);

 reactionA = t2-t1-reactionB;



data = {
    params: {
        
        t1:t1,
        t2:t2,
   
     
        l1:l1,
        l2:l2,
        l3:l3,


      unitsMoment:unitsMoment,
        unitsDist:unitsDist
},

    correct_answers: { 
        reactionA:reactionA,
        reactionB:reactionB,
    
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