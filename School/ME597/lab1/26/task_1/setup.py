from setuptools import find_packages, setup
from glob import glob

setup(
    name="task_1",
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/task_1']),

        ('share/task_1', ['package.xml']),# added these lines for the launch file access
        ('share/task_1/launch', glob('launch/*launch.py')),   
    ],

    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='elijah',
    maintainer_email='elijahjacobperez@gmail.com',
    description='TODO: Package description',
    license='TODO: License declaration',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            "talker = task_1.PublishNode:main",
            "listener = task_1.SubNode:main"
        ],
    },
)
