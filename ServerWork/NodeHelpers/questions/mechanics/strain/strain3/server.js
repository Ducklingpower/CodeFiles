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
 
	l= math.randomInt(200,500);
    l2 = math.randomInt(3,6);
    l3 = math.round(100*l2*1.2)/100;



    LAC = math.sqrt(l**2+l**2);
    LAC2 = math.sqrt((l2+l2+l)**2+(l-l3)**2);
    rad  = 2*math.atan((l2+l2+l)/(l-l3));
    strain = (LAC2-LAC)/(LAC);
    shear = (Math.PI)/(2)-rad;





data = {
    params: {
     
        
        l:l,
        l2:l2,
        l3:l3,
       unitsDist:unitsDist,


      
},

    correct_answers: { 


strain:strain,
shear:shear,

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
