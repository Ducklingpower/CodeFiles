import prairielearn as pl
import numpy as np
from scipy.constants import pi


def generate(data):
    # Dynamic Parameter Selection
    use_SI = np.random.choice([True, False])

    # Randomly generate parameters
    if use_SI:
        force = np.random.uniform(20, 100)  # Force in newtons (N)
        diameter = np.random.uniform(200, 500)  # Diameter in millimeters (mm)
        revolutions = np.random.randint(10, 50)  # Number of revolutions
    else:
        # For USCS system (though not calculated in USCS for this problem)
        force = np.random.uniform(4, 20)  # Force in pound-force (lbf)
        diameter = np.random.uniform(8, 20)  # Diameter in inches (not used here directly)
        revolutions = np.random.randint(10, 50)

    # Convert diameter from mm to meters (m) when using SI
    diameter_meters = diameter / 1000

    # Calculate work done in Joules
    # Work = force * distance, distance for 1 revolution = pi * diameter_meters
    distance = revolutions * pi * diameter_meters
    work_done = force * distance  # Work in Joules

    # Populate the problem data
    data['params']['force'] = force
    data['params']['diameter'] = diameter
    data['params']['revolutions'] = revolutions

    # Set correct answers with specified significant figures
    data['correct_answers']['workDone'] = "{:.3g}".format(work_done)
    data['answers_display'] = 3  # Number of displayed significant figures

    return data