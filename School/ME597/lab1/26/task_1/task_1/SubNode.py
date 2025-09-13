#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from std_msgs.msg import Float64


class ReceiverNode(Node):

    def __init__(self):
        super().__init__("listener")
        self.sub = self.create_subscription(Float64,"my_first_topic",self.message_callback,10)
    
    def message_callback(self, msg: Float64):
        n1 = msg.data
        n2 = msg.data * 2
        self.get_logger().info(f"Subscriber heard: {n1:.2f} seconds and {n2:.2f} 2x seconds")



def main(args=None):
    rclpy.init(args=args)

    node = ReceiverNode()
    rclpy.spin(node)

    rclpy.shutdown()
