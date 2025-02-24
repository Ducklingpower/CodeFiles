import random
import prairielearn as pl


def generate(data):
    ureg = pl.get_unit_registry()

    # 1. Dynamic Parameter Selection
    units_force = ['N', 'lb']  # Newton and pound
    units_length = ['m', 'ft']  # Meter and foot
    
    # Randomly select units
    selected_force_unit = random.choice(units_force)
    selected_length_unit = random.choice(units_length)
    selected_moment_unit = 'Nm' if selected_force_unit == 'N' and selected_length_unit == 'm' else 'lb*ft'

    # 2. Value Generation
    force = random.uniform(5, 100)  # Random force value between 5 and 100
    l1 = random.uniform(0.1, 2)  # Effective length between 0.1 and 2 meters or feet
    l2 = random.uniform(0.1, l1)  # New length less than or equal to l1

    # 3. Solution Synthesis
    
    # Convert generated values to correct units using pint
    force_quantity = force * ureg(selected_force_unit)
    l1_quantity = l1 * ureg(selected_length_unit)
    l2_quantity = l2 * ureg(selected_length_unit)
    
    # Calculate moment
    moment = force_quantity * l1_quantity  # Moment = Force * Lever arm distance
    
    # Calculate required force for new moment
    required_force = moment / l2_quantity

    # Set data parameters
    data['params']['force'] = round(force, 3)
    data['params']['unitsForce'] = selected_force_unit
    data['params']['l1'] = round(l1, 3)
    data['params']['unitsLength'] = selected_length_unit
    data['params']['l2'] = round(l2, 3)
    data['params']['unitsMoment'] = selected_moment_unit

    # Set correct answers values
    data['correct_answers']['moment'] = {
        'value': round(moment.to(selected_moment_unit).magnitude, 3),
        'unit': selected_moment_unit
    }

    data['correct_answers']['requiredForce'] = {
        'value': round(required_force.to(selected_force_unit).magnitude, 3),
        'unit': selected_force_unit
    }

    data['nDigits'] = 3  # Number of digits after the decimal point
    data['sigfigs'] = 3  # Significant figures for final answers

    return data