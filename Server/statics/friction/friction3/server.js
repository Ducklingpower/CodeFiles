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
    
    unitSel = 0;
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngSpeed = units[unitSystems[unitSel]].angSpeed;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsAcc = units[unitSystems[unitSel]].acc;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsForcee=units[unitSystems[unitSel]].forcee

  angle=math.randomInt(35,45);
  
  ang=angle*Math.PI/180;
  static1=math.randomInt(55,45)/100
  kinetic1=math.randomInt(35,30)/100
  static2=math.round((static1/2)*100)/100
  kinetic2=math.round((kinetic1/2)*100)/100
  static3=math.randomInt(22,32)/100;
  kinetic3=math.randomInt(10,20)/100;

    
    mass1=math.randomInt(190,210);
    weight1=mass1*9.81;         
    mass2=math.randomInt(90,110);
    weight2=mass2*9.81; 
    mass3_1=math.round(math.randomInt(580,610)/(9.81*Math.sin(ang)-kinetic3*9.81*Math.cos(ang)));
    mass3_2=math.round(math.randomInt(790,810)/(9.81*Math.sin(ang)-kinetic3*9.81*Math.cos(ang)));
    mass3_3=math.round(math.randomInt(1190,1210)/(9.81*Math.sin(ang)-kinetic3*9.81*Math.cos(ang)));
    weight3_1=mass3_1*9.81*Math.sin(ang)-kinetic3*9.81*mass3_1*Math.cos(ang);
    weight3_2=mass3_2*9.81*Math.sin(ang)-kinetic3*9.81*mass3_2*Math.cos(ang);
    weight3_3=mass3_3*9.81*Math.sin(ang)-kinetic3*9.81*mass3_3*Math.cos(ang);


    //Q1
frictionM1_1=weight3_1;
frictionM2_1=frictionM1_1;

//Q2
frictionM1_2=weight3_2;
frictionM2_2=kinetic2*(weight2+weight1);

//Q3
frictionM1_3=kinetic1*(weight1);
frictionM2_3=frictionM1_3;

//Q4
M_3min=(static1*weight1)/(9.81*Math.sin(ang)-kinetic3*9.81*Math.cos(ang));



data = {
    params: {
        unitsForce:unitsForce,
        unitsMass:unitsMass,
        mass1:mass1,
        mass2:mass2,
        mass3_1:mass3_1,
        mass3_2:mass3_2,
        mass3_3:mass3_3,
        angle:angle,
        static1:static1,
        static2:static2,
        static3:static3,
        kinetic1:kinetic1,
        kinetic2:kinetic2,
        kinetic3:kinetic3,

},

    correct_answers: { 
   frictionM1_1:frictionM1_1,
   frictionM2_1:frictionM2_1,
   frictionM1_2:frictionM1_2,
   frictionM2_2:frictionM2_2,
   frictionM1_3:frictionM1_3,
   frictionM2_3:frictionM2_3,
   M_3min:M_3min
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