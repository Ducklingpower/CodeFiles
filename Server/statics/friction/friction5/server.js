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

 friction= math.randomInt(45,55)/100;
 kinetic=math.randomInt(10,20)/100;
 static=math.randomInt(22,30)/100;
e=2.718281828;
angleTHETA=math.randomInt(20,30)
anglePHI=math.randomInt(18,30) 

THETA=(math.randomInt(20,30))*(Math.PI/180);
PHI=(math.randomInt(18,30))*(Math.PI/180);

 if(unitSel>0){ 
    mass=math.randomInt(800,900);
    weight=mass*1 }
else{ mass=math.randomInt(82,92);
    weight=math.round(mass*9.81*100)/100 }
sin=math.sin(THETA);
cos=math.cos(THETA);
beta=(180-angleTHETA-anglePHI)*(Math.PI/180);


//
P1=((weight*sin)+(static*weight*cos))*e**(friction*beta);
//
P2=((weight*sin)+(kinetic*weight*cos))*e**(friction*beta);
//
P3=((weight*sin)-(static*weight*cos))/(e**(friction*beta));
//
P4=((weight*sin)-(kinetic*weight*cos))/(e**(friction*beta));




data = {
    params: { 
        weight:weight,
        friction:friction,
        static:static,
        kinetic:kinetic,
        unitsForce:unitsForce,
        unitsMass:unitsMass,
        angleTHETA:angleTHETA,
        anglePHI:anglePHI,
        mass:mass,
},

    correct_answers: { 
        P1:P1,
        P2:P2,
        P3:P3,
        P4:P4,

  
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