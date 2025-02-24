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


  f = math.randomInt(350,750)/100;//kN
  l = math.randomInt(4,10);//m
  l1 = math.randomInt(250,350);//mm
  l2 = math.round(l1*.83);//mm
  l3 = math.randomInt(15,25);//mm







  ll = l//m
  ll1 = l1/1000;//m
  ll2=l2/1000;//m
  ll3=l3/1000;//m
ff = f*1000;//N
reactionB = (ff*ll)/(2);
  reactionA = -(reactionB)+(ff*ll);
  


  maxM = (reactionA*(ll/2))/(2);
  I = 2*((1/12)*ll2*(ll3**3)+ll2*ll3*((ll1/2)+(ll3/2))**2)+((1/12)*ll3*(ll1**3));
  c = (ll1/2)+ll3;
  stress = (maxM*c)/(I);

  reactionA = reactionA/1000; //kN
  reactionB = reactionB/1000; //kN
  maxM = maxM/1000//kN*m
  I = I*10**(6)//micro meter;
  stress = stress*10**(-6)//Mpa


    


 



data = {
    params: {
        f:f,
        l:l,
        l1:l1,
        l2:l2,
        l3:l3,
        unitsDist:unitsDist,
        unitsDistt:unitsDistt,


},

    correct_answers: { 
   reactionB:reactionB,
   reactionA:reactionA,
   maxM:maxM,
   I:I,
   stress:stress,

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