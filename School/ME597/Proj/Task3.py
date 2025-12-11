#!/usr/bin/env python3

#ros2 launch turtlebot3_gazebo navigator.launch.py spawn_objects:=true
import rclpy
from rclpy.node import Node
from sensor_msgs.msg import Image as ImageCV2 # To use a ROS2 image messagex
from sensor_msgs.msg import LaserScan
from rclpy.time import Time

# for the subscriber 
import math


from geometry_msgs.msg import Twist
import numpy as np
from cv_bridge import CvBridge   # add this import at the top
from geometry_msgs.msg import Pose2D
import cv2

## 



import sys
import os

import time

# ros2 node imports


from nav_msgs.msg import Path
from geometry_msgs.msg import Point

from geometry_msgs.msg import PoseStamped, PoseWithCovarianceStamped, Pose, Twist
from std_msgs.msg import Float32
from nav_msgs.msg import Odometry



# controls impoers
import control as ct


# ap processing iports
import heapq

from pathlib import Path as FsPath


from PIL import Image, ImageOps
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import yaml
import pandas as pd
from copy import copy, deepcopy
import time
import os
from ament_index_python.packages import get_package_share_directory
from graphviz import Graph


############################################################### All classes ##########################################################################################


class Map():
    def __init__(self, map_name):
        self.map_im, self.map_df, self.limits = self.__open_map(map_name)
        self.image_array = self.__get_obstacle_map(self.map_im, self.map_df)

    def __repr__(self):
        fig, ax = plt.subplots(dpi=150)
        ax.imshow(self.image_array, extent=self.limits, cmap=cm.gray)
        ax.plot()
        return ""

    def __open_map(self, map_name):
     
        yaml_filename = f"{map_name}.yaml"
   
        pkg_share = get_package_share_directory('turtlebot3_gazebo')
        maps_dir  = os.path.join(pkg_share, 'maps')
        yaml_path = os.path.join(maps_dir, yaml_filename)

        f = open(yaml_path, 'r')
        map_df = pd.json_normalize(yaml.safe_load(f))

        image_filename = map_df.image[0]
        image_path = os.path.join(maps_dir, image_filename)
        print("Looking for image:", image_path)

        im = Image.open(image_path)####
        #size = 200, 200
        #im.thumbnail(size)
        im = ImageOps.grayscale(im)######

        xmin = float(map_df.origin[0][0])#####
        ymin = float(map_df.origin[0][1])#####
        res  = float(map_df.resolution[0])#####

        xmax = xmin + im.size[0] * res
        ymax = ymin + im.size[1] * res

        return im, map_df, [xmin, xmax, ymin, ymax]
    
    def __get_obstacle_map(self, map_im, map_df):
        gray = np.array(self.map_im, dtype=np.uint8)

     
        occ_t  = float(self.map_df.occupied_thresh[0])  
        free_t = float(self.map_df.free_thresh[0])      
        negate = int(self.map_df.negate[0]) if hasattr(self.map_df, "negate") else 0

        
        if negate == 1:
            gray = 255 - gray

        occ_px  = int(round(occ_t  * 255.0))
        free_px = int(round(free_t * 255.0))


        occ = np.zeros_like(gray, dtype=np.uint8)
        occ[gray <= occ_px] = 255                               
        occ[(gray > occ_px) & (gray < free_px)] = 255           
        occ[gray >= free_px] = 0                                

        # Flip once so row 0 
        occ = np.flipud(occ)

        return occ



    def resolution(self) -> float:
        return float(self.map_df.resolution[0])

    def width(self) -> int:   # columns x/j
        return int(self.map_im.size[0])

    def height(self) -> int:  # rows y/i
        return int(self.map_im.size[1])

    def origin_xy(self):
        return float(self.map_df.origin[0][0]), float(self.map_df.origin[0][1])

    def grid_to_world(self, i: int, j: int):
        ox, oy = self.origin_xy()
        r = self.resolution()
        x = ox + (j + 0.5) * r
        y = oy + (i + 0.5) * r
        return float(x), float(y)

    def world_to_grid(self, x: float, y: float):
        ox, oy = self.origin_xy()
        r = self.resolution()
        j = int(round((x - ox) / r))
        i = int(round((y - oy) / r))
        i = int(np.clip(i, 0, self.height() - 1))
        j = int(np.clip(j, 0, self.width()  - 1))
        return i, j

    

    def in_bounds(self, i, j):
        H, W = self.image_array.shape
        return 0 <= i < H and 0 <= j < W

    def is_free(self, i, j):
 
        raise NotImplementedError  




class Queue():
    def __init__(self, init_queue = []):
        self.queue = copy(init_queue)
        self.start = 0
        self.end = len(self.queue)-1

    def __len__(self):
        numel = len(self.queue)
        return numel

    def __repr__(self):
        q = self.queue
        tmpstr = ""
        for i in range(len(self.queue)):
            flag = False
            if(i == self.start):
                tmpstr += "<"
                flag = True
            if(i == self.end):
                tmpstr += ">"
                flag = True

            if(flag):
                tmpstr += '| ' + str(q[i]) + '|\n'
            else:
                tmpstr += ' | ' + str(q[i]) + '|\n'

        return tmpstr

    def __call__(self):
        return self.queue

    def initialize_queue(self,init_queue = []):
        self.queue = copy(init_queue)

    def sort(self,key=str.lower):
        self.queue = sorted(self.queue,key=key)

    def push(self,data):
        self.queue.append(data)
        self.end += 1

    def pop(self):
        p = self.queue.pop(self.start)
        self.end = len(self.queue)-1
        return p

class nodes():
    def __init__(self,name):
        self.name = name
        self.children = []
        self.weight = []

    def __repr__(self):
        return self.name

    def add_children(self,node,w=None):
        if w == None:
            w = [1]*len(node)
        self.children.extend(node)
        self.weight.extend(w)

class Tree():
    def __init__(self,name):
        self.name = name
        self.root = 0
        self.end = 0
        self.g = {}
        self.g_visual = Graph('G')

    def __call__(self):
        for name,node in self.g.items():
            if(self.root == name):
                self.g_visual.node(name,name,color='red')
            elif(self.end == name):
                self.g_visual.node(name,name,color='blue')
            else:
                self.g_visual.node(name,name)
            for i in range(len(node.children)):
                c = node.children[i]
                w = node.weight[i]
                #print('%s -> %s'%(name,c.name))
                if w == 0:
                    self.g_visual.edge(name,c.name)
                else:
                    self.g_visual.edge(name,c.name,label=str(w))
        return self.g_visual

    def add_node(self, node, start = False, end = False):
        self.g[node.name] = node
        if(start):
            self.root = node.name
        elif(end):
            self.end = node.name

    def set_as_root(self,node):
        # These are exclusive conditions
        self.root = True
        self.end = False

    def set_as_end(self,node):
        # These are exclusive conditions
        self.root = False
        self.end = True

class MapProcessor():
    def __init__(self,name):
        self.map = Map(name)
        self.inf_map_img_array = np.zeros(self.map.image_array.shape)
        self.map_graph = Tree(name)

    def __modify_map_pixel(self,map_array,i,j,value,absolute):
        if( (i >= 0) and
            (i < map_array.shape[0]) and
            (j >= 0) and
            (j < map_array.shape[1]) ):
            if absolute:
                map_array[i][j] = value
            else:
                map_array[i][j] += value

    def in_bounds(self, i, j):
        H, W = self.inf_map_img_array.shape
        return 0 <= i < H and 0 <= j < W

    def is_free(self, i, j):
        return self.in_bounds(i, j) and (float(self.inf_map_img_array[i, j]) <= 1e-12)

    def nearest_free(self, i, j, R=60):
        if self.is_free(i, j):
            return i, j
        for r in range(1, R+1):
            # ring searchinsg 
            for di in range(-r, r+1):
                for dj in (-r, r):
                    ii, jj = i+di, j+dj
                    if self.is_free(ii, jj):
                        return ii, jj
            for dj in range(-r+1, r):
                for di in (-r, r):
                    ii, jj = i+di, j+dj
                    if self.is_free(ii, jj):
                        return ii, jj
        return None, None


    def __inflate_obstacle(self,kernel,map_array,i,j,absolute):
        dx = int(kernel.shape[0]//2)
        dy = int(kernel.shape[1]//2)
        if (dx == 0) and (dy == 0):
            self.__modify_map_pixel(map_array,i,j,kernel[0][0],absolute)
        else:
            for k in range(i-dx,i+dx):
                for l in range(j-dy,j+dy):
                    self.__modify_map_pixel(map_array,k,l,kernel[k-i+dx][l-j+dy],absolute)



    def inflate_map(self, kernel, absolute=True):
        # Start with zeros; we will "paint" influence around occupied cells.
        self.inf_map_img_array = np.zeros(self.map.image_array.shape, dtype=float)

        H, W = self.map.image_array.shape
        for i in range(H):
            for j in range(W):
                if self.map.image_array[i, j] > 0:   # occupied pixel
                    self.__inflate_obstacle(kernel, self.inf_map_img_array, i, j, absolute)

        # Normalize to [0,1] for convenience
        r = np.max(self.inf_map_img_array) - np.min(self.inf_map_img_array)
        if r == 0: r = 1.0
        self.inf_map_img_array = (self.inf_map_img_array - np.min(self.inf_map_img_array)) / r


    def get_graph_from_map(self):
        # Create the nodes that will be part of the graph, considering only valid nodes or the free space
        for i in range(self.map.image_array.shape[0]):
            for j in range(self.map.image_array.shape[1]):
                if self.inf_map_img_array[i][j] == 0:
                    node = nodes('%d,%d'%(i,j))
                    self.map_graph.add_node(node)
                    
        # Connect the nodes through edges
        for i in range(self.map.image_array.shape[0]):
            for j in range(self.map.image_array.shape[1]):
                if self.inf_map_img_array[i][j] == 0:
                    if (i > 0):
                        if self.inf_map_img_array[i-1][j] == 0:
                            # add an edge up
                            child_up = self.map_graph.g['%d,%d'%(i-1,j)]
                            self.map_graph.g['%d,%d'%(i,j)].add_children([child_up],[1])
                    if (i < (self.map.image_array.shape[0] - 1)):
                        if self.inf_map_img_array[i+1][j] == 0:
                            # add an edge down
                            child_dw = self.map_graph.g['%d,%d'%(i+1,j)]
                            self.map_graph.g['%d,%d'%(i,j)].add_children([child_dw],[1])
                    if (j > 0):
                        if self.inf_map_img_array[i][j-1] == 0:
                            # add an edge to the left
                            child_lf = self.map_graph.g['%d,%d'%(i,j-1)]
                            self.map_graph.g['%d,%d'%(i,j)].add_children([child_lf],[1])
                    if (j < (self.map.image_array.shape[1] - 1)):
                        if self.inf_map_img_array[i][j+1] == 0:
                            # add an edge to the right
                            child_rg = self.map_graph.g['%d,%d'%(i,j+1)]
                            self.map_graph.g['%d,%d'%(i,j)].add_children([child_rg],[1])
                    if ((i > 0) and (j > 0)):
                        if self.inf_map_img_array[i-1][j-1] == 0:
                            # add an edge up-left
                            child_up_lf = self.map_graph.g['%d,%d'%(i-1,j-1)]
                            self.map_graph.g['%d,%d'%(i,j)].add_children([child_up_lf],[np.sqrt(2)])
                    if ((i > 0) and (j < (self.map.image_array.shape[1] - 1))):
                        if self.inf_map_img_array[i-1][j+1] == 0:
                            # add an edge up-right
                            child_up_rg = self.map_graph.g['%d,%d'%(i-1,j+1)]
                            self.map_graph.g['%d,%d'%(i,j)].add_children([child_up_rg],[np.sqrt(2)])
                    if ((i < (self.map.image_array.shape[0] - 1)) and (j > 0)):
                        if self.inf_map_img_array[i+1][j-1] == 0:
                            # add an edge down-left
                            child_dw_lf = self.map_graph.g['%d,%d'%(i+1,j-1)]
                            self.map_graph.g['%d,%d'%(i,j)].add_children([child_dw_lf],[np.sqrt(2)])
                    if ((i < (self.map.image_array.shape[0] - 1)) and (j < (self.map.image_array.shape[1] - 1))):
                        if self.inf_map_img_array[i+1][j+1] == 0:
                            # add an edge down-right
                            child_dw_rg = self.map_graph.g['%d,%d'%(i+1,j+1)]
                            self.map_graph.g['%d,%d'%(i,j)].add_children([child_dw_rg],[np.sqrt(2)])

    def gaussian_kernel(self, size, sigma=1):
        size = int(size) // 2
        x, y = np.mgrid[-size:size+1, -size:size+1]
        normal = 1 / (2.0 * np.pi * sigma**2)
        g =  np.exp(-((x**2 + y**2) / (2.0*sigma**2))) * normal
        r = np.max(g)-np.min(g)
        sm = (g - np.min(g))*1/r
        return sm

    def rect_kernel(self, size, value):
        m = np.ones(shape=(size,size))
        return m

    def draw_path(self,path):
        path_tuple_list = []
        path_array = copy(self.inf_map_img_array)
        for idx in path:
            tup = tuple(map(int, idx.split(',')))
            path_tuple_list.append(tup)
            path_array[tup] = 0.5
        return path_array
    
# mp = MapProcessor('sync_classroom_map')
# kr = mp.rect_kernel(9,1)
# mp.inflate_map(kr,True)

# mp.get_graph_from_map()

# fig, ax = plt.subplots(dpi=100)
# plt.imshow(mp.inf_map_img_array)
# plt.colorbar()
# plt.show()
## end of map generation class --------------------------------------------------------------------------------------------------------------



# A star class ----------------------------------------------------------------------------------------------------------------------------------

class AStar():
    def __init__(self,in_tree):
        self.in_tree = in_tree
        self.q = Queue()
        self.dist = {name:np.inf for name,node in in_tree.g.items()}
        self.h = {name:0 for name,node in in_tree.g.items()}

        self._heap = []# creatong heap


        # creating the h(n) heuristic to goal
        for name,node in in_tree.g.items():
            start = tuple(map(int, name.split(',')))
            end = tuple(map(int, self.in_tree.end.split(',')))
            self.h[name] = np.sqrt((end[0]-start[0])**2 + (end[1]-start[1])**2)

        #self.h = {name: 0.0 for name in self.in_tree.g.keys()} # debuggig setting H valuies to zero
        self.via = {name:0 for name,node in in_tree.g.items()} # creating the predecor map (came from map for ech node)
        for __,node in in_tree.g.items():
            self.q.push(node)

    def neighbors(self, name):
        node = self.in_tree.g[name]            # Get the Node object for this name
        return [(child.name, w) for child, w in zip(node.children, node.weight)]

    # def __get_f_score(self,node):
    #     return self.dist[node]+self.h[node] # outputting the f scourse for the current node in question

    def __get_f_score(self, node):
        # Defensive: if a node slips through that isn't in dist/h, return inf
        if node not in self.dist or node not in self.h:
            # print or log if you want: print(f"[A*] missing node {node}")
            return np.inf
        return self.dist[node] + self.h[node]
        
    def solve(self, sn, en): #sn = start node, en = end node

        # setting start node to zeor
        self.dist[sn] = 0.0
        self.via[sn] = None # via is my parent table
        self._heap = [] # creating the heap

        # push start into the open set along with its F score
        heapq.heappush(self._heap,(self.__get_f_score(sn),sn))

        #creating empty set "closed set" for visited nodes
        self.visited = set()

        # main while loop------------------------------------whiile the open set is not empty
        while self._heap:

               #pop node withthe smallest F value
               F_score, current_node = heapq.heappop(self._heap)

               # checking if current node is in visited if not then search if it is then skip this iteration
               if current_node in self.visited:
                  continue

               # add current node to visited
               self.visited.add(current_node)

               # check if current_node is equal to en
               if current_node == en:
                  return self.reconstruct_path(sn,en) #### still have to finish the function

               #running the main for loop ------ branch checking
               for neighbor_node, branch_cost in self.neighbors(current_node):
                    if neighbor_node in self.visited:
                      continue

                    tentative_g_score = self.dist[current_node] + float(branch_cost) # new possible G score if it remains the lowest

                    if tentative_g_score < self.dist[neighbor_node]: #checking if a better path is found
                      self.dist[neighbor_node] = tentative_g_score
                      self.via[neighbor_node] = current_node

                      #push new fastes node into the open set tobe checked
                      heapq.heappush(self._heap,(self.__get_f_score(neighbor_node),neighbor_node))


        return [], np.inf    # if path connot be fopund retunr no path and inf time

    def reconstruct_path(self,sn,en):
        path = []
        dist = float(self.dist[en])
        current = en

        while current is not None:
           path.append(current)
           current = self.via[current]

        path.reverse()


        # if we never reach the start
        if path[0] != sn:
            path = []
            dist = np.inf

        return path,dist
    
## edn of Astar class ----------------------------------------------------------------------------------------------------------------------------------------



######################################################################End of All classes #########################################################################################







class tracker(Node):

    def __init__(self):
        super().__init__("tracker")
        self.bridge = CvBridge()  

        self.sub = self.create_subscription(ImageCV2,'/camera/image_raw',self.detect,10)
        self.sub_scan = self.create_subscription(LaserScan,"/scan",self.callback,10) # subscribing to get latest scan info
        self.pub_U = self.create_publisher(Twist,"/cmd_vel",10)

        # PID vals
        self.kp = 0.15
        self.ki = 0.01
        self.kd = 0.022

        self.last_error1 = 0
        self.I1 = 0
        self.I_last1= 0

        self.last_error2 = 0
        self.I2 = 0
        self.I_last2= 0

        self.last_error3 = 0
        self.I3 = 0
        self.I_last3= 0

        # serach mode
        self.SearchMode = False
        self.Recived_data = False
        self.SpinMode = False
        self.AdjustMode = False
        self.first_iter=False

        # gola poinst to search
        self.next_goal_pose = True
        self.goal_num = 0
        self.goals = [(-4.3,2.3),
                      (-4.3,-4.0),
                      (8.8, 0.0),
                      (8.2, -2.4),
                      (3.3,3.55),
                      (0.0, 3.0),
                      (-4.3,2.3),
                      (-4.3,-4.0)]
        self.theta_spin = 0
        self.go = 0



        ## from auto nav ---------------------------------------------------------------------------------------------
               
        # Path planner/follower related variables
        self.path = Path()
        self.goal_pose = PoseStamped()
        self.ttbot_pose = PoseStamped()
        self.start_time = 0.0

        self.mp = MapProcessor('sync_classroom_map')# current map
        kr = self.mp.rect_kernel(14, 1.0)      # tune size as needed
        self.mp.inflate_map(kr, True)
        self.mp.get_graph_from_map()


        # fig, ax = plt.subplots(dpi=100)
        # plt.imshow(self.mp.inf_map_img_array)
        # plt.colorbar()
        # plt.show()

        # flags
        self._have_goal = False
        self._current_path = None
        self._last_idx = 0 
        self._have_pose = False
        self.drivemode = False
        self.omega_set = False
        self.omega_spin = 0
        self.avoid = False

        self.See_Green = False
        self.See_Blue = False
        self.See_Red = False

        self.found_blue = False
        self.found_green = False
        self.found_red = False

        self.See_Blue_log = False
        self.See_Green_log = False
        self.See_Red_log = False
        self.no_ball_found = False

        self.found_all_balls = False



        # Subscribers
        self.create_subscription(PoseStamped, '/move_base_simple/goal', self.__goal_pose_cbk, 10)
        self.create_subscription(Odometry, '/odom', self.__ttbot_pose_cbk, 10)

        # Publishers
        self.path_pub = self.create_publisher(Path, 'global_plan', 10)
        self.cmd_vel_pub = self.create_publisher(Twist, 'cmd_vel', 10)
        self.calc_time_pub = self.create_publisher(Float32, 'astar_time',10) #DO NOT MODIFY

        # publishing ball pos

        self.pos_pub_red = self.create_publisher(Point, 'red_pos', 10)
        self.pos_pub_green = self.create_publisher(Point, 'green_pos', 10)
        self.pos_pub_blue = self.create_publisher(Point, 'blue_pos', 10)


        # Node rate
        self.rate = self.create_rate(10)

    def callback(self, Data: LaserScan): # call back to abtin the last scan 
        self.scan = Data
        self.Recived_data = True
      


        # readin data from the scan
        self.front_dist310 = self.scan.ranges[310]# most right
        self.front_dist320 = self.scan.ranges[320]# most right
        self.front_dist325 = self.scan.ranges[325]# most right
        self.front_dist330 = self.scan.ranges[330]# most right
        self.front_dist335 = self.scan.ranges[335]
        self.front_dist340 = self.scan.ranges[340]
        self.front_dist345 = self.scan.ranges[345]
        self.front_dist350 = self.scan.ranges[350]
        self.front_dist355 = self.scan.ranges[355]
        self.front_dist0 = self.scan.ranges[0] # strait ahwad
        self.front_dist5 = self.scan.ranges[5]
        self.front_dist10 = self.scan.ranges[10]
        self.front_dist15 = self.scan.ranges[15]
        self.front_dist20 = self.scan.ranges[20]
        self.front_dist25 = self.scan.ranges[25]
        self.front_dist30 = self.scan.ranges[30]# most left
        self.front_dist35 = self.scan.ranges[35]# most left
        self.front_dist40 = self.scan.ranges[40]# most left
        self.front_dist50 = self.scan.ranges[50]# most left



        
        self.front_dist270 = self.scan.ranges[270]# Pure right
        self.front_dist90 = self.scan.ranges[90]# Pure Left





        self.front_matrix = [
                            self.front_dist325,
                            self.front_dist330,
                            self.front_dist335,
                            self.front_dist340,
                            self.front_dist345,
                            self.front_dist350,
                            self.front_dist355,
                            self.front_dist0,
                            self.front_dist5,
                            self.front_dist10,
                            self.front_dist15,
                            self.front_dist20,
                            self.front_dist25,
                            self.front_dist30,
                            self.front_dist35,]
        
        self.front_matrix_wide =  [
                            self.front_dist310,
                            self.front_dist325,
                            self.front_dist330,
                            self.front_dist335,
                            self.front_dist340,
                            self.front_dist345,
                            self.front_dist350,
                            self.front_dist355,
                            self.front_dist0,
                            self.front_dist5,
                            self.front_dist10,
                            self.front_dist15,
                            self.front_dist20,
                            self.front_dist25,
                            self.front_dist30,
                            self.front_dist35,
                            self.front_dist40,
                            self.front_dist50]
       # self.get_logger().info(f"drive = {self.drivemode},spin = {self.avoid},have goal = {self._have_goal}")
        
        
        
        if self._have_goal:
            if np.min(self.front_matrix) < 0.35 or np.min(self.front_matrix_wide) < 0.075:
                self.avoid = True
                self.SearchMode = False
                
                self.get_logger().info("Almost hit obsticle")
                            
                msg = Twist()
                msg.linear.x = float(0.0)
                msg.linear.y = float(0.0)
                msg.linear.z = float(0.0)
                msg.angular.x = float(0.0)
                msg.angular.y = float(0.0)
                msg.angular.z = float(0.0)
                
                self.get_logger().info("pub 1")
                self.pub_U.publish(msg)

            if self.avoid and np.min(self.front_matrix) > 0.40:
                self.avoid = False
                self.omega_set = False

                self.drivemode = True


            if self.avoid:


                if not self.omega_set:

                    self.get_logger().info("selecting spin mode")
                    self.get_logger().info(f"90_dist = {self.front_dist90}, 270_dist = {self.front_dist270}")


                    if self.front_dist90<self.front_dist270:
                        self.omega_spin = -0.5
                        self.omega_set = True
                    else:
                        self.omega_spin = 0.5
                        self.omega_set = True



                self.get_logger().info("spinning")
                msg = Twist()
                msg.linear.x = float(0.0)
                msg.linear.y = float(0.0)
                msg.linear.z = float(0.0)
                msg.angular.x = float(0.0)
                msg.angular.y = float(0.0)
                msg.angular.z = float(self.omega_spin)

                self.get_logger().info("pub 2")
                self.pub_U.publish(msg)




            if self.drivemode:
                if  self.avoid:
                    return

                dt = 1/5 # about 5 hz
                self.go = dt*0.14 + self.go
                
                if self.go >.7:
                    self.go = 0
                    self.drivemode = False

                    self.get_logger().info("stop driving")
                    msg = Twist()
                    msg.linear.x = float(0.0)
                    msg.linear.y = float(0.0)
                    msg.linear.z = float(0.0)
                    msg.angular.x = float(0.0)
                    msg.angular.y = float(0.0)
                    msg.angular.z = float(0.0)

                    self.get_logger().info("pub 3")
                    self.pub_U.publish(msg)

                self.get_logger().info("blind driving")
                msg = Twist()
                msg.linear.x = float(0.1)
                msg.linear.y = float(0.0)
                msg.linear.z = float(0.0)
                msg.angular.x = float(0.0)
                msg.angular.y = float(0.0)
                msg.angular.z = float(0.0)

                self.get_logger().info("pub 4")
                self.pub_U.publish(msg)

            if not self.drivemode and not self.avoid and self._have_goal:
                
                #self.get_logger().info("searching")
                #self.searching()
                self.drivemode = False
                self.avoid = False

            # self.get_logger().info(f"drive = {self.drivemode},spin = {self.avoid},have goal = {self._have_goal}")




    def detect(self,msg):   


        if (self.found_blue) and (self.found_green) and (self.found_red):

            self.get_logger().info(f"\n green ball is at x = {self.x_green + 0.718* np.cos(self.theta_green)}, y = {self.y_green+ 0.718* np.sin(self.theta_green)} \n Red ball is at x = {self.x_red + 0.718* np.cos(self.theta_red)}, y = {self.y_red+ 0.718* np.sin(self.theta_red)}, \n Blue ball is at x = {self.x_blue + 0.718* np.cos(self.theta_blue)}, y = {self.y_blue+ 0.718* np.sin(self.theta_blue)}")
            self.found_all_balls = True

        if self.found_red:
            msg_red = Point()
            msg_red.x = self.x_red+ 0.718* np.cos(self.theta_red)
            msg_red.y = self.y_red+ 0.718* np.sin(self.theta_red)
            msg_red.z = 0.0 
            self.pos_pub_red.publish(msg_red)
        else:
            msg_r = Point()
            msg_r.x = 0.0
            msg_r.y = 0.0
            msg_r.z = 0.0
            self.pos_pub_red.publish(msg_r)


        if self.found_green:
            msg_green = Point()
            msg_green.x = self.x_green+ 0.718* np.cos(self.theta_green)
            msg_green.y = self.y_green+ 0.718* np.sin(self.theta_green)
            msg_green.z = 0.0 
            self.pos_pub_green.publish(msg_green)
        else:
            msg_g = Point()
            msg_g.x = 0.0
            msg_g.y = 0.0
            msg_g.z = 0.0
            self.pos_pub_green.publish(msg_g)

        if self.found_blue:
            msg_blue = Point()
            msg_blue.x = self.x_blue+ 0.718* np.cos(self.theta_blue)
            msg_blue.y = self.y_blue+ 0.718* np.sin(self.theta_blue)
            msg_blue.z = 0.0 
            self.pos_pub_blue.publish(msg_blue)
        else:
            msg_b = Point()
            msg_b.x = 0.0
            msg_b.y = 0.0
            msg_b.z = 0.0
            self.pos_pub_blue.publish(msg_b)

        

            



       
        frame = self.bridge.imgmsg_to_cv2(msg)
        frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)

        


        

        #frame = self.bridge.imgmsg_to_cv2(msg,desired_encoding='bgr8') # coverting imafe back 
        height, width = frame.shape[:2]


        hsvColorFrame = cv2.cvtColor(frame,cv2.COLOR_BGR2HSV)


        # RED hvs limit---------------------------------------

        red_low1  = np.array([0, 100, 100])
        red_low2 = np.array([10,255,255])
        lowerlim_mask = cv2.inRange(hsvColorFrame,red_low1,red_low2)

        red_high1 = np.array([170, 120, 150])
        red_high2 = np.array([179,255,255])
        upperlim_mask = cv2.inRange(hsvColorFrame,red_high1,red_high2)

        #combine mask
        red_mask = cv2.bitwise_or(lowerlim_mask,upperlim_mask)


        # GREEN hvs limit---------------------------------------

        green_low1  = np.array([35,  80,  80])
        green_low2  = np.array([85, 255, 255])
        lowerlim_mask = cv2.inRange(hsvColorFrame, green_low1, green_low2)

        green_high1 = np.array([35,  80,  80])
        green_high2 = np.array([85, 255, 255])
        upperlim_mask = cv2.inRange(hsvColorFrame, green_high1, green_high2)

        # Combined mask
        green_mask = cv2.bitwise_or(lowerlim_mask, upperlim_mask)

      
        # BLUE hvs limit---------------------------------------

        blue_low1  = np.array([100, 100,  80])
        blue_low2  = np.array([140, 255, 255])
        lowerlim_mask = cv2.inRange(hsvColorFrame, blue_low1, blue_low2)

        blue_high1 = np.array([100, 100,  80])
        blue_high2 = np.array([140, 255, 255])
        upperlim_mask = cv2.inRange(hsvColorFrame, blue_high1, blue_high2)

        # Combine mask
        blue_mask = cv2.bitwise_or(lowerlim_mask, upperlim_mask)



        # searching for colored balls

        if not self.found_red:
            contours_red, _ = cv2.findContours(red_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            area_red,Cx1_red = self.RedBall(contours_red,frame)


        if not self.found_green:
            contours_green, _ = cv2.findContours(green_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            area_green,Cx1_green = self.GreenBall(contours_green,frame)


        if not self.found_blue:
            contours_blue, _ = cv2.findContours(blue_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            area_blue,Cx1_blue = self.BlueBall(contours_blue,frame)


        cv2.imshow('frame',frame) # showing frame 


        #init
        area = 1
        Cx1 = 0

        if self.See_Blue:
            if not self.See_Blue_log:
                self.get_logger().info("I see Blue")

            self.See_Blue_log = True
            area = area_blue
            Cx1 = Cx1_blue
            self.no_ball_found = True



        elif self.See_Green:
            if not self.See_Green_log:
                self.get_logger().info("I see Green")
            
            self.See_Green_log = True
            area = area_green
            Cx1 = Cx1_green
            self.no_ball_found = True


        elif self.See_Red:
            if not self.See_Red_log:
                self.get_logger().info("I see Red")

            self.See_Red_log = True
            area = area_red
            Cx1 = Cx1_red
            self.no_ball_found = True


        else:
            if not self.no_ball_found:
                self.get_logger().info("No Ball found ... Searching")
            
            self.no_ball_found = True

        
        if (self.drivemode or self.avoid):
            self.get_logger().info(f"DANGER DANGER DANGER")
            area = 1
            
            

        # PID control + search algo ------------------------------------------------------------

        

        # PID control (omega)----------------------------------------------------------
        # desired area
        area_want = 500000.0
        
        #self.get_logger().info(f"Area = {area}")
        if area>1000:
            #self.get_logger().info("control mode")
           

            if area > 1000:
                self.error1 = -(area*0.00001)+(area_want*0.00001)
                # self.get_logger().info(f"error  = {self.error1}")
                dt = 0.1 # for now 
                self.D1 = (self.error1-self.last_error1)/(dt)
                self.I1 = self.error1*dt + self.I_last1
                self.P1 = self.error1
                U1 = (self.kp*self.P1 + self.ki*self.I1 + self.kd*self.D1)
                # self.get_logger().info(f"vel input = {U1}")
                if math.isnan(U1):
                    #print("I see nan")
                    V = 0
                else:
                    V =  max(-0.15,min(0.15,U1))
                    #V = U1

                # reset
                self.last_error1 = self.error1

        

            else:
                V = 0


            # PID control (omega)----------------------------------------------------------
            # desired cneter
            Center_x = width/2

            if area > 1000:
                self.error2 = -(Cx1*0.01)+(Center_x*0.01)
                #self.get_logger().info(f"output of error = {self.error2}")
                dt = 0.1 # for now 
                self.D2 = (self.error2-self.last_error2)/(dt)
                self.I2 = self.error2*dt + self.I_last2
                self.P2 = self.error2
                U2 = (self.kp*self.P2 + self.ki*self.I2+ self.kd*self.D2)
                #self.get_logger().info(f"omega input = {U2}")
                # self.get_logger().info(f"centroid x = {Cx1}, desired = {Center_x}, omega = {U2}")
                if math.isnan(U2):
                    #print("I see nan")
                    omega = 0
                else:
                    omega =  max(-0.15,min(0.15,U2))
                    #omega = U2

                # reset
                self.last_error2 = self.error2

            else:
                omega = 0


            # for now
        
            msg = Twist()
            msg.linear.x = float(V)
            msg.linear.y = float(0.0)
            msg.linear.z = float(0.0)

            msg.angular.x = float(0.0)
            msg.angular.y = float(0.0)
            msg.angular.z = float(omega)

            # print(f"position is:{self.scan.ranges[270]}")
            self.pub_U.publish(msg)
            self.SearchMode = False
            self.SpinMode = False




            if (np.abs(self.error1) <0.005) and (np.abs(self.error2) <0.005): # Ball found

                    # cords of ball, for now pos of (x,y) robot

                if self.See_Blue:
                    
                    
                    self.theta_blue = self.robotthete
                    self.x_blue = self.robotx
                    self.y_blue = self.roboty

                    self.found_blue = True
                    self.get_logger().info(f"blue ball is at x = {self.x_blue + 0.71* np.cos(self.theta_blue)}, y = {self.y_blue + 0.71* np.sin(self.theta_blue)},theta = {self.robotthete}")

                elif self.See_Green:

                
                    self.theta_green = self.robotthete
                    self.x_green = self.robotx
                    self.y_green = self.roboty

                    self.found_green = True
                    self.get_logger().info(f"green ball is at x = {self.x_green + 0.71* np.cos(self.theta_green)}, y = {self.y_green+ 0.71* np.sin(self.theta_green)}, theta = {self.robotthete}")



                elif self.See_Red:
                    
                    self.theta_red =self.robotthete
                    self.x_red = self.robotx
                    self.y_red = self.roboty

                    self.found_red = True
                    self.get_logger().info(f"Red ball is at x = {self.x_red + 0.71* np.cos(self.theta_red)}, y = {self.y_red + 0.71* np.sin(self.theta_red)}")

                self.See_Blue = False
                self.See_Green = False
                self.See_Red =False
            
    
        else: # entering search mode -----------------------------------------------------------------------------------------
            
            #self.get_logger().info("Search Mode")
            
        



    

            if not self.SearchMode:
                self.first_iter = True
                self.SearchMode = True
                
            else:
                self.first_iter = False
                

            if (self.drivemode or self.avoid):
                x = 1
            else:

                if not self.SpinMode:
                    if self.next_goal_pose:
                        if len(self.goals) == (self.goal_num-1):
                            self.goal_num = 0

                        goal_x,goal_y = self.goals[self.goal_num]
                        self.goal_pose.pose.position.x = goal_x
                        self.goal_pose.pose.position.y = goal_y
                        self.goal_num = self.goal_num + 1
                        self.next_goal_pose = False
                        self._have_goal = True

                    if self.found_all_balls:
                        self.goal_num = 0


                    self.searching()
                else:
                    
                    dt = 1/25.6 # about 25 hz
                    self.theta_spin = dt*0.4 + self.theta_spin
                    
                    if self.theta_spin >6.3:
                        self.theta_spin = 0
                        self.SearchMode = False
                        self.SpinMode = False
                    



                    msg = Twist()
                    msg.linear.x = float(0)
                    msg.linear.y = float(0.0)
                    msg.linear.z = float(0.0)

                    msg.angular.x = float(0.0)
                    msg.angular.y = float(0.0)
                    msg.angular.z = float(0.4)

                    # print(f"position is:{self.scan.ranges[270]}")
                    self.pub_U.publish(msg)





        if cv2.waitKey(1) & 0xFF == ord('q'): ## match with video fps
            self.get_logger().info("why we braking")
            cv2.destroyAllWindows()
            return
        

# see ball funcs----------------------------------------------------------------------------------------------

    def BlueBall(self,contours,frame):


        area = 1
        areas = [0.0]
        Cx1s = [0.0]
        for c in contours:
            area = cv2.contourArea(c)
            if area>5000:

                self.See_Blue = True
                areas.append(area)
                xs = c[:, 0, 0]  # x cords
                ys = c[:, 0, 1]  # y

                Cx = int(np.mean(xs))
                Cy = int(np.mean(ys))


                M = cv2.moments(c) # area weighted average
                if M["m00"] > 0:
                    Cx1 = (M["m10"] / M["m00"]) #x/tot
                    Cy1 = (M["m01"] / M["m00"]) # y/tot
                else:
                    Cx1 = 0
                    Cy1 = 0


                Cx1s.append(Cx1)
            
                cv2.drawContours(frame, [c], -1, (255, 0, 0), 2)  # blue contour line
                x, y, w, h = cv2.boundingRect(c)
                cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 3)  # drawing green box onto frame
                cv2.circle(frame, (int(Cx) ,int(Cy)), 5, (255, 0, 100), -1)
                cv2.circle(frame, (int(Cx1) ,int(Cy1)), 5, (0, 200, 255), -1)
            
            
            

            # # printing statments
            # self.get_logger().info(f"Centroid pos, x = {Cx1}, y = {Cy1}")
            # self.get_logger().info(f"Width & Height of obj. w = {w}, h = {h}")
            #self.get_logger().info(f"area = {area}")

        area = max(areas)
        Cx1 = max(Cx1s)
 

        return area,Cx1










    def GreenBall(self,contours,frame):


        area = 1
        areas = [0.0]
        Cx1s = [0.0]
        for c in contours:
            area = cv2.contourArea(c)
            if area>5000:

                self.See_Green = True
        
                areas.append(area)
                xs = c[:, 0, 0]  # x cords
                ys = c[:, 0, 1]  # y

                Cx = int(np.mean(xs))
                Cy = int(np.mean(ys))


                M = cv2.moments(c) # area weighted average
                if M["m00"] > 0:
                    Cx1 = (M["m10"] / M["m00"]) #x/tot
                    Cy1 = (M["m01"] / M["m00"]) # y/tot
                else:
                    Cx1 = 0
                    Cy1 = 0


                Cx1s.append(Cx1)
            
                cv2.drawContours(frame, [c], -1, (255, 0, 0), 2)  # blue contour line
                x, y, w, h = cv2.boundingRect(c)
                cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 3)  # drawing green box onto frame
                cv2.circle(frame, (int(Cx) ,int(Cy)), 5, (255, 0, 100), -1)
                cv2.circle(frame, (int(Cx1) ,int(Cy1)), 5, (0, 200, 255), -1)
             
       
            

            # # printing statments
            # self.get_logger().info(f"Centroid pos, x = {Cx1}, y = {Cy1}")
            # self.get_logger().info(f"Width & Height of obj. w = {w}, h = {h}")
            #self.get_logger().info(f"area = {area}")

        area = max(areas)
        Cx1 = max(Cx1s)
 
        

        return area,Cx1


    def RedBall(self,contours,frame):


        area = 1
        areas = [0.0]
        Cx1s = [0.0]
        for c in contours:
            area = cv2.contourArea(c)
            if area>5000:

                self.See_Red = True
        
                areas.append(area)
                xs = c[:, 0, 0]  # x cords
                ys = c[:, 0, 1]  # y

                Cx = int(np.mean(xs))
                Cy = int(np.mean(ys))


                M = cv2.moments(c) # area weighted average
                if M["m00"] > 0:
                    Cx1 = (M["m10"] / M["m00"]) #x/tot
                    Cy1 = (M["m01"] / M["m00"]) # y/tot
                else:
                    Cx1 = 0
                    Cy1 = 0


                Cx1s.append(Cx1)
            
                cv2.drawContours(frame, [c], -1, (255, 0, 0), 2)  # blue contour line
                x, y, w, h = cv2.boundingRect(c)
                cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 3)  # drawing green box onto frame
                cv2.circle(frame, (int(Cx) ,int(Cy)), 5, (255, 0, 100), -1)
                cv2.circle(frame, (int(Cx1) ,int(Cy1)), 5, (0, 200, 255), -1)

            

            # # printing statments
            # self.get_logger().info(f"Centroid pos, x = {Cx1}, y = {Cy1}")
            # self.get_logger().info(f"Width & Height of obj. w = {w}, h = {h}")
            #self.get_logger().info(f"area = {area}")

        area = max(areas)
        Cx1 = max(Cx1s)
 
        

        return area,Cx1




 ############################################################## Def for Astar path follwoing ##################################################################################################


    def __goal_pose_cbk(self, data):
        """! Callback to catch the goal pose.
        @param  data    PoseStamped object from RVIZ.
        @return None.
        """
        self.goal_pose = data
        self._have_goal = True
        self._current_path = None  # trigger replan
       # self.get_logger().info('goal_pose: {:.4f}, {:.4f}'.format(self.goal_pose.pose.position.x, self.goal_pose.pose.position.y))

    def __ttbot_pose_cbk(self, msg: Odometry):
            
            self.robotx = msg.pose.pose.position.x
            self.roboty = msg.pose.pose.position.y


            q = msg.pose.pose.orientation
            sin_q = 2 * (q.w * q.z + q.x * q.y)
            cos_q = 1 - 2 * (q.y * q.y + q.z * q.z)
            self.robotthete = np.arctan2(sin_q, cos_q)
            #self.get_logger().info(f"raw odom -> x={x}, y={y}")
        
            ps = PoseStamped()
            ps.header.stamp = msg.header.stamp
            ps.header.frame_id = msg.header.frame_id  
            ps.pose = msg.pose.pose
            self.ttbot_pose = ps


        



    def a_star_path_planner(self, start_pose, end_pose):
        """! A Start path planner.
        @param  start_pose    PoseStamped object containing the start of the path to be created.
        @param  end_pose      PoseStamped object containing the end of the path to be created.
        @return path          Path object containing the sequence of waypoints of the created path.
        """

      

        #!! make sure to uncomment this later******************&&&&&&&&&&&&&&&&&&&&&^^^^^^^^^^^^^^^^^^^^^^^^^^

        self.get_logger().info('A* planner.\n> start: {},\n> end: {}'.format(start_pose.pose.position, end_pose.pose.position))
        self.get_logger().info(f"goal = {end_pose.pose.position}")
        self.start_time = self.get_clock().now().nanoseconds*1e-9 #Do not edit this line (required for autograder)


        # world (m) -> grid (i,j)
        si, sj = self.mp.map.world_to_grid(start_pose.pose.position.x,start_pose.pose.position.y)
        ei, ej = self.mp.map.world_to_grid(end_pose.pose.position.x,end_pose.pose.position.y)

        si, sj = self.mp.nearest_free(si, sj)
        ei, ej = self.mp.nearest_free(ei, ej)
        if si is None or ei is None:
            self.get_logger().error("Start/goal inside obstacles; no nearby free cell.")
            return None

        s_name = f"{si},{sj}"
        e_name = f"{ei},{ej}"

        # must be members of the graph
        # if s_name not in self.mp.map_graph.g:
        #     self.get_logger().error(f"Start {s_name} not in graph (blocked/mismatch).")
        #     return None
        # if e_name not in self.mp.map_graph.g:
        #     self.get_logger().error(f"Goal  {e_name} not in graph (blocked/mismatch).")
        #     return None

        self.mp.map_graph.root = s_name
        self.mp.map_graph.end  = e_name

        astar = AStar(self.mp.map_graph)
        names, dist = astar.solve(s_name, e_name)
        

    # grid to map world for RViz
        path = Path()
        path.header.frame_id = "map"
        poses = []
        for name in names:
            i, j = map(int, name.split(","))
            x, y = self.mp.map.grid_to_world(i, j)
            ps = PoseStamped()
            ps.pose.position.x = x
            ps.pose.position.y = y
            ps.pose.orientation.w = 1.0
            poses.append(ps)

        if ps is None:
            self.get_logger().info("buggy ah code")
            return None
        
        ps.pose.position.x = end_pose.pose.position.x
        ps.pose.position.y = end_pose.pose.position.y
        ps.pose.orientation.w = 1.0
        poses.append(ps)     # appending goal point to make sure robot reaches intedted goal

        
        path.poses = poses
        self.path_pub.publish(path)

        # Do not edit below (required for autograder)
        self.astarTime = Float32()
        self.astarTime.data = float(self.get_clock().now().nanoseconds*1e-9-self.start_time)
        self.calc_time_pub.publish(self.astarTime)
        


        return path

    def get_path_idx(self, path, vehicle_pose):
        """! Path follower.
        @param  path                  Path object containing the sequence of waypoints of the created path.
        @param  current_goal_pose     PoseStamped object containing the current vehicle position.
        @return idx                   Position in the path pointing to the next goal pose to follow.
        """
        idx = 0
        


        k = 3 # look ahead 

        wp = np.array([[p.pose.position.x, p.pose.position.y] for p in path.poses], dtype=float)
        N = len(wp) 

        # tuerle bot crrent position x,y
        px = vehicle_pose.pose.position.x 
        py = vehicle_pose.pose.position.y 

        #print(f"reading x = {px} and y  = {py}")

        p  = np.array([px, py], dtype=float)

        #finding nearierst point to path
        i_near = int(np.argmin(np.sum((wp - p)**2, axis=1)))


        # new goal pos
        idx = min(i_near + k, N - 1)
        idx1 = min(i_near,N-1)

        #goal pos stamp creation
        goal = PoseStamped(); 
        goal.pose.position.x = float(wp[idx,0])
        goal.pose.position.y = float(wp[idx,1])

        # headin driection t0 new point
        if idx1 < N - 1:
            dx, dy = wp[idx1+1,0]-wp[idx1,0], wp[idx1+1,1]-wp[idx1,1]
        else:
            dx, dy = wp[idx1,0]-wp[idx1-1,0], wp[idx1,1]-wp[idx1-1,1]

        th = np.arctan2(dy, dx) # calculating heading angle
        goal.pose.orientation.z = np.sin(th/2.0)
        goal.pose.orientation.w = np.cos(th/2.0)

        

        

        self._last_idx = idx
        return idx, goal


    def path_follower(self, vehicle_pose, current_goal_pose):
        """! Path follower.
        @param  vehicle_pose           PoseStamped object containing the current vehicle pose.
        @param  current_goal_pose      PoseStamped object containing the current target from the created path. This is different from the global target.
        @return path                   Path object containing the sequence of waypoints of the created path.
        """
        speed = 0.0
        heading = 0.0
        # TODO: IMPLEMENT PATH FOLLOWER


        # full state feedback implimatation-----------------------------------

        v_ref = 0.15         # nominal speed
        v_max = 0.15          # max vel
        w_max = 3             # max omega

        # state cost (Q) and input cost (R)
        Q = np.array([[4,0,0],[0,4,0],[0,0,20]]) # states for x,y,theta
        R = np.array([[1.5, 0],[0,8]]) # inputs for vel and omega

       # current states 
        px = vehicle_pose.pose.position.x
        py = vehicle_pose.pose.position.y
        q  = vehicle_pose.pose.orientation
        # yaw from quaternion
        siny_cosp = 2.0 * (q.w * q.z + q.x * q.y)
        cosy_cosp = 1.0 - 2.0 * (q.y * q.y + q.z * q.z)

        th = np.arctan2(siny_cosp, cosy_cosp)
        x = np.array([px, py, th], dtype=float)  # state vector [x,y,theta]

        
        # ref path/ nominal states
        x_r = current_goal_pose.pose.position.x 
        y_r = current_goal_pose.pose.position.y
        qq = current_goal_pose.pose.orientation
        #yaw for quarternion
        siny_cospos = 2.0 * (qq.w * qq.z + qq.x * qq.y)
        cosy_cospos = 1.0 - 2.0 * (qq.y * qq.y + qq.z * qq.z)
        theta_r = np.arctan2(siny_cospos,cosy_cospos)

        ref = np.array([x_r,y_r,theta_r], dtype=float) # ref inputs 

        # --- Nominal input 
        v_r = float(v_ref)
        omega_r = 0.0  
        u_r = np.array([v_r, omega_r], float)



        # linearize state space at nom inputs
        def A_of(theta, v):
            return np.array([[0.0, 0.0, -v * np.sin(theta)],
                            [0.0, 0.0,  v * np.cos(theta)],
                            [0.0, 0.0,  0.0]], dtype=float)

        def B_of(theta):
            return np.array([[np.cos(theta), 0.0],
                            [np.sin(theta), 0.0],
                            [0.0,             1.0]], dtype=float)

        A = A_of(theta_r, v_r)
        B = B_of(theta_r)

        K, _, _ = ct.lqr(A, B, Q, R)   # K 2x3
    
 
       # error calc
        e = x - ref

        self.get_logger().info(f"error = {e}")

        # wrap angle to (-π, π]
        e[2] = (e[2] + np.pi) % (2.0 * np.pi) - np.pi


        # system input
        u = u_r - K@e

      
        self.correction_error_I = self.correction_error_I + u[1]
        self.currection_error_d = (self.error_last - u[1])/20
        self.error_last = u[1]




       


        #self.get_logger().info(f"correction = {self.correction_error}, derivative = {self.currection_error_d}")


        speed = float(np.clip(u[0], -v_max, v_max))
        heading = float(np.clip(u[1], -w_max, w_max))

       
        #print(f"{u[0]}")

        return speed, heading

    def move_ttbot(self, speed, heading):
        """! Function to move turtlebot passing directly a heading angle and the speed.
        @param  speed     Desired speed.
        @param  heading   Desired yaw angle.
        @return path      object containing the sequence of waypoints of the created path.
        """
        cmd_vel = Twist()
        # TODO: IMPLEMENT YOUR LOW-LEVEL CONTROLLER
        cmd_vel.linear.x = speed
        cmd_vel.angular.z = heading

        #print(f"publishing vel = {speed}, omega = {heading}")

        self.cmd_vel_pub.publish(cmd_vel)

   




    def searching(self):

        if self.first_iter:
            path = self.a_star_path_planner(self.ttbot_pose, self.goal_pose)
            self.first_iter = False
            self._current_path = path
            self._last_idx = 0
            self.correction_error = 0
            self.correction_error_I = 0
            self.currection_error_d = 0
            self.error_last =0

        self.idx, current_goal = self.get_path_idx(self._current_path, self.ttbot_pose)
        self._last_idx = self.idx

        N = len(self._current_path.poses)
        # self.get_logger().info(f"N = {N}, index = {self.idx}")

        # Stop the robot when final waypoint reached
        if self.idx >= N-3:
            self.get_logger().info("Goal reached :Activate spin mode")
            self.move_ttbot(0.0, 0.0)
            self._have_goal = False
            self._current_path = None
            self._last_idx = 0
            self.first_iter = False
            self.idx = 0
            self.SpinMode = True
            self.SearchMode =False

            # for goal poses
            self.next_goal_pose = True

          

        speed, heading = self.path_follower(self.ttbot_pose, current_goal)
        self.move_ttbot(speed, heading)



def main(args=None):
    rclpy.init(args=args) # this initializes ross two communications

    node = tracker() # activating the class called MyNode
    rclpy.spin(node) # keep node alive and running

    node.destroy_node()
    rclpy.shutdown()   # shuts downs node

if __name__ == '__main__':
    main()
