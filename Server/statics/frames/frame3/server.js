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
	radious=l4;
if(unitSel>1){
    
    l1=l1*3;
    l2=l2*3;
    l3=l3*3;
    l4=l4*3;
    radious=radious*3;
}






//------- solving for reactions forces Dx,Ax,Ay
DX=((l2+l3+radious)*(W))/(l1+l1+l1+l4);
DY=0;
AX=DX;
AY=W;

// -------solving for the forces on member B-F
EY=((l2+l3)*(W))/(l2);
EX=EY*2;
//by semitry 
CY=EY;
CX=EX;

BY=EY-W;
BX=EX-W;
// point F
FX=W;
FY=W;

data = {
    params: {
         W: W,
        l1: l1,
        l2: l2,
        l3: l3,
        l4: l4,
   radious: radious,
   unitsForce:unitsForce,
   unitsDist:unitsDist
},

    correct_answers: { 
    AX:AX,
    AY:AY,
    BX:BX,
    BY:BY,
    CX:CX,
    CY:CY,
    DX:DX,
    DY:DY,
    EX:EX,
    EY:EY,
    FX:FY,
    FY:FY
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