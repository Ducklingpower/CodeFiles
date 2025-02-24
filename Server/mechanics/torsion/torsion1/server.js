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
            "moment":"Nm",
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


    t3 = math.randomInt(40,100);          //Nm
    t2 = math.round(t3*.65*10)/10;    //Nm
    t1 = math.round(t3*.26*10)/10;    //Nm

    d= math.round(math.random(250,500)); //mm
  
    rr = (d/2)*(1/1000)  //m
    r= math.round(d*(math.random(250,500)/1000)) //mm
    rs = r/1000//m




    shear1 = (t1*2)/(Math.PI*(rr**3));
    shear2 = (t1*2*rs)/(Math.PI*(rr**4));

    


 



data = {
    params: {
         d:d,
         r:r,
        t1:t1,
        t2:t2,
        t3:t3,
      unitsMoment:unitsMoment,
        unitsDistt:unitsDistt
},

    correct_answers: { 
   shear1:shear1,
   shear2:shear2,
    
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