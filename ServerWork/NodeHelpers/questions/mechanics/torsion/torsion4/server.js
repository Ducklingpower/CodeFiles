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



f1 = math.randomInt(50,100);
f2 = math.round(10*f1*(math.randomInt(80,100)/100))/10;
l2= math.randomInt(300,600)/1000;
l1 = math.round(10*l2*.75)/10;
rin = math.randomInt(40,60)//mm
rout = math.round(10*rin*1.4)/10;



rri = rin/1000;
rro = rout/1000;

m = f1*l1 + f2*l2;
outer = ((m*rro*2)/((Math.PI)*(rro**4-rri**4)))/1000;
inner = ((m*rri*2)/((Math.PI)*(rro**4-rri**4)))/1000;











data = {
    params: {
        
        f1:f1,
        f2:f2,
        rin:rin,
        rout:rout,
       
        l1:l1,
        l2:l2,
    


   unitsForce:unitsForce,
        unitsDist:unitsDist
},

    correct_answers: { 
      inner:inner,
      outer:outer,
    
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