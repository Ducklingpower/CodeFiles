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
	
   
F1  = math.randomInt(70,100);//kN
F2  = math.randomInt(30,50);//kN
F3  = math.randomInt(60,80);//kN

l1 = math.randomInt(1,2);           //m
l2 = math.round(l1*1.5*10)/10;//m
l3 = math.round(l2*1.2*10)/10;//m

d = math.randomInt(40,60)/1000;//m



//converting
F11 = F1*1000;
F22 = F2*1000;
F33 = F3*1000;
E = 200*10**9;
A = Math.PI*(d/2)**2;

change1 = math.abs((F33*l3)/(A*E));
change2 = math.abs(((F33-F22)*l2)/(A*E));
change3  = math.abs(((F11+F22-F33)*l1)/(A*E));

change = -change1-change2+change3
change = change*10**6;


data = {
    params: {
        F1:F1,
        F2:F2,
        F3:F3,
        l1:l1,
        l2:l2,
        l3:l3,
        d:d,
        unitsDist:unitsDist,
        unitsForce:unitsForce,

       
      
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
