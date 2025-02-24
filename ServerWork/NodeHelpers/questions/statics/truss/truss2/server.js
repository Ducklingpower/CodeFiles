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
	length1= (math.randomInt(15,30)); //length of l1 in m or ft

	length2= length1*((math.randomInt(650,680))/1000);
    length3= length1*((math.randomInt(300,350)))/1000;
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




//reactions
reactionFy=(length1*weight)/(length1+length2);
reactionFx=0;
reactionAx=0;
reactionAy=weight-reactionFy;

trig=1/Math.sqrt(2);

AB=-reactionAy/trig;
AJ=-AB*trig;
BJ=0;
IJ=reactionAy;
BI=-AB;
BC=(-BI*trig)+(AB*trig);
HI=IJ+(BI*trig);
CI=-BI*trig;
CH=-CI/(trig);
CD=BC-(CH*trig);
EF=-reactionFy/trig;
FG=-EF*trig;
DE=FG;
EG=FG;
DG=EF;
DH=-DG*trig;
GH=HI+(CH*trig);



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

reactionEx:reactionFx,
reactionEy:reactionFy,
reactionAx:reactionAx,
reactionAy:reactionAy,
    AB:AB,
    BC:BC,
    CD:CD,
    DE:DE,
    DE:DE,
    EF:EF,
    FG:FG,
    GH:GH,
    HI:HI,
    IJ:IJ,
    AJ:AJ,
    BJ:BJ,
    BI:BI,
    CI:CI,
    CH:CH,
    DH:DH,
    DG:DG,
    EG:EG,

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