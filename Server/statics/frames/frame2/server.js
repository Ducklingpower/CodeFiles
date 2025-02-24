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
 
	weight= (math.randomInt(500,3000));//the force
	length2= (math.randomInt(3,15)); //length of l1 in m or ft
    angle=45;
    angleRAD=angle*(Math.PI/180);

	length1= length2*((math.randomInt(825,845))/1000);
    length3= length2*((math.randomInt(650,675))/1000);
    length4= length2*((math.randomInt(150,175))/1000);


    length1=(Math.round(length1*10))/10;
    length2=(Math.round(length2*10))/10;
    length3=(Math.round(length3*10))/10;
    length4=(Math.round(length4*10))/10;
    if(unitSel>0){
    
        length1=length1*3;
        length2=length2*3;
        length3=length3*3;
        length4=length4*3;

    length1=(Math.round(length1*10))/10;
    length2=(Math.round(length2*10))/10;
    length3=(Math.round(length3*10))/10;
    length4=(Math.round(length4*10))/10;
        
    }


thetaRAD=Math.atan(length3/(length4*0.5));

pinD=(weight*Math.sin(angleRAD)*length1)/(Math.sin(thetaRAD)*length4);
F=(weight*Math.sin(angleRAD*length2))/(length4);


pinA=((Math.sin(angleRAD)*weight*(length1-length4))+(Math.cos(angleRAD)*length2*weight))/2;








data = {
    params: {
         weight: weight,
        length1: length1,
        length2: length2,
        length3: length3,
        length4: length4,
       angle:angle,
        unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 

 pinA:pinA,
 pinD:pinD


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