import prairielearn as pl
import numpy as np


def generate(data):
    ureg = pl.get_unit_registry()

    # 1. Dynamic Parameter Selection
    # Randomly select unit systems for different parameters
    units_diameter_options = ['meter', 'inch']
    units_load_options = ['newton', 'pound_force']
    units_length_options = ['meter', 'inch']
    units_modulus_options = ['pascal', 'psi']

    units_diameter = np.random.choice(units_diameter_options)
    units_load = np.random.choice(units_load_options)
    units_length = np.random.choice(units_length_options)
    units_modulus = np.random.choice(units_modulus_options)

    # 2. Value Generation
    internal_diameter = np.random.uniform(0.05, 0.2) * ureg(units_diameter)
    external_diameter = np.random.uniform(0.25, 0.5) * ureg(units_diameter)
    load = np.random.uniform(1000, 5000) * ureg(units_load)
    length = np.random.uniform(1, 5) * ureg(units_length)
    modulus_elasticity = np.random.uniform(70e9, 120e9) * ureg(units_modulus)

    # Convert modulus of elasticity to the correct units for calculation
    if units_modulus == 'psi':
        modulus_elasticity = modulus_elasticity.to(ureg.pascals)

    # 3. Solution Synthesis
    # Calculate the axial contraction \( \Delta L \)
    A = np.pi * (external_diameter**2 - internal_diameter**2) / 4  # cross-sectional area
    delta_L = (load * length / (A * modulus_elasticity)).to(ureg.meter)

    # Preparing the output data
    data["params"] = {
        "internalDiameter": internal_diameter.magnitude,
        "externalDiameter": external_diameter.magnitude,
        "unitsDiameter": units_diameter,
        "load": load.magnitude,
        "unitsLoad": units_load,
        "length": length.magnitude,
        "unitsLength": units_length,
        "modulusElasticity": modulus_elasticity.magnitude,
        "unitsModulus": "Pa"  # Always output in Pascals for clarity
    }

    data["correct_answers"] = {
        "contraction": round(delta_L.magnitude, 3)
    }

    data["nDigits"] = 3
    data["sigfigs"] = 3
    
    return data
