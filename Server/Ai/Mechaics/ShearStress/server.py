import prairielearn as pl
import random

def generate(data):
    ureg = pl.get_unit_registry()

    # Randomly generate dimensions in mm
    length = random.uniform(50, 200)  # length L in mm
    width = random.uniform(50, 200)   # width W in mm
    height = random.uniform(10, 50)   # height H in mm
    force = random.uniform(10, 100)   # force F in N
    displacement = random.uniform(0.1, 2)  # displacement delta in mm

    # Calculate shear stress and shear strain
    area = length * width * (ureg.mm ** 2)  # Area in mm^2
    force_newtons = force * ureg.newton
    shear_stress = (force_newtons / area).to(ureg.Pa)  # Shear stress in Pa

    shear_strain = (displacement / height)  # Shear strain (dimensionless)

    # Store original and calculated values
    data['params'] = {
        'length': length,
        'width': width,
        'height': height,
        'force': force,
        'displacement': displacement,
        'unitsStress': 'Pa'
    }

    data['correct_answers']['shearStress'] = round(shear_stress.magnitude, 3)
    data['correct_answers']['shearStrain'] = round(shear_strain, 3)

    data['nDigits'] = 3  # Number of digits after the decimal point
    data['sigfigs'] = 3  # Number of significant figures to use in the answer

    return data