import random
import prairielearn as pl


def generate(data):
    # Initialize the unit registry
    ureg = pl.get_unit_registry()

    # Randomly choose between SI and USCS units
    use_si = random.choice([True, False])

    if use_si:
        # SI units
        data['params']['unitsDist'] = 'm'
        data['params']['unitsForce'] = 'N'
        distance_conversion = ureg.meter
        force_conversion = ureg.newton
        max_length = 10  # meters
        max_force = 1000  # newtons
    else:
        # USCS units
        data['params']['unitsDist'] = 'ft'
        data['params']['unitsForce'] = 'lbf'
        distance_conversion = ureg.foot
        force_conversion = ureg.pound_force
        max_length = 30  # feet
        max_force = 2000  # pounds

    # Generate random values within the specified ranges
    data['params']['length'] = random.uniform(0.5 * max_length, max_length)
    data['params']['force1'] = random.uniform(0.1 * max_force, max_force)
    data['params']['force2'] = random.uniform(0.1 * max_force, max_force)
    data['params']['distance1'] = random.uniform(0, 0.5 * data['params']['length'])
    data['params']['distance2'] = random.uniform(0, data['params']['length'])

    # Convert values with units
    L = data['params']['length'] * distance_conversion
    F1 = data['params']['force1'] * force_conversion
    F2 = data['params']['force2'] * force_conversion
    d1 = data['params']['distance1'] * distance_conversion
    d2 = data['params']['distance2'] * distance_conversion

    # Calculate reactions at A and B
    # Using the moment equilibrium about B: sum(M_B) = 0 => F1 * d1 + F2 * d2 = R_a * L
    Ra = (F1 * d1 + F2 * d2) / L
    # Using vertical force equilibrium: sum(F_vertical) = 0 => R_a + R_b = F1 + F2
    Rb = F1 + F2 - Ra

    # Store answers
    data['correct_answers']['reactionA'] = float(Ra.to(ureg.newton if use_si else ureg.pound_force).magnitude)
    data['correct_answers']['reactionB'] = float(Rb.to(ureg.newton if use_si else ureg.pound_force).magnitude)

    # Specify number of digits/significant figures in the final answers
    data['nDigits'] = 3
    data['sigfigs'] = 3

    return data