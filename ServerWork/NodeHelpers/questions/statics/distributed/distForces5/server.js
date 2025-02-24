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


    
	
    constant=math.randomInt(200,300)/1000;
   
	length1= (math.randomInt(15,20));
	length2= length1*(math.randomInt(600,620))/1000;
    length3=.5*length2;

    length2=math.round(length2*100)/100;
    length3=math.round(length3*100)/100;
    counstant=math.round(constant*100)/100;

forceD=(constant*(length2**2))/(math.randomInt(130,140)/100);
forceD=math.round(forceD*100)/100;
//Green
   FG=(constant*(length2)**3)/(3);
   FGX=(3/4)*length1;
//RED
FR=((Math.PI)*(constant*(length1**2))**2)/4;
FRX=(4*(length3+length3))/((Math.PI)*3);
//purple
FP=(forceD*length1)/(2);
FPX=(1/3)*length1;
//Orange
FO=forceD*length3;
FOX=length3/2;
//solution
reactionB=(-(length3+length2-FGX)*(FG)-(length3-FRX)*(FR)+(length1+length3-FPX)*(FP)+(length1+length1+length3-FOX)*(FO))/(length1+length3);

reactionB=Math.abs(reactionB);

data = {
    params: {
         forceD: forceD,
         constant:constant,
        length1: length1,
        length2:length2,
        length3:length3,
      
        unitsForcee:unitsForcee,
        unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 
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