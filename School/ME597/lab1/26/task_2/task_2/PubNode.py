#!/usr/bin/env python3
import rclpy 
from rclpy.node import Node

from task_2_interfaces.msg import JointData  # import our JointData.msg custom interface from task_2_interfaces
from geometry_msgs.msg import Point32        # since Point32 tpye is used in the custome .msg interface


class MyNode(Node):

    def __init__(self):
        super().__init__("PublisherNode")
        self.pub = self.create_publisher(JointData,"joint_topic",10)
        self.create_timer(1,self.timerCallback)

    def timerCallback(self):

        message = JointData() # creating a message and filing in the message with the neccissary inputs for the topic type      

        message.center = Point32()
        message.center.x = 1.0
        message.center.y = 2.0
        message.center.z = 3.0

        message.vel = 10.0

        self.pub.publish(message)
        self.get_logger().info(f"logging input for topic:x = {message.center.x}, y = {message.center.y}, z = {message.center.z} and Vel = {message.vel}") #logging data

def main(args=None):
    rclpy.init(args=args)

    node = MyNode()
    rclpy.spin(node)

    rclpy.shutdown()