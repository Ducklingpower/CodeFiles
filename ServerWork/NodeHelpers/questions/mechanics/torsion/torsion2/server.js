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
            "moment":"kNm",
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
            "moment": "kip*in",
            "distt":"mm",

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
    unitsMoment = units[unitSystems[unitSel]].moment;
    unitsDistt = units[unitSystems[unitSel]].distt;

l1 = math.randomInt(5,15);
l2 = math.round(l1*.75*10)/10;
l3 = math.round(l1*.5*10)/10;

tB = math.randomInt(100,200);           //KNm
tA = math.round(tB*(80/150)*10)/10;//KNm
tC = math.round(tB*(60/150)*10)/10;//KNm
tD = math.round(tB*(10/150)*10)/10;//KNm


ttA = tA*1000;
ttB = tB*1000;
ttC = tC*1000;
ttD = tD*1000;

r = math.randomInt(100,150)//mm


R = r/1000
G = 75*10**9;
J = (Math.PI/2)*(R)**4

change1 = ((ttA)*l1)/(G*J);
change2 = ((ttA-ttB)*l2)/(G*J);
change3 = ((ttA-ttB+ttC)*l3)/(G*J);

twist1 = change1+change2+change3;
twist2 = change1+change2;








 



data = {
    params: {
        
         r:r,
        tA:tA,
        tB:tB,
        tC:tC,
        tD:tD,
        l1:l1,
        l2:l2,
        l3:l3,


      unitsMoment:unitsMoment,
        unitsDist:unitsDist
},

    correct_answers: { 
        twist1:twist1,
        twist2:twist2,
    
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