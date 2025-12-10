#!/usr/bin/env python3

import os
import matplotlib
matplotlib.use("TkAgg")          
import matplotlib.pyplot as plt
import matplotlib.cm as cm

import rclpy
from rclpy.node import Node 
from nav_msgs.msg import OccupancyGrid
import numpy as np
import matplotlib.pyplot as plt

#ros2 launch turtlebot3_gazebo mapper.launch.py
#ros2 run teleop_twist_keyboard teleop_twist_keyboard 


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

#!/usr/bin/env python3

import sys

import time

# ros2 node imports


from nav_msgs.msg import Path
from geometry_msgs.msg import PoseStamped, PoseWithCovarianceStamped, Pose, Twist
from std_msgs.msg import Float32
from nav_msgs.msg import Odometry



# controls impoers
import control as ct
from scipy.integrate import solve_ivp

# ap processing iports
import heapq

from pathlib import Path as FsPath


from PIL import Image, ImageOps
import numpy as np

import yaml
import pandas as pd
from copy import copy, deepcopy
import time
import os
from ament_index_python.packages import get_package_share_directory
from graphviz import Graph

from nav_msgs.msg import OccupancyGrid
import pandas as pd


############################################################### All classes ##########################################################################################


class Map():
    # def __init__(self, map_name):
    #     self.map_im, self.map_df, self.limits = self.__open_map(map_name)
    #     self.image_array = self.__get_obstacle_map(self.map_im, self.map_df)

#------------------------------chnages for occupency graph----------------------------------------------------------------
    def __init__(self, map_name=None, occ_msg=None):
        if occ_msg is not None:
            self.map_im, self.map_df, self.limits = self.occupency_grid_map_open(occ_msg)
        else:
            self.map_im, self.map_df, self.limits = self.__open_map(map_name)
        self.image_array = self.__get_obstacle_map(self.map_im, self.map_df)

    def occupency_grid_map_open(self, msg):

        info = msg.info
        w, h = info.width, info.height

        arr = np.asarray(msg.data).reshape(h, w)   # -1, 0, 100

     

        gray = np.where(arr == 100,0,np.where(arr == 0,254, 205)).astype(np.uint8)

        # im = Image.fromarray(gray)

        # arr = np.asarray(msg.data, dtype=int).reshape(h, w)   # values: -1, 0, 100
        # # free=255, occupied OR unknown = 0
        # gray = np.where(arr == 0, 255, 0).astype(np.uint8)
        im = Image.fromarray(gray)
            
        origin = [float(info.origin.position.x), float(info.origin.position.y), 0.0]

        # fake json file
        map_df = pd.json_normalize({"resolution": info.resolution,"origin": [origin],"occupied_thresh": 0.65,"free_thresh": 0.196,"negate": 0})

        xmin = origin[0]
        ymin = origin[1]
        res  = float(info.resolution)
        xmax = xmin + im.size[0] * res
        ymax = ymin + im.size[1] * res

        return im, map_df, [xmin, xmax, ymin, ymax]
# - --------------------------------------------------------------------------------------------------------------------------------
    def __repr__(self):
        fig, ax = plt.subplots(dpi=150)
        ax.imshow(self.image_array, extent=self.limits, cmap=cm.gray)
        ax.plot()
        return ""

    def __open_map(self, map_name):
     
        try:
            package_share = get_package_share_directory('task_6')
            maps_dir = os.path.join(package_share, 'maps')
        except Exception:

            base_dir = os.path.dirname(__file__)
            parent_dir = os.path.dirname(base_dir)
            maps_dir = os.path.join(parent_dir, 'maps')

        yaml_path = os.path.join(maps_dir, f"{map_name}.yaml")
        print("Looking for YAML:", yaml_path)

        f = open(yaml_path, 'r')
        map_df = pd.json_normalize(yaml.safe_load(f))######

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
        #occ = np.flipud(occ)

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
    # def __init__(self,name):
    #     self.map = Map(name)
    #     self.inf_map_img_array = np.zeros(self.map.image_array.shape)
    #     self.map_graph = Tree(name)
# -----------------------------------------------------------------------------------------------------------------------
    def __init__(self, name=None, occ_msg=None):
        if occ_msg is not None:
            self.map = Map(occ_msg=occ_msg)
            name = name or "live_map"
        else:
            self.map = Map(name)
        self.inf_map_img_array = np.zeros(self.map.image_array.shape)
        self.map_graph = Tree(name)
#----------------------------------------------------------------------------------------------------------------------------


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

def find_nearest_frontier_by_distance(msg, robot_x, robot_y):

    info = msg.info
    w = info.width
    h = info.height

    #graph to  grid
    grid = np.array(msg.data, dtype=int).reshape(h, w)

    ri = int((robot_y - info.origin.position.y) / info.resolution)
    rj = int((robot_x - info.origin.position.x) / info.resolution)

    ri = np.clip(ri, 0, h - 1)
    rj = np.clip(rj, 0, w - 1)

    unknown_cells = np.argwhere(grid == -1) # all unknown scells

    if len(unknown_cells) == 0:
        return None  # fully explored

    dists = np.sqrt((unknown_cells[:,0] - ri)**2 + (unknown_cells[:,1] - rj)**2)

    sorted_idx = np.argsort(dists)[::-1] # farthest 
    unknown_cells = unknown_cells[sorted_idx]


    # cleaning 
    m = 0
    p = 0
    for (ux, uy) in unknown_cells:
        n = 0
        
        for i, j in [(-1,0),(1,0),(0,-1),(0,1),(1,1),(1,-1),(-1,1),(-1,-1),(-2,0),(2,0),(0,-2),(0,2)]:
            x = ux + i
            y = uy + j
            if x < 0 or x >= h or y < 0 or y >= w:
                continue

            if grid[x][y] ==100:
                grid[ux][uy] = 1
                break
            
            if grid[x][y] == 1:
                m = 1+m
            
            if m==3:
                grid[ux][uy] = 1
                break

            

        
    unknown_cells = np.argwhere(grid == -1) # all unknown scells

    if len(unknown_cells) == 0:
        return None  # fully explored

    dists = np.sqrt((unknown_cells[:,0] - ri)**2 + (unknown_cells[:,1] - rj)**2)

    sorted_idx = np.argsort(dists)[::-1] # farthest 
    # sorted_idx = np.argsort(dists) # closest

    unknown_cells = unknown_cells[sorted_idx]


   



    for (ux, uy) in unknown_cells:
        n = 0
        
        for i, j in [(-1,0),(1,0),(0,-1),(0,1),(1,1),(1,-1),(-1,1),(-1,-1)]:
            x = ux + i
            y = uy + j
            if x < 0 or x >= h or y < 0 or y >= w:
                continue
            

            if grid[x][y] == 0:      
                n += 1
                if n > 2:         
                    break
            
            if grid[x][y] == 100: # obsticle
                    print("skipped node touching wall")
                    break 
            
            
                
                
        if n == 1:
            origin_x = info.origin.position.x + uy * info.resolution
            origin_y = info.origin.position.y + ux * info.resolution
            return (origin_x, origin_y)
        
    

# If no frontier found
    print("NO FRONTER FOUND")
    return None




class SubscriberNode(Node):

    def __init__(self):
        super().__init__("listener")
       
        fig, ax = plt.subplots(dpi=100)


        self.bridge = CvBridge()  

        #self.sub = self.create_subscription(ImageCV2,'/camera/image_raw',self.detect,10)
        #self.sub_scan = self.create_subscription(LaserScan,"/scan",self.callback,10) # subscribing to get latest scan info
        self.pub_U = self.create_publisher(Twist,"/cmd_vel",10)
        self.sub = self.create_subscription(OccupancyGrid,"/map",self.Grid_CallBack,10)


        self.timer = self.create_timer(0.1, self.timer_cb)
   

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
        self.goals = [(8.8, 0.0),
                      (8.2, -2.4),
                      (3.3,3.55),
                      (0.0, 3.0),
                      (-4.3,2.0),
                      (-4.3,-4.0)]
        self.theta_spin = 0



        ## from auto nav ---------------------------------------------------------------------------------------------
               
        # Path planner/follower related variables
        self.path = Path()
        self.goal_pose = PoseStamped()
        self.ttbot_pose = PoseStamped()
        self.start_time = 0.0

        # self.mp = MapProcessor('sync_classroom_map')# current map
        # kr = self.mp.rect_kernel(14, 1.0)      # tune size as needed
        # self.mp.inflate_map(kr, True)
        # self.mp.get_graph_from_map()


        # fig, ax = plt.subplots(dpi=100)
        # plt.imshow(self.mp.inf_map_img_array)
        # plt.colorbar()
        # plt.show()

        # flags
        self._have_goal = False
        self._current_path = None
        self._last_idx = 0 
        self._have_pose = False

        self.fx = 0
        self.fy = 0
        self.point_count = 0
        self.fx_last = 0
        self.fy_last = 0
        self.waiting_pose = 0

        self.drivemode = False
        self.omega_set = False
        self.omega_spin = 0
        self.theta_spin = 0
        self.go = 0
        self.avoid = False
        self.remap = False


        # Subscribers
        self.create_subscription(PoseStamped, '/move_base_simple/goal', self.__goal_pose_cbk, 10)
        self.create_subscription(Odometry, '/odom', self.__ttbot_pose_cbk, 10)
        self.sub_scan = self.create_subscription(LaserScan,"/scan",self.safty_callback,10) # subscribing to get latest scan info


        # Publishers
        self.path_pub = self.create_publisher(Path, 'global_plan', 10)
        self.cmd_vel_pub = self.create_publisher(Twist, 'cmd_vel', 10)
        self.calc_time_pub = self.create_publisher(Float32, 'astar_time',10) #DO NOT MODIFY

        # Node rate
        self.rate = self.create_rate(10)

    def safty_callback(self, Data: LaserScan): # call back to abtin the last scan 
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
                self.remap = True
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

            if self.avoid and np.min(self.front_matrix) > 0.35:
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
                
                if self.go >.3:
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




        
    def timer_cb(self):
        self.waiting_pose = self.waiting_pose+1
        if not self._have_goal:
            if self.waiting_pose ==1:
                self.get_logger().info("waiting for goal pos")
        else:
            self.first_iter
            # self.get_logger().info("Have goal poses")

            if not self.avoid and (not self.drivemode):
                self.searching()
                self.first_iter = False
                self.waiting_pose =0
                self.get_logger().info("Still searching")





        

    def Grid_CallBack(self,msg):

        if not self._have_goal:
            self.grid_msg = msg
            info = msg.info
            # self.get_logger().info(f"map size: w = {info.width}, h = {info.height}")
            # self.get_logger().info(f"origin: x = ({info.origin.position.x:.3f}, y = {info.origin.position.y:.3f}),")
            # self.get_logger().info(f"time: {msg.header.stamp.sec}.{msg.header.stamp.nanosec:09d}")

            self.mp = MapProcessor(occ_msg=msg)
            kr = self.mp.rect_kernel(13, 1)
            self.mp.inflate_map(kr, True)
            self.mp.get_graph_from_map()
            
            # plt.imshow(self.mp.inf_map_img_array)
            # plt.colorbar()
            # plt.show()
            
            grid = np.array(msg.data).reshape(info.height, info.width)     # grid[i, j]

           


                

            x = 0.0 
            y = 0.0 

            self.fx,self.fy = find_nearest_frontier_by_distance(msg,x,y)



            if self.fx == self.fx_last and self.fy ==self.fy_last:
                  
                  self.point_count = self.point_count+1
                  self.get_logger().info(f"same point count = {self.point_count}")
            else:
                self.point_count = 0



            if self.point_count == 3:
                self.point_count = 0
                self.get_logger().info(f"Turtle ot crash out, looking for new point")
        
                x = self.ttbot_pose.pose.position.x 
                y = self.ttbot_pose.pose.position.y 
                self.fx,self.fy = find_nearest_frontier_by_distance(msg,x,y)


            self.fx_last = self.fx
            self.fy_last = self.fy




            self.get_logger().info(f"fronterr x  = {self.fx}, fronterr y = {self.fy}")


            self.goal_pose.pose.position.x = self.fx
            self.goal_pose.pose.position.y = self.fy
            self._have_goal = True
            self.first_iter = True

        





 ############################################################## Def for Astar path follwoing ##################################################################################################


    def __goal_pose_cbk(self, data):
        """! Callback to catch the goal pose.
        @param  data    PoseStamped object from RVIZ.
        @return None.
        """
        self.goal_pose = data
        self._have_goal = True
        self._current_path = None  # trigger replan
        #self.get_logger().info('goal_pose: {:.4f}, {:.4f}'.format(self.goal_pose.pose.position.x, self.goal_pose.pose.position.y))

    def __ttbot_pose_cbk(self, msg: Odometry):
            
            x = msg.pose.pose.position.x
            y = msg.pose.pose.position.y
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

        # self.get_logger().info('A* planner.\n> start: {},\n> end: {}'.format(start_pose.pose.position, end_pose.pose.position))
        # self.get_logger().info(f"goal = {end_pose.pose.position}")
        self.start_time = self.get_clock().now().nanoseconds*1e-9 #Do not edit this line (required for autograder)


        # world (m) -> grid (i,j)
        # si, sj = self.mp.map.world_to_grid(start_pose.pose.position.x,start_pose.pose.position.y)
        # ei, ej = self.mp.map.world_to_grid(end_pose.pose.position.x,end_pose.pose.position.y)

        info = self.grid_msg.info
        w = info.width
        h = info.height
        ox = info.origin.position.x
        oy = info.origin.position.y
        res = info.resolution

        # Build grid
        grid = np.array(self.grid_msg.data, dtype=int).reshape(h, w)
        si = int(round((start_pose.pose.position.y- oy) / res))   
        sj = int(round((start_pose.pose.position.x- ox) / res))
        


        ei = int(round((end_pose.pose.position.y - oy) / res))   
        ej = int(round((end_pose.pose.position.x - ox) / res))   
      

        si, sj = self.mp.nearest_free(si, sj)
        ei, ej = self.mp.nearest_free(ei, ej)
        if si is None or ei is None:
            self.get_logger().info("Start/goal inside obstacles no nearby free cell.")
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


        if not names or not np.isfinite(dist):
            self.get_logger().error("A star is failing bruh why??!?!?!?!")
            return None
        

    # grid to map world for RViz
        path = Path()
        path.header.frame_id = "map"
        poses = []
        for name in names:
            i, j = map(int, name.split(","))
            #x, y = self.mp.map.grid_to_world(i, j)

            x = ox + (j+0.5)* res
            y = oy + (i+0.5)*res



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
        """! Path follower.In my 
        @param  path                  Path object containing the sequence of waypoints of the created path.
        @param  current_goal_pose     PoseStamped object containing the current vehicle position.
        @return idx                   Position in the path pointing to the next goal pose to follow.
        """
        idx = 0
        # TODO: IMPLEMENT A MECHANISM TO DECIDE WHICH POINT IN THE PATH TO FOLLOW idx <= len(path)


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

        #goal pos stamp creation
        goal = PoseStamped(); 
        goal.pose.position.x = float(wp[idx,0])
        goal.pose.position.y = float(wp[idx,1])

        # headin driection t0 new point
        if idx < N - 1:
            dx, dy = wp[idx+1,0]-wp[idx,0], wp[idx+1,1]-wp[idx,1]
        else:
            dx, dy = wp[idx,0]-wp[idx-1,0], wp[idx,1]-wp[idx-1,1]

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

        v_ref = 0.3         # nominal speed
        v_max = 0.3          # max vel
        w_max = 10           # max omega

        # state cost (Q) and input cost (R)
        Q = np.array([[2,0,0],[0,2,0],[0,0,2]]) # states for x,y,theta
        R = np.array([[10, 0],[0,1]]) # inputs for vel and omega

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

       # self.get_logger().info(f"error = {e}")

        # wrap angle to (-π, π]
        e[2] = (e[2] + np.pi) % (2.0 * np.pi) - np.pi


        # system input
        u = u_r - K@e


        speed = float(np.clip(u[0]*10, -v_max, v_max))
        heading = float(np.clip(u[1], -w_max, w_max))
       # print(f"{u[0]}")

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

        

        self.cmd_vel_pub.publish(cmd_vel)




    def searching(self):

            if self.first_iter:
                path = self.a_star_path_planner(self.ttbot_pose, self.goal_pose)

                #self.get_logger().info("we just ran Astar planer")
                if path is None:
                    self.get_logger().error("****Please Wait, just let Path count get to 3!*****")
                    self._have_goal = False
                    self.first_iter = False
                    return

                self._current_path = path
                self._last_idx = 0

            self.idx, current_goal = self.get_path_idx(self._current_path, self.ttbot_pose)
            self._last_idx = self.idx

            N = len(self._current_path.poses)
            self.get_logger().info(f"N = {N}, index = {self.idx}")

            # Stop the robot when final waypoint reached
            speed, heading = self.path_follower(self.ttbot_pose, current_goal)
            self.move_ttbot(speed, heading)
            
            if self.idx >= N-int(N*0.2)-3 or (self.remap):
                self.get_logger().info("Goal reached :Activate spin mode")
                self.move_ttbot(0.0, 0.0)
                self._have_goal = False
                self._current_path = None
                self._last_idx = 0
                self.first_iter = False
                self.idx = 0
                self.SpinMode = True
                self.SearchMode =False
                self.remap = False

                # for goal poses
                self.next_goal_pose = True

                msg = Twist()
                msg.linear.x = float(0.0)
                msg.linear.y = float(0.0)
                msg.linear.z = float(0.0)

                msg.angular.x = float(0.0)
                msg.angular.y = float(0.0)
                msg.angular.z = float(0.0)

                self.get_logger().info("Stopping turtle bot boy")
                self.pub_U.publish(msg)

            


def main(args=None):
    rclpy.init(args=args)

    node = SubscriberNode()
    rclpy.spin(node)

    rclpy.shutdown()

if __name__ == "__main__": # this will allow us to run the script from terminal
   main()
