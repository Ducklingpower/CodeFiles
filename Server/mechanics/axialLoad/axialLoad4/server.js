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
	



f1 = math.randomInt(140,160);
f2 = math.randomInt(30,50);
l1 = math.randomInt(5,15);
l2 = math.round(l1*.8*10)/10;
d1 = math.randomInt(5,10)/100;
d2 = math.round(100*d1*(0.7))/100;



f1 = 155;
f2 = 43;
l1 = 6;
l2 = 4.8;
d1  = 0.05;
d2 = 0.04;




f11=f1*1000;
f22 = f2*1000;


N = f11-f22;

E = 80*10**9
change1 = (f22*l2)/(Math.PI*(d2/2)**2*(E));
change2 = (f22*(l1/2))/(Math.PI*(d1/2)**2*(E));
change3 = (N*(l1/2))/(Math.PI*(d1/2)**2*(E));
change = -change1-change2+change3

change = change*10**3






    

data = {
    params: {
        f1:f1,
        f2:f2,
        l1:l1,
        l2:l2,
        
        d1:d1,
        d2:d2,
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
