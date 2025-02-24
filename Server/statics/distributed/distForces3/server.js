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


    
	forceF = math.randomInt(50,95);
    forceP = math.randomInt(100,150);//the force

	length1= (math.randomInt(10,30)); //length of l1 in m or ft
	length2= length1*((math.randomInt(660,670))/1000);
   
    length1=(Math.round(length1*10))/10;
    length2=(Math.round(length2*10))/10;
  
    if(unitSel>0){
    
        length1=length1*3;
        length2=length2*3;
        length1=(Math.round(length1*10))/10;
        length2=(Math.round(length2*10))/10;
    }

F=(forceF*length1)/2;
Fxx=length1*(2/3);
P=(forceP*length2)/2;
Pxx=length2*(1/3)+length1
momentA=P*Pxx-F*Fxx;

data = {
    params: {
         forceF: forceF,
         forceP:forceP,
        length1: length1,
        length2: length2,
        unitsForcee:unitsForcee,
        unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 
    momentA:momentA,
    F:F,
    P:P,
    Fxx:Fxx,
    Pxx:Pxx,
    
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