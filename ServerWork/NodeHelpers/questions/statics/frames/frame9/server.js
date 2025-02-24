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
            "forcee":"N/m",
            "distt":"mm",
        },
        "uscs": {
            "masslabel": "weight",
            "mass": "lb",
            "dist": "feet",
            "force": "lb",
            "angSpeed": "rpm",
            "angle": "degrees",
            "speed": "feet/s",
            "acc": "ft/s^2",
            "forcee":"lb/ft",
            "distt":"in",

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
    unitsForcee=units[unitSystems[unitSel]].forcee
    unitsDistt = units[unitSystems[unitSel]].distt;



    if(unitSel==0){
        weight = math.randomInt(600,900);
        l1 = math.randomInt(150,300);
        l2 = math.round(l1*.3*100)/100;


    }else{
        weight = math.randomInt(140,180);
        l1 = math.randomInt(5,8);
        l2 = math.round(l1*.3*100)/100;
        
    }

weight = 70*9.81;
l1=200;
l2=60;


weight = weight/2;
Ax = 0;
Bx = 0;
By = (weight*(l2+l1+(l1/2)))/(l1+l1+(l1/2));
Ay = weight-By;
Cy = (weight*(l2+l1))/(l1);
Dy = weight-Cy;
Ey = Cy-By;
A  = math.atan((2*l1)/(l1/2));
B  = math.atan((2*l1)/(l1));
C  = Math.PI-(A+B);
c  = l1;
a  = (c*math.sin(A))/(math.sin(C));
Ex = (By*l1-Ey*(a*math.cos(B)))/(a*math.sin(B));
Cx = Ex;
Dx = Ex;
Dy = Ey-Ay;



data = {
    params: {
       
      l1:l1,
      l2:l2,
      weight:weight,
    

      

       unitsForce:unitsForce,
       unitsDist:unitsDist,
       unitsDistt:unitsDistt,

     



       
},

    correct_answers: { 

  Ax:Ax,
  Ay:Ay,
  Bx:Bx,
  By:By,
  Cx:Cx,
  Cy:Cy,
  Dx:Dx,
  Dy:Dy,
  Ex:Ex,
  Ey:Ey,

  
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