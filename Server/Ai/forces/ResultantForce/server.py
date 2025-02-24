import math
import random

def generate():
    # 1. Dynamic Parameter Selection:
    # Here we assume the forces are selected in SI units (Newtons)
    
    # Define static ranges for force magnitudes and angle
    force1_magnitude_range = (10, 100)  # N
    force2_magnitude_range = (10, 100)  # N
    angle_range = (0, 180)  # degrees

    # Randomly generate parameter values
    force1 = random.uniform(*force1_magnitude_range)
    force2 = random.uniform(*force2_magnitude_range)
    angle = random.uniform(*angle_range)

    # 2. Value Generation:
    # Generate original values (here no explicit conversions necessitated)

    # Compute the resultant force using vector addition
    resultant_magnitude = math.sqrt(force1**2 + force2**2 + 2*force1*force2*math.cos(math.radians(angle)))
    resultant_direction = math.degrees(math.atan2(
        force2 * math.sin(math.radians(angle)),
        force1 + force2 * math.cos(math.radians(angle))
    ))

    # 3. Solution Synthesis:
    # Using the calculated resultant and direction

    return {
        'params': {
            'force1': round(force1, 2), 
            'force2': round(force2, 2),
            'angle': round(angle, 2),
        },
        'correct_answers': {
            'resultantMagnitude': round(resultant_magnitude, 3),
            'resultantDirection': round(resultant_direction, 3),
        },
        'nDigits': 3,
        'sigfigs': 3
    }

# Example usage:
result = generate()
print(result)