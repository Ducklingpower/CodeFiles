#!/usr/bin/env python3

import rclpy
from rclpy.node import Node

from task_2_interfaces.srv import JointState
import sys


class ClientNode(Node):
    
    def __init__(self):
        super().__init__("client")
        self.client = self.create_client(JointState, "joint_service")

        while not self.client.wait_for_service(timeout_sec=2.0):
            self.get_logger().info("waiting for service to be active")

        self.req = JointState.Request()
        
    def send_request(self,x,y,z):
        self.req.x = x
        self.req.y = y
        self.req.z = z

        self.future = self.client.call_async(self.req)
        rclpy.spin_until_future_complete(self, self.future)
        return self.future.result()

        

        
        



def main(args=None):
    rclpy.init(args=args)
    node = ClientNode()

    response = node.send_request(float(sys.argv[1]),float(sys.argv[2]),float(sys.argv[3]))

    node.get_logger().info(f"service said: valid={response.valid}")

    node.destroy_node()
    rclpy.shutdown()


if __name__ == "__main__":
    main()


################

