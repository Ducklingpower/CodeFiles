import random
import prairielearn as pl


def generate(data):
    # Let's assume params.moment, params.force1, and params.force2 are dynamically generated from within the system.
    # These values would typically be specified, allowing the engineer to test multiple scenarios interactively.
    moment_scenario = random.uniform(50, 200)  # Moment in N*m
    force1_scenario = random.uniform(10, 100)  # Force in N
    force2_scenario = random.uniform(0.1, 1.0)  # Force in kN

    # Update the parameter with random values
    data["params"]["moment"] = moment_scenario
    data["params"]["force1"] = force1_scenario
    data["params"]["force2"] = force2_scenario

    # Effective lengths calculations
    length_handle_f1 = moment_scenario / force1_scenario  # in meters (since force1 is in N and moment in N*m)
    length_handle_f2 = moment_scenario / (force2_scenario * 1000)  # in meters (since force2 is in kN)

    # Update correct answers
    data["correct_answers"]["lengthHandleF1"] = length_handle_f1
    data["correct_answers"]["lengthHandleF2"] = length_handle_f2

    return data