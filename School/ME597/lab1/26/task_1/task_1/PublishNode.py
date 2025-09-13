#!/usr/bin/env python3
import rclpy
from rclpy.node import Node # importing node since I will use the node class 
from std_msgs.msg import Float64

class MyNode(Node):   #I just defined a cass called MyNode that inherits ROS2 node funcinonalities

    def __init__(self):
        super().__init__("talker")
        self.freq = 10
        self.n = 0.0
        self.pub = self.create_publisher(Float64,"my_first_topic",10) # creating topic and publishing to my first topic
        self.create_timer(1.0/self.freq,self.timer_callback) # this will run the timer_callback function every second

    def timer_callback(self):
        # self.get_logger().info("I have been active for " + str(self.n) + " seconds")
        message = Float64() # message type
        message.data = float(self.n) # populating message
        self.n +=1/self.freq
        self.pub.publish(message)

        

def main(args=None):
    rclpy.init(args=args) # this initializes ross two communications

    node = MyNode() # activating the class called MyNode
    rclpy.spin(node) # keep node alive and running

    node.destroy_node()
    rclpy.shutdown()   # shuts downs node



#if __name__ == "__main__": # this will allow us to run the script from terminal
#    main()

