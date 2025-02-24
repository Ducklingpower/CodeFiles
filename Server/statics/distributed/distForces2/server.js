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


    force  = (math.randomInt(20,100));
	forceD = force*(math.randomInt(175,185)/1000);
    forceP = forceD*((math.randomInt(490,510)/1000));//the force

	length1= (math.randomInt(3,7)); //length of l1 in m or ft
	length2= length1*((math.randomInt(660,670))/1000);
    length3= length1*((math.randomInt(330,340))/1000);

    forceD=(Math.round(forceD*100))/100;
    forceP=(Math.round(forceP*100))/100;
    length1=(Math.round(length1*100))/100;
    length2=(Math.round(length2*100))/100;
    length3=(Math.round(length3*100))/100;
 

//math
reactionAx=0
reactionBx=0
reactionBy=((-forceP*length2*(length3+(length2/2))+(forceD*length1*(length3+(length1/2)))-(force*(length1+length3+length3)))/(length3+length1));
reactionAy=-reactionBy+(forceD*length1)+(forceP*length2)-force;
reactionBy=Math.abs(reactionBy)

data = {
    params: {
         forceD: forceD,
         forceP:forceP,
          force:force,
        length1: length1,
        length2: length2,
        length3:length3,
        unitsForcee:unitsForcee,
        unitsForce:unitsForce,
        unitsDist:unitsDist
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