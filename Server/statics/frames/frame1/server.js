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
            "dist": "feet",
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
 
	weight = (math.randomInt(100,500));//the force
	length1= (math.randomInt(400,700))/1000; //length of l1 in m or ft

	length2= length1*((math.randomInt(550,650))/1000);
    length3= length1*((math.randomInt(350,450))/1000);

    length1=(Math.round(length1*100))/100;
    length2=(Math.round(length2*100))/100;
    length3=(Math.round(length3*100))/100;
    
if(unitSel>0){
    
    length1=length1*3;
    length2=length2*3;
    length3=length3*3;
   
}
// Using FBD A-C
//moment about point A
reactionB=(weight*(length1+length2))/(length1*0.866025404);

//using FBD B-D
//sum force in x direction
reactionD=reactionB;

//FBD D-E
//moment about E
reactionF=(reactionD*0.866025404*(length3+length3))/(length3);

data = {
    params: {
         weight: weight,
        length1: length1,
        length2: length2,
        length3: length3,
        unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 
    reactionB:reactionB,
    reactionD:reactionD,
    reactionF:reactionF
    
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