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
	
f = math.randomInt(10,30);
l1 = math.randomInt(350,450);
l2 = math.randomInt(750,850);
l3 = math.randomInt(15,25)/100;
d= math.randomInt(8,12);//all in mm and kN




ff= f*1000;
l11=l1/1000;
l22=l2/1000;
l33=l3/1000;
dd = d/1000;




E = 200*(10**9);
    A = Math.PI * (dd/2)**2;
   //N = (l33-((f*l11)/(A*E)))/((-(l11)/(A*E))+((l22)/(A*E)));
   N= ((l33*A*E)-(l11*ff))/(-l11-l22);
   
N = N/1000;



data = {
    params: {
        f:f,
        l1:l1,
        l2:l2,
        l3:l3,
        d:d,
        unitsDist1:unitsDist1,
        unitsForce:unitsForce,

       
      
},

    correct_answers: { 
        N:N
    

},
   nDigits: 2,
   sigfigs:2
}

console.log(data);
return data;
}

