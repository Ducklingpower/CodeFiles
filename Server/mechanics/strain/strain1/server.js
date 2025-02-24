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
            "dist1": "mm",
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
    
    unitSel = 0;

    unitsDist = units[unitSystems[unitSel]].dist;
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngSpeed = units[unitSystems[unitSel]].angSpeed;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsAcc = units[unitSystems[unitSel]].acc;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsDist1 = units[unitSystems[unitSel]].dist1;
	
    l1 = math.randomInt(25,35)/10;
    l3 = math.randomInt(15,25);
    l2 = l3*0.5;
    l4 = math.round(l1*1.25*10)/10;


    //test vales


l2c = l2/1000;
l3c = l3/1000;


    LAB = Math.sqrt((l4)**2+(l1)**2);
    LAC = LAB;
    LAB2 = Math.sqrt((l4 + l3c)**2+(l1+l2c)**2);
    LAC2 = Math.sqrt((l4+l3c)**2+(l1-l2c)**2);

    strainB = (LAB2-LAB)/(LAB);
    strainC = (LAC2-LAC)/(LAC);






data = {
    params: {

        unitsDist:unitsDist,
        unitsDist1:unitsDist1,
        l1:l1,
        l2:l2,
        l3:l3,
        l4:l4,

      
},

    correct_answers: { 

strainB:strainB,
strainC:strainC,



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
