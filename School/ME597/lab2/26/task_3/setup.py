from setuptools import find_packages, setup
from glob import glob

package_name = 'task_3'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),


          ('share/task_3', ['package.xml']),# added these lines for the launch file access
        ('share/task_3/launch', glob('launch/*launch.py')),  
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='elijah',
    maintainer_email='elijahjacobperez@gmail.com',
    description='TODO: Package description',
    license='Apache-2.0',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            "pid_speed_controller = task_3.pid_controller:main"
        ],
    },
)
