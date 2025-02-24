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
            "distSmall": "mm",
            "force": "N",
            "angSpeed": "rad/s",
            "angle": "degrees",
            "speed": "m/s",
            "acc": "m/s^2",
            "forcee": "N/m"
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "feet",
            "distSmall": 'in',
            "force": "lb",
            "angSpeed": "rpm",
            "angle": "degrees",
            "speed": "feet/s",
            "acc": "ft/s^2",
            "forcee": "lb/ft"
        }
    }

    unitSel = math.randomInt(0, 2);
    unitsDist = units[unitSystems[unitSel]].dist;
    unitsDistSmall = units[unitSystems[unitSel]].distSmall
    unitsSpeed = units[unitSystems[unitSel]].speed;
    unitsMass = units[unitSystems[unitSel]].mass;
    unitsForce = units[unitSystems[unitSel]].force;
    unitsAngSpeed = units[unitSystems[unitSel]].angSpeed;
    unitsAngle = units[unitSystems[unitSel]].angle;
    unitsAcc = units[unitSystems[unitSel]].acc;
    masslabel = units[unitSystems[unitSel]].masslabel;
    unitsForcee = units[unitSystems[unitSel]].forcee




    //assign values to parameters 
   
   if (unitSel === 0) {
    length = (math.randomInt(1, 3));
    elongate = ((math.randomInt(2, 25)) + math.random()).toFixed(2);
   } 

   else {
    length = (math.randomInt(3, 10));
    elongate = (math.random()).toFixed(2);
   }



 


    //solve 

    if (unitSel === 0) {
        epsilon = ((elongate / 1000) / length);
    }
    else {
        epsilon = ((elongate / 12)/ length);
    }


    data = {
        params: {
            length: length,
            elongate: elongate,


            unitsDist: unitsDist,
            unitsDistSmall: unitsDistSmall,

        },

        correct_answers: {
            epsilon: epsilon
        },
        nDigits: 2,
        sigfigs: 2
    }

    console.log(data);
    return data;
}
generate();
module.exports = {
    generate
}

function computestrain(dl, L) {
    if (L !== 0) {
        const epsilon = dl / L;
        return epsilon;
    } else {
        console.error("Error: Division by zero.");
        return null;
    }
}
