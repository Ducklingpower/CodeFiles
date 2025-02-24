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
            "dist": "mm",
            "force": "N",
            "angSpeed": "rad/s",
            "angle": "degrees",
            "speed": "m/s",
            "acc": "m/s^2"
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "in",
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
 
	force= (math.randomInt(10,100));//the force
	length1= (math.randomInt(40,100)); //length of l1 in m or ft
    
    

	length2= length1*((math.randomInt(780,820))/1000);
    length3= length1*((math.randomInt(220,260))/1000);
    length4= length1*((math.randomInt(80,120))/1000);


    length1=(Math.round(length1*100))/100;
    length2=(Math.round(length2*100))/100;
    length3=(Math.round(length3*100))/100;
    length4=(Math.round(length4*100))/100;
    if(unitSel>0){
    
        length1=length1/25;
        length2=length2/25;
        length3=length3/25;
        length4=length4/25;

    length1=(Math.round(length1*100))/100;
    length2=(Math.round(length2*100))/100;
    length3=(Math.round(length3*100))/100;
    length4=(Math.round(length4*100))/100;
        
    }

    //testvals
    //length1=62.5
    //force=80
    //length2=50
    //length3=15
    //length4=6.25
    

theta=(Math.atan(length3/length1))+(Math.atan((length3+length4)/length2));
distab=Math.sqrt((length1**2)+(length3)**2);
reactionB=(force*(length1+length2))/(distab*Math.sin(theta));
forceP=reactionB*Math.cos(Math.atan((length3+length4)/length2));







data = {
    params: {
        force:force,
        length1: length1,
        length2: length2,
        length3: length3,
        length4: length4,
        unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 

 forceP:forceP


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