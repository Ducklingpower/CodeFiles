import random

def generate(data):
    # Generate two random forces between 100 and 500 kN (inclusive)
    force1 = random.randint(100, 500)
    force2 = random.randint(100, 500)

    # Store the forces in data['params']
    data["params"]["force1"] = force1
    data["params"]["force2"] = force2

    # Calculate the resultant force when in the same direction
    resultant_same_direction = force1 + force2
    
    # Calculate the resultant force when in opposite directions
    resultant_opposite_direction = abs(force1 - force2)

    # Put the resultant forces into data['correct_answers']
    data["correct_answers"]["resultant_same_direction"] = round(resultant_same_direction, 3)
    data["correct_answers"]["resultant_opposite_direction"] = round(resultant_opposite_direction, 3)
