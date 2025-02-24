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
    
    unitSel = 0
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngSpeed = units[unitSystems[unitSel]].angSpeed;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsAcc = units[unitSystems[unitSel]].acc;
    masslabel = units[unitSystems[unitSel]].masslabel;
 
	l1 = math.randomInt(300,600);
    l2 = math.round(l1*.75*10)/10;
    l3 = math.randomInt(40,60)/10;
    l4 =math.round(l3*(3/5) *10)/10;



    LBC = math.sqrt(l1**2+l2**2);
    LBC2 = math.sqrt((l3+l1)**2+(l2-l4)**2);
    strain = (LBC2-LBC)/(LBC);
    shearA = math.atan((l4)/(l1+l3));
    theta1 = math.atan((l2-l4)/(l1+l3));
    theta2 = math.atan((l1)/(l2));
    shearC = (Math.PI)/(2)-(theta1+theta2);



    



data = {
    params: {
     
        
        l1:l1,
        l2:l2,
        l3:l3,
        l4:l4,
        
       unitsDist:unitsDist,


      
},

    correct_answers: { 

        shearA:shearA,
        shearC:shearC,
        strain:strain,
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
