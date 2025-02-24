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
	
theta = math.randomInt(50,70);
c = math.randomInt(10,50)/10;





rad = theta*(Math.PI/180);



t = ((rad)/(c))**(2/3);
theta1 =((c*3)/(2))*t**(1/2);
theta2 = ((c*3)/(2*2))*t**(-1/2);
r = 4*Math.sin(2*rad);
r1 = 8*Math.cos(2*rad)*theta1;
r2 = -(16*Math.sin(2*rad)*theta1*theta1)+8*Math.cos(2*rad)*theta2;

V = Math.sqrt(r1**2+(r*theta1)**2);
A = Math.sqrt((r2-(r*theta1**2))**2+(r*theta2+2*r1*theta1)**2)




data = {
    params: {
t:t,
theta:theta,
c:c,
      theta1:theta1,
      theta2:theta2,
      r:r,
      r1:r1,
      r2:r2,

},

    correct_answers: { 
 
V:V,
A:A,

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
