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

    
    f = math.randomInt(5,15); //kN
    l1 = math.randomInt(6,15);//m
    l2 = math.randomInt(125,200)//mm
    l3 = math.round(l2*math.randomInt(80,100)/100);//mm
    l4 = math.randomInt(25,35);//mm
    t = l4



    ff = f*1000;//N
    ll1 = l1//m
    ll2 = l2/1000;//m
    ll3 = l3/1000;//m
    ll4 = l4/1000;//m

    reactionB = (ff*(ll1/2)*(3/4)*ll1)/(ll1);
    reactionA = ((ff*ll1)/2)-reactionB;
    ybar = ((ll3/2)*(ll3*ll4)+(ll3+(ll4/2))*(ll2*ll4))/((ll3*ll4)+(ll2*ll4));
    I = ((1/12)*ll4*(ll3**3)+(ll4*ll3*(ybar-(ll3/2))**2))+((1/12)*(ll2*(ll4**3))+(ll2*ll4*(ll3+(ll4/2)-ybar)**2))
    Q = (ll3+(ll4/2)-ybar)*(ll4*ll2);
    V = reactionB
    shear = (V*Q)/(I*t);
   
    reactionA = reactionA/1000;//kN
    reactionB = reactionB/1000;//kN
    I = I*10**(6)//micro m
    ybar = ybar*1000//mm
    shear  = shear *10**(-6)//Mpa
    Q = Q*1000//mm

data = {
    params: {
   t:t,
   f:f,
   l1:l1,
   l2:l2,
   l3:l3,
   l4:l4,
   unitsDist:unitsDist,
   unitsDistt:unitsDistt,


},

    correct_answers: { 
        I:I,
        Q:Q,
        shear:shear,
        reactionA:reactionA,
        reactionB:reactionB,
        ybar:ybar,
      



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