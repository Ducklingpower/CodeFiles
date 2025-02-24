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
            "forcee":"N/m"
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
            "forcee":"lb/ft"
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

    fp = math.randomInt(10,200);
    fb = math.round(fp*(math.randomInt(115,130)/100));
    fo = math.round(fb*(math.randomInt(140,160)/100));
    fr = math.round(fo*(math.randomInt(130,150)/100));



    l2 = math.randomInt(5,25);
    l1 = math.round(l2*(math.randomInt(180,200)/100));
    l3 = math.round(l1*(math.randomInt(120,140)/100));





    //vect Fo
//(-l3,-l1,l1)
lengtho = math.sqrt(l3**2+l1**2+l1**2);
xo = fo*(-l3/lengtho);
yo = fo*(-l1/lengtho);
zo = fo*( l1/lengtho);

    //vec Fp
//(-l2,l2,0)
lengthp = math.sqrt(l2**2+l2**2);
xp = fp*(-l2/lengthp);
yp = fp*(l2/lengthp);
zp = 0;

    //vec FB
//(l2,l1,l2)
lengthb = math.sqrt(l2**2+l2**2+l1**2);
xb = fb*(l2/lengthb);
yb = fb*(l1/lengthb);
zb = fb*(l2/lengthb);

    //vec FR
//(l2,-l2,-l3)
lengthr = math.sqrt(l2**2+l2**2+l3**2);
xr = fr*(l2/lengthr);
yr = fr*(-l2/lengthr);
zr = fr*(-l3/lengthr);

Fx = -(xo+xp+xb+xr);
Fy = -(yo+yr+yp+yb);
Fz = -(zr+zo+zb);
    
F = math.sqrt(Fx**2+Fy**2+Fz**2);
Ufx = Fx/F;
Ufy = Fy/F;
Ufz = Fz/F;



data = {
    params: {
       
       l1:l1,
       l2:l2,
       l3:l3,
       fr:fr,
       fo:fo,
       fp:fp,
       fb:fb,
       unitsForce:unitsForce,
       unitsDist:unitsDist,
     



       
},

    correct_answers: { 
   F:F,
   Ufx:Ufx,
   Ufy:Ufy,
   Ufz:Ufz,

  
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