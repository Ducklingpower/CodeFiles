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
            "force": "kN",
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
	
   force = math.randomInt(140,180);//kN
    l = math.randomInt(200,300);//mm
    d = math.randomInt(20,30);//mm
    l2 = math.randomInt(100,200)/100;//mm





    g = 26;//Gpa
    G = 26*10**9
    forcee = force*1000;
    ll  = l/1000;
    dd = d/1000;
    ll2 = l2/1000;

    stress = forcee/(Math.PI*(dd/2)**2);
    strain = (l2)/(l);
    E = stress/strain;
    v = ((E)/(G*2))-1;
    strainLat = v*strain;
    change = strainLat*d
   
data = {
    params: {

        
        unitsDist1:unitsDist1,
        unitsForce:unitsForce,
        l:l,
        l2:l2,
        d:d,
         g:g,
        force:force,


      
},

    correct_answers: { 

    change:change,
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
