from sympy import symbols, solve, Eq
import random


# Define the function to generate a problem instance
def generate():
    # Parameter Definitions: placeholders for the problem
    T_free = symbols('T_free')  # stress-free temperature
    sigma = symbols('sigma')  # critical stress
    E = symbols('E')  # modulus of elasticity
    alpha = symbols('alpha')  # thermal expansion coefficient
    
    # Dynamic Parameter Selection:
    # Generate parameters within realistic ranges randomly
    tempFree = random.randint(-40, 40)  # degrees Celsius
    stress = random.randint(100, 500)  # MPa
    modulusElasticity = random.uniform(1.5, 2.5)  # x 10^11 Pa
    thermalExpansionCoeff = random.uniform(10, 15)  # x 10^-6 /°C

    # Calculation of buckling temperature
    # Stress equation: sigma = E * alpha * (T_buckling - T_free)
    T_buckling = symbols('T_buckling')
    equation = Eq(sigma, E * alpha * (T_buckling - T_free))
    
    # Solve the equation for T_buckling
    buckling_temp_solution = solve(equation, T_buckling)[0].subs({
        sigma: stress * 1e6,  # Convert MPa to Pa
        E: modulusElasticity * 1e11,  # Pa
        alpha: thermalExpansionCoeff * 1e-6,  # °C^-1
        T_free: tempFree
    })
    
    correct_answer = round(float(buckling_temp_solution), 3)  # Correct answer with 3 significant figures
    
    return {
        'params': {
            'tempFree': tempFree,
            'unitsTemp': '°C',
            'stress': stress,
            'unitsStress': 'MPa',
            'modulusElasticity': modulusElasticity,
            'unitsModulus': 'Pa',
            'thermalExpansionCoeff': thermalExpansionCoeff,
            'unitsAlpha': '/°C',
        },
        'correct_answers': {
            'tempBuckling': correct_answer
        },
        'nDigits': 3,  # Number of digits after the decimal
        'sigfigs': 3   # Number of significant figures
    }