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
   force = math.randomInt(50,150);
   l1 = math.randomInt(50,200);
   l2 = math.round(10*l1*math.randomInt(360,375)/1000)/10;
    }else{

        force = math.randomInt(50,150);
        l1 = math.randomInt(5,9);
        l2 = math.round(10*l1*math.randomInt(360,375)/1000)/10;
     
    }



  n = (force*l1)/(l2);
  Bx=0;
  By=force*(1+(l1/l2));
  n=n+n;



data = {
    params: {
       
      l1:l1,
      l2:l2,
   force:force,
     

      

       unitsForce:unitsForce,
       unitsDist:unitsDist,
       unitsDistt:unitsDistt,

     



       
},

    correct_answers: { 

  Bx:Bx,
 n:n,
  By:By,
  

  
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