import random
import prairielearn as pl


# Utility function to generate random numbers within a range
# and convert them to the relevant unit system
# unitsDist can be 'm' (meters) or 'ft' (feet)
# unitsForce can be 'N' (newtons) or 'lbf' (pounds-force)

def generate_random_value(min_val, max_val, unit):
    value = random.uniform(min_val, max_val)
    return value * pl.get_unit_registry()[unit]


def generate(data):
    # Define parameter ranges (within realistic limits)
    # For example:
    delta_range_m = (0.01, 1.0)  # in meters
    delta_range_ft = (0.03, 3.0) # in feet
    force_range_N = (50, 1000)   # in newtons
    force_range_lbf = (10, 200)  # in pounds-force

    # Randomly select a unit system: True for SI, False for USCS
    use_SI = random.choice([True, False])

    # Generate initial elongation and force in the appropriate units
    if use_SI:
        unitsDist = 'm'
        unitsForce = 'N'
        delta1 = generate_random_value(*delta_range_m, unitsDist)
        forceF = generate_random_value(*force_range_N, unitsForce)
    else:
        unitsDist = 'ft'
        unitsForce = 'lbf'
        delta1 = generate_random_value(*delta_range_ft, unitsDist)
        forceF = generate_random_value(*force_range_lbf, unitsForce)

    # Assume linear behavior, so force is proportional to elongation
    # Select a target elongation (delta2) randomly within the same range as delta1
    delta2 = generate_random_value(delta_range_m[0] if use_SI else delta_range_ft[0],
                                  delta_range_m[1] if use_SI else delta_range_ft[1],
                                  unitsDist)

    # Calculate the new force for delta2 proportionally
    force_delta2 = forceF * (delta2 / delta1)

    # Convert everything to a string for output and preparation
    delta1_str = str(delta1)
    forceF_str = str(forceF)
    delta2_str = str(delta2)
    force_delta2_str = str(force_delta2)

    # Assign generated parameters to the data
    data['params']['delta1'] = delta1.magnitude
    data['params']['unitsDist'] = unitsDist
    data['params']['forceF'] = forceF.magnitude
    data['params']['unitsForce'] = unitsForce
    data['params']['delta2'] = delta2.magnitude

    # Set the correct answer for the question
    data["correct_answers"]["force_delta2"] = force_delta2.magnitude
