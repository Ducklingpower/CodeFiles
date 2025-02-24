const math = require('mathjs');

let  fluidProperties = {
    "water": {
        "sg": 1
    },
    "gasoline": {
        "sg": 0.72
    },
    "diesel": {
        "sg": 0.8
    },
    "benzene": {
        "sg": 0.88
    },
    "ethanol": {
        "sg": 0.79
    }, 
    "acetone": {
        "sg": 0.78
    },
    "corn oil": {
        "sg": 0.92
    },
    "gylcerine": {
        "sg": 1.26
    },
    "honey": {
        "sg": 1.4
    },
    "bromine":{
        "sg": 3.1
    }
}

let materialProperties = {
    "aluminum alloy": {
        "sg": 2.7,
        "Es": [70,80],
        "sults": [310, 550],
        "linexp": 23,
        "nud": 0.33
    },
    "steel alloy": {
        "sg": 7.7,
        "Es": [195,210],
        "sults": [550, 1400],
        "linexp": 12,
        "nud": 0.30
    },
    "copper": {
        "sg": 7.7,
        "Es": [195,210],
        "sults": [550, 1400],
        "linexp": 12,
        "nud": 0.30
    },
    "brass": {
        "sg": 8.4,
        "Es": [96,110],
        "sults": [300, 590],
        "linexp": 20,
        "nud": 0.34
    }
}

const getMaterialProperties = (material, unitSel)=> {
    let mat = materialProperties[material];
    E = math.randomInt(mat.Es[0],mat.Es[1]);
    sult = math.randomInt(mat.sults[0], mat.sults[1]);
    nud = mat.nud;
    G = E/(2*(1+nud));
    fshear = math.random(0.5, 0.7);
    if (unitSel === 0) {
        tult = math.round(fshear*sult);
    }
    else {
       E = math.round(E*145037.737734*1e-6);
       G = math.round(G*145037.737734*1e-6);
       sult = math.round(sult*145.037738*1e-3);
       tult = math.round(fshear*sult);
    }

    materialProperties[material].E = E; // Young's modulus
    materialProperties[material].G = G; // shear modulus
    materialProperties[material].sult = sult; // yield
    materialProperties[material].tult = tult; //shear yield
    return mat;
}


module.exports = {
    fluidProperties,
    materialProperties,
    getMaterialProperties
}