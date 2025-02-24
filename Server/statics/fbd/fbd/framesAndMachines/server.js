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
 
	W = (math.randomInt(100,500));//the force
	l1= (math.randomInt(150,250))/100; //length of l1 in m or ft
	l2= (math.randomInt(300,400))/100;
    l3= (math.randomInt(150,250))/100;
    l4=(math.randomInt(40,60))/100;
	radius=l4;
if(unitSel>0){
    
    l1=l1*3;
    l2=l2*3;
    l3=l3*3;
    l4=l4*3;
    radius=radius*3;
}






//------- solving for reactions forces Dx,Ax,Ay
DX=((l2+l3+radius)*(W))/(l1+l1+l1+l4);
DY=0;
AX= -DX;
AY=W;

// -------solving for the forces on member B-F
EY=((l2+l3)*(W))/(l2);

ang = math.atan(l1/l2)

EX=EY/math.tan(ang);
//by semitry 
CY= -EY;
CX= -EX;
// point F
FX=W;
FY=W;

BY=EY-FY;
BX=EX-FX;


data = {
    params: {
        W: W,
        l1: l1,
        l2: l2,
        l3: l3,
        l4: l4,
        unitsForce: unitsForce,
        unitsDist: unitsDist,
        radius: radius
},

    correct_answers: { 
    AX:math.abs(AX),
    AY:math.abs(AY),
    BX:math.abs(BX),
    BY:math.abs(BY),
    CX:math.abs(CX),
    CY:math.abs(CY),
    DX:math.abs(DX),
    DY:math.abs(DY),
    EX:math.abs(EX),
    EY:math.abs(EY),
    FX:math.abs(FY),
    FY:math.abs(FY)
},
   nDigits: 2,
   sigfigs:2
}

console.log(data);
return data;
}
//generate();
module.exports = {
    generate
}