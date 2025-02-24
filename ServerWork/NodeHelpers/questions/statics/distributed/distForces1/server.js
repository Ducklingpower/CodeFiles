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

 
	forceP = (math.randomInt(500,2000));
    forceD = forceP*((math.randomInt(150,175)/1000));//the force


	length1= (math.randomInt(5,25)); //length of l1 in m or ft
	length2= length1*((math.randomInt(450,550))/1000);

    forceD=(Math.round(forceD*10))/10;
    length1=(Math.round(length1*10))/10;
    length2=(Math.round(length2*10))/10;
    if(unitSel>0){
    
        length1=length1*3;
        length2=length2*3;
        length1=(Math.round(length1*10))/10;
        length2=(Math.round(length2*10))/10;
    }

//math
reactionAx=0
reactionBx=0

reactionBy=((forceP*length1)+(forceD*length1)*(length1+length2+(length1/2)))/(length1+length2+length1);
reactionAy=forceP+forceD*length1-reactionBy;
    
data = {
    params: {
         forceD: forceD,
         forceP:forceP,
        length1: length1,
        length2: length2,
       
        unitsForce:unitsForce,
        unitsDist:unitsDist,
        unitsForcee:unitsForcee
},

    correct_answers: { 
    reactionAx:reactionAx,
    reactionAy:reactionAy,
    reactionBx:reactionBx,
    reactionBy:reactionBy
    
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