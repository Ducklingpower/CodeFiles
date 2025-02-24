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
 
	force = (math.randomInt(100,500));//the force
	length2= (math.randomInt(600,800)); //length of l1 in m or ft

	length1= length2*((math.randomInt(400,450))/1000);
    length1=(Math.round(length1))/10000;
    length2=(Math.round(length2))/10000;
    if(unitSel>0){
    
        length1=length1*3;
        length2=length2*3;
        length1=(Math.round(length1*1000))/1000;
    length2=(Math.round(length2*1000))/1000;
       
    }
    

    length1=(Math.round(length1*10000))/10000;
    length2=(Math.round(length2*10000))/10000;
    
    


theta=(Math.atan(length1/length2));//*(180/Math.PI);

//testing values 
//length1=.03
//length2=.07
//force=150


//member BD
//Moment about D
reactionB=(force*(length1+length1+length2))/(Math.sin(theta)*(180/Math.PI)*length1);
//member BD 
//by sem.
reactionA=reactionB;
//member AC
//moment about C to solve normal force
boltForce=((reactionA*Math.sin(theta)*(180/Math.PI)*(length1+length2))-(force*(length1+length1+length2)))/(length1);
data = {
    params: {
         force: force,
        length1: length1,
        length2: length2,
       
        unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 
    boltForce:boltForce
    
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