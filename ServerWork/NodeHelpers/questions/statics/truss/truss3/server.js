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
 
	weight= (math.randomInt(100,2000));//the force
	length1= (math.randomInt(2,10)); //length of l1 in m or ft

	length2= length1*((math.randomInt(480,520))/1000);
    length3= length1*((math.randomInt(235,265)))/1000;
    length1=(Math.round(length1*10))/10;
    length2=(Math.round(length2*10))/10;
    length3=(Math.round(length3*10))/10;
    if(unitSel>0){
    
        length1=length1*3;
        length2=length2*3;
        length3=length3*3;
        length1=(Math.round(length1*10))/10;
        length2=(Math.round(length2*10))/10;
        length3=(Math.round(length3*10))/10;
    }
//test vals
//length1=2
//length2=1
//length3=.5
//weight=8



//reactions
reactionAx=0
reactionNy=(weight*(length1+length1+length1+length1))/length1;//+
reactionAy=weight-reactionNy;//-
reactionAy=reactionAy*-1;//+
reactionNx=0;

thetaRAD=Math.atan(length3/(length1+length1+length1));

LK=-reactionAy/Math.cos(thetaRAD);//compression
DE=-LK*Math.cos(thetaRAD);//tension
DL=DE*Math.sqrt(2);
EL=-LK*Math.sin(thetaRAD)-(DL/Math.sqrt(2));//comp





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

reactionEx:reactionNx,
reactionEy:reactionNy,
reactionAx:reactionAx,
reactionAy:reactionAy,
DE:DE,
EL:EL,
LK:LK,
DL:DL,
   
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