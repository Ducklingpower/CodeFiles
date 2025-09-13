#!/usr/bin/env python3
import rclpy
from rclpy.node import Node 

from task_2_interfaces.srv import JointState # importing Joint states file to use custome interfaces

class ServerNode(Node):

    def __init__(self):
        super().__init__("service")
      
        self.serv = self.create_service(JointState, "joint_service", self.data_request)

    def data_request(self, request, response):

        total = float(request.x) + float(request.y) + float(request.z)



        
        response.valid = (total >= 0.0)
        
        #self.get_logger().info(
        #    f"[ServerNode] request=({request.x:.3f}, {request.y:.3f}, {request.z:.3f}) "
        #    f"total={total:.3f} -> valid={response.valid}"
        #)

        return response
    




def main(args=None):
    rclpy.init(args=args)

    node = ServerNode()
    rclpy.spin(node)

    rclpy.shutdown()



