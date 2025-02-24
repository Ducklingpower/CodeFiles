import prairielearn as pl
import sympy as sp


def generate(data):
    ureg = pl.get_unit_registry()

    F1 = pl.uniform(100, 1000) * ureg.newton  # Force generated in N
    theta1 = pl.uniform(30, 60)  # Angle in degrees
    theta2 = pl.uniform(30, 60)  # Angle in degrees

    # Convert angles to radians
    theta1_rad = sp.rad(theta1)
    theta2_rad = sp.rad(theta2)

    # Define symbolic variables for tensions
    T1, T2 = sp.symbols('T1 T2', real=True, positive=True)

    # Set up equations for equilibrium
    eq1 = sp.Eq(T1 * sp.cos(theta1_rad) + T2 * sp.cos(theta2_rad), F1)
    eq2 = sp.Eq(T1 * sp.sin(theta1_rad), T2 * sp.sin(theta2_rad))

    # Solve the system of equations
    solution = sp.solve((eq1, eq2), (T1, T2))

    T1_value = solution[T1].evalf()
    T2_value = solution[T2].evalf()

    # Store the correct answers
    data['correct_answers']['Tension1'] = pl.po_quantity(T1_value, digits=3)
    data['correct_answers']['Tension2'] = pl.po_quantity(T2_value, digits=3)

    # Store parameters for later visualization
    data['params']['F1'] = f'{F1.magnitude:.0f}'  # Use a whole number format
    data['params']['unitsForce'] = str(F1.units)
    data['params']['theta1'] = f'{theta1:.0f}'
    data['params']['theta2'] = f'{theta2:.0f}'