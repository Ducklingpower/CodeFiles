import random
import prairielearn as pl


# Define ranges for each parameter
OUTSIDE_DIAMETER_RANGE = (0.1, 0.5)  # in meters
INSIDE_DIAMETER_RANGE = (0.05, 0.4)   # in meters
LENGTH_RANGE = (1.0, 10.0)            # in meters
LOAD_RANGE = (1000, 10000)            # in Newtons
SHORTENING_RANGE = (0.001, 0.01)     # in meters


# Define units for each property
UNITS_DIAMETER = ["m", "cm"]
UNITS_LENGTH = ["m", "cm"]
UNITS_LOAD = ["N", "kN"]
UNITS_SHORTENING = ["m", "cm"]


# Random unit selection function
def select_units(units_list):
    return random.choice(units_list)


# Function to convert values between unit systems (assuming SI for simplicity)
def convert_units(value, from_unit, to_unit):
    ureg = pl.get_unit_registry()
    quantity = value * ureg(from_unit)
    quantity.ito(to_unit)
    return quantity.magnitude


# Main generate function
def generate(data):
    ureg = pl.get_unit_registry()

    # Randomly generate input parameters and units
    outside_diameter = random.uniform(*OUTSIDE_DIAMETER_RANGE)
    inside_diameter = random.uniform(*INSIDE_DIAMETER_RANGE)
    length = random.uniform(*LENGTH_RANGE)
    load = random.uniform(*LOAD_RANGE)
    shortening = random.uniform(*SHORTENING_RANGE)

    # Select units
    units_diameter = select_units(UNITS_DIAMETER)
    units_length = select_units(UNITS_LENGTH)
    units_load = select_units(UNITS_LOAD)
    units_shortening = select_units(UNITS_SHORTENING)

    # Convert diameters, length, load, and shortening to selected units
    converted_outside_diameter = convert_units(outside_diameter, "m", units_diameter)
    converted_inside_diameter = convert_units(inside_diameter, "m", units_diameter)
    converted_length = convert_units(length, "m", units_length)
    converted_load = convert_units(load, "N", units_load)
    converted_shortening = convert_units(shortening, "m", units_shortening)

    # Calculate the cross-sectional area (π/4 * (Do^2 - Di^2))
    cross_sectional_area = (3.14159 / 4) * (outside_diameter**2 - inside_diameter**2) * ureg.m**2
    # Convert load to base unit (N) for stress calculation
    load_quantity = load * ureg(newton)
    # Calculate compressive stress (F / A)
    compressive_stress = load_quantity / cross_sectional_area

    # Populate data with parameters and solutions
    data["params"] = {
        "outside_diameter": round(converted_outside_diameter, 3),
        "inside_diameter": round(converted_inside_diameter, 3),
        "length": round(converted_length, 1),
        "load": round(converted_load, 0),
        "shortening": round(converted_shortening, 4),
        "unitsDiameter": units_diameter,
        "unitsLength": units_length,
        "unitsLoad": units_load,
        "unitsShortening": units_shortening
    }

    data["correct_answers"]["compressive_stress"] = round(compressive_stress.magnitude, 3)

    data["nDigits"] = 3
    data["sigfigs"] = 3

    return data
