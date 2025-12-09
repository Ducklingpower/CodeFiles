#pragma once
#include <iostream>

#include <rclcpp/rclcpp.hpp> // ros includes
#include <std_msgs/msg/float64.hpp>

#include "add_sub.hpp"// class includs
#include "mult_divide.hpp"


class math_node: public rclcpp::Node{

    // init vars
    double a;
    double b;

    rclcpp::TimerBase::SharedPtr timer;



    // all publishers init
    rclcpp::Publisher<std_msgs::msg::Float64>::SharedPtr pub_add;
    rclcpp::Publisher<std_msgs::msg::Float64>::SharedPtr pub_subtract;
    rclcpp::Publisher<std_msgs::msg::Float64>::SharedPtr pub_multiply;
    rclcpp::Publisher<std_msgs::msg::Float64>::SharedPtr pub_divide;

    // all subscriber init
    rclcpp::Subscription<std_msgs::msg::Float64>::SharedPtr sub_add;
    rclcpp::Subscription<std_msgs::msg::Float64>::SharedPtr sub_subtract;
    rclcpp::Subscription<std_msgs::msg::Float64>::SharedPtr sub_multiply;
    rclcpp::Subscription<std_msgs::msg::Float64>::SharedPtr sub_divide;

    // class instances

    add_sub add_sub_funcs;
    multiply_divide multiply_divide_funcs;





public:

    math_node(); 

private: 

    

    //callbacks for the subscribers
    void add_callback(const std_msgs::msg::Float64::SharedPtr msg_data);
    void sub_callback(const std_msgs::msg::Float64::SharedPtr msg_data);
    void mult_callback(const std_msgs::msg::Float64::SharedPtr msg_data);
    void divide_callback(const std_msgs::msg::Float64::SharedPtr msg_data);

    void timerCallback();

};