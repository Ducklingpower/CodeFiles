{"params": {
        "area": {
            "value_si": 0.001,  # m^2
            "value_uscs": 1.55,  # in^2
        },
        "unitsArea": {
            "si": "m^2",
            "uscs": "in^2",
        },
        "forceF": {
            "value_si": 1000,  # Newton
            "value_uscs": 225,  # lbf
        },
        "unitsForce": {
            "si": "N",
            "uscs": "lbf",
        }
    },
    'correct_answers': {
        'stress_si': round(1000 / 0.001, 3),  # Stress in N/m^2 or Pascal
        'stress_uscs': round(225 / 1.55, 3),  # Stress in psi
    },
    'nDigits': 3,
    'sigfigs': 3
}