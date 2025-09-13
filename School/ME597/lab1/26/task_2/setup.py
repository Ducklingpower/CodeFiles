from setuptools import find_packages, setup
from glob import glob

package_name = 'task_2'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']), #Added tis becouse of custom interfaces

        ('share/task_2', ['package.xml']),# added these lines for the launch file access
        ('share/task_2/launch', glob('launch/*launch.py')),  

     
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
            "talker = task_2.PubNode:main",
            "listener = task_2.SubNode:main",
            "service = task_2.ServNode:main",
            "client = task_2.ClientNode:main",
        ],
    },
)
