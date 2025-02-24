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
 
	weight= (math.randomInt(100,500));//the force
	length2= (math.randomInt(3,20)); //length of l1 in m or ft

	length1= length2*((math.randomInt(420,750))/1000);
    length1=(Math.round(length1*10))/10;

    if(unitSel>0){
    
        length1=length1*3;
        length2=length2*3;
        length1=(Math.round(length1*10))/10;
    }
//testing values
//length1=2.3094;
//length2=4;
//weight=1;

  thetaRAD=Math.atan(length1/length2);



    //from joint C
    BC=weight/(Math.sin(thetaRAD));//Tension
    CD=-weight*((Math.cos(thetaRAD))/(Math.sin(thetaRAD)));//compression

    //from joint B
    AB=CD*-1;//tension
    BD=-weight;//compression

    //from joint D
    DE=CD+CD;
    AD=BC
    
    //from joint E
    AE=0


//Reaction forces

reactionEx=DE*-1
reactionEy=0
reactionAx=DE*-1
reactionAy=weight


data = {
    params: {
         weight: weight,
        length1: length1,
        length2: length2,
       
        unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 

reactionEx:reactionEx,
reactionEy:reactionEy,
reactionAx:reactionAx,
reactionAy:reactionAy,
    AB:AB,
    BC:BC,
    CD:CD,
    DE:DE,
    AD:AD,
    AE:AE,
    BD:BD,

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