import random
import prairielearn as pl

def generate(data):
    ureg = pl.get_unit_registry()

    # Dynamic Parameter Selection
    # Choosing between SI and USCS units for the length and contraction.
    length_si = (random.uniform(2.0, 10.0), '\\mathrm{m}')  # meters
    length_uscs = (random.uniform(6.56, 32.8), '\\mathrm{ft}')  # feet
    contraction_si = (random.uniform(0.001, 0.01), '\\mathrm{cm}')  # centimeters
    contraction_uscs = (random.uniform(0.01, 0.1), '\\mathrm{in}')  # inches

    # Randomly choose unit system
    if random.choice(['SI', 'USCS']) == 'SI':
        length_value, length_unit = length_si
        contraction_value, contraction_unit = contraction_si
    else:
        length_value, length_unit = length_uscs
        contraction_value, contraction_unit = contraction_uscs

    # Calculate strain (unitless) and percentage strain
    strain = contraction_value / (length_value * 100)
    percent_strain = strain * 100
    
    data['params']['length'] = length_value
    data['params']['unitsDist'] = length_unit
    
    data['params']['contraction'] = contraction_value
    data['params']['unitsDistSmall'] = contraction_unit
    
    data['correct_answers']['strain'] = round(strain, 3)
    data['correct_answers']['percent_strain'] = round(percent_strain, 3)

    data['nDigits'] = 3
    data['sigfigs'] = 3