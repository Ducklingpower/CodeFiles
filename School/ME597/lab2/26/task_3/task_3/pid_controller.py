#!/usr/bin/env python3
import rclpy
import math
from rclpy.node import Node
from sensor_msgs.msg import LaserScan
from geometry_msgs.msg import Twist



class MyNode(Node):

    

    def __init__(self):
        super().__init__("pid_speed_controller")

        #params

        self.freq = 10 # hz
        self.ref = 0.35
        self.last_error = 0
        self.I = 0
        self.I_last= 0

        self.kp = 0.15
        self.ki = 0.01
        self.kd = 0.022

        self.scan = None

        self.get_clock().now().nanoseconds*1e-9


        self.sub = self.create_subscription(LaserScan,"/scan",self.callback,10) # subscribing to get latest scan info
        self.create_timer(1/self.freq,self.PID)

        self.pub_U = self.create_publisher(Twist,"/cmd_vel",10)



    def callback(self, Data: LaserScan): # call back to abtin the last scan 
        self.scan = Data


    def PID(self):

        if self.scan is None:  #making sure scan is not empty
            return
    
        # optain front forward range
        self.front_dist = self.scan.ranges[0]

        ## PID calcs-----------------------

        # error
        self.error = -(self.ref)+(self.front_dist)


        # dt______________---
       


        dt = 0.1 # for now 

        self.D = (self.error-self.last_error)/(dt)
        self.I = self.error*dt + self.I_last
        self.P = self.error

        U = (self.kp*self.P + self.ki*self.I + self.kd*self.D)

        if math.isnan(U):
           #print("I see nan")
           V = 0
        else:
            V =  max(-0.15,min(0.15,U))

        #print(f"requested = {U}, filtered = {V}, error = {self.error}")
      
        # reset
        self.last_error = self.error

       
        msg = Twist()
        msg.linear.x = float(V)
        msg.linear.y = float(0.0)
        msg.linear.z = float(0.0)

        msg.angular.x = float(0.0)
        msg.angular.y = float(0.0)
        msg.angular.z = float(0.0)

        
        self.pub_U.publish(msg)


def main(args=None):
    rclpy.init(args=args)

    node = MyNode()
    rclpy.spin(node)

    rclpy.shutdown()




