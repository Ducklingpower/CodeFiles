# service_launch.py

from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():
    return LaunchDescription([

          Node(
            package = "task_2",
            executable = "service",
            name = "ServerNode",
        ),

        Node(
            package = "task_2",
            executable= "talker",
            name = "PublisherNode",
        ),

        Node(
            package = "task_2",
            executable = "listener",
            name = "SubscriberNode",
            ),

    

      

    ])

        