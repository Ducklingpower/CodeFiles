cmake_minimum_required(VERSION 3.8)
project(task_2_interfaces)

# adding lnes ---- so that I can build my packages with my custom interfaces ----------


find_package(rosidl_default_generators REQUIRED)   # Turn mesg/srv into code
find_package(geometry_msgs REQUIRED)               # using geometry_msgs/Point32


rosidl_generate_interfaces(${PROJECT_NAME}         
  "msg/JointData.msg"                              
  "srv/JointState.srv"                            
  DEPENDENCIES geometry_msgs                       

)                                                  


#--------------------------------------------------------------------------------------
if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  # the following line skips the linter which checks for copyrights
  # comment the line when a copyright and license is added to all source files
  set(ament_cmake_copyright_FOUND TRUE)
  # the following line skips cpplint (only works in a git repo)
  # comment the line when this package is in a git repo and when
  # a copyright and license is added to all source files
  set(ament_cmake_cpplint_FOUND TRUE)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()
