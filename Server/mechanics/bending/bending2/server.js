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


    f= math.randomInt(20,40)/10;//kN
    theta = math.randomInt(55,75);//deg
    d1 = math.randomInt(20,50)/10;//m
    d2 = math.round(d1*0.5*10)/10;//m
    l1 =math.randomInt(200,300);//mm
    l2 = math.randomInt(20,35);//mm
    l3 = math.round(l2*.75);//mm
    l4 =  math.round(l1*.8);//mm



    ff = f*1000;//N
    rad = theta*(Math.PI)/(180);//rad
    dd1 = d1;//m
    dd2 = d2;//m
    ll1 = l1/1000;//m
    ll2 = l2/1000;//m
    ll3 = l3/1000;//m
    ll4 = l4/1000;//m
    fy = ff*Math.sin(rad);
    fx = ff*Math.cos(rad);
    ybar = ((ll2/2)*(ll2*ll1)+2*(ll4/2)*(ll4*ll3))/((ll2*ll1)+2*(ll4*ll3));
    moment = fy*dd1+fx*ybar;
    I = ((1/12)*(ll1*(ll2**3))+(ll1*ll2*(ybar-(ll2/2))**2))+2*((1/12)*(ll3*(ll4**3))+(ll3*ll4*((ll4/2)-ybar)**2));
    stress = (moment*(ll4-ybar))/(I);

ybar = ybar*1000;
moment = moment/1000;
I = I*10**6;
stress = stress*10**(-6);


data = {
    params: {
        f:f,
        d1:d1,
        d2:d2,
        l1:l1,
        l2:l2,
        l3:l3,
        l4:l4,
        theta:theta,
        unitsDist:unitsDist,
        unitsDistt:unitsDistt,


},

    correct_answers: { 
   ybar:ybar,
   moment:moment,
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