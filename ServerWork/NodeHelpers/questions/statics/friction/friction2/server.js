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

  
    if(unitSel>0){ 
        m=math.randomInt(400,540);
        weight=m*1 }
    else{ m=math.randomInt(45,55);
        weight=m*9.81 }
P1=0
P2=math.randomInt(190,210);
P3=math.randomInt(250,280);
static=math.randomInt(230,270)/1000;
kinetic=static*.8;
kinetic=Math.round(kinetic*1000)/1000
angle=math.randomInt(15,25);



C=math.cos(angle*(Math.PI/180));
S=math.sin(angle*(Math.PI/180));
CC=math.cos(15*(Math.PI/180));
SS=math.sin(15*(Math.PI/180));
//questionA

answerA=kinetic*(weight*CC);//pointing Up
answerB=-((P2*C)-(weight*SS));//Down Hill
answerC=-(kinetic*(weight*CC-(P3*S)));//Down Hill
answerD=((static*weight*CC)+(weight*SS))/((S*static)+C);

data = {
    params: {
        unitsForce:unitsForce,
       P1:P1,
       P2:P2,
       P3:P3,
       unitsMass:unitsMass,
       m:m,
       angle:angle,
       static:static,
       kinetic:kinetic
},

    correct_answers: { 
    answerA:answerA,
    answerB:answerB,
    answerC:answerC,
    answerD:answerD
  
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