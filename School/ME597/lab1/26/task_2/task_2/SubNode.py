#!/usr/bin/env python3
import rclpy
from rclpy.node import Node 

from task_2_interfaces.msg import JointData
from geometry_msgs.msg import Point32


class SubscriberNode(Node):

    def __init__(self):
        super().__init__("listener")
        self.sub = self.create_subscription(JointData,"joint_topic",self.CallBack,10)

    def CallBack(self,message: JointData):
        x = message.center.x
        y = message.center.y
        z = message.center.z
        vel = message.vel

        self.get_logger().info(f"Sub node hears: x = {x}, y ={y}, z = {z}, and vel = {vel}")
        

def main(args=None):
    rclpy.init(args=args)

    node = SubscriberNode()
    rclpy.spin(node)

    rclpy.shutdown()
