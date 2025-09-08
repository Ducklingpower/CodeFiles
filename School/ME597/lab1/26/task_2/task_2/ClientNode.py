#!/usr/bin/env python3

import rclpy
from rclpy.node import Node

from task_2_interfaces.srv import JointState


class ClientNode(Node):
    
    def __init__(self):
        super().__init__("ClientNode")
        self.client = self.create_client(JointState,"joint_service")

        while not self.client.wait_for_service(timeout_sec=2.0):                # LOGGING WAITING FOR SERVICE SO i KNOW ITS NOT UP AND i WONT GET AN ERROR
            self.get_logger().info("waiting for service to be active")

        request = JointState.Request() ## filling in client request info 
        request.x = 1.0
        request.y = 2.0
        request.z = -10.0

        self.future = self.client.call_async(request) # sending the request and using future as a place holder until my code arrives
        self.get_logger().info(f"sent x = {request.x}, y = {request.y}, z = {request.z}")# logging request


def main(args=None):
    rclpy.init(args=args)

    node = ClientNode()
    
    rclpy.spin_until_future_complete(node, node.future) # keeps node spinning until future is filled with the requested data
    response = node.future.result()
    node.get_logger().info(f"service said: valid={response.valid}") ## output the results of future


    rclpy.shutdown()



