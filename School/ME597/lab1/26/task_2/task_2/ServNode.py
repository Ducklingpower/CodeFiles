#!/usr/bin/env python3
import rclpy
from rclpy.node import Node 

from task_2_interfaces.srv import JointState # importing Joint states file to use custome interfaces

class ServerNode(Node):

    def __init__(self):
        super().__init__("ServerNode")
        self.serv = self.create_service(JointState,"joint_service",self.DataRequest)

    def DataRequest(self, request, response): #ending off working on call back

        total = request.x + request.y + request.z
        
        if total >= 0:
            response.valid = True
        else:
            response.valid = False

        return response




def main(args=None):
    rclpy.init(args=args)

    node = ServerNode()
    rclpy.spin(node)

    rclpy.shutdown()



