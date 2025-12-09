#include <iostream>
#include "node.hpp"// include node hpp file, also contains other includes



// wrapping ros around classes... I think ??

math_node::math_node() : Node("my_math_node"){


    // parameters
    this->declare_parameter<double>("a",10.0);
    this->declare_parameter<double>("b",5.0);

    a = this->get_parameter("a").as_double();
    b = this->get_parameter("b").as_double();


    // publishers
    pub_add = create_publisher<std_msgs::msg::Float64>("add_numbers",10);
    pub_subtract = create_publisher<std_msgs::msg::Float64>("subtract_numbers",10);
    pub_multiply = create_publisher<std_msgs::msg::Float64>("multiply_numbers",10);
    pub_divide = create_publisher<std_msgs::msg::Float64>("divide_numbers",10);

    // timer for publishers
    timer =  this->create_wall_timer(std::chrono::milliseconds(1000),std::bind(&math_node::timerCallback,this));

    // subscribers
    sub_add = create_subscription<std_msgs::msg::Float64>("add_numbers",10,std::bind(&math_node::add_callback,this,std::placeholders::_1));
    sub_subtract = create_subscription<std_msgs::msg::Float64>("subtract_numbers",10,std::bind(&math_node::sub_callback,this,std::placeholders::_1));
    sub_multiply = create_subscription<std_msgs::msg::Float64>("multiply_numbers",10,std::bind(&math_node::mult_callback,this,std::placeholders::_1));
    sub_divide = create_subscription<std_msgs::msg::Float64>("divide_numbers",10,std::bind(&math_node::divide_callback,this,std::placeholders::_1));
}


void math_node::timerCallback(){

    std_msgs::msg::Float64 sum_of_ab;
    sum_of_ab.data = add_sub_funcs.add(a,b);

    std_msgs::msg::Float64 subtraction_of_ab;
    subtraction_of_ab.data = add_sub_funcs.subtract(a,b);

    std_msgs::msg::Float64 multiplication_of_ab;
    multiplication_of_ab.data = multiply_divide_funcs.multiply(a,b);

    std_msgs::msg::Float64 division_of_ab;
    division_of_ab.data = multiply_divide_funcs.divide(a,b);


    //publishing
    pub_add->publish(sum_of_ab);
    pub_subtract->publish(subtraction_of_ab);
    pub_multiply->publish(multiplication_of_ab);
    pub_divide->publish(division_of_ab);
}



// subscriber call back funcs
void math_node::add_callback(const std_msgs::msg::Float64::SharedPtr msg ){

    RCLCPP_INFO(get_logger(),"a+b = %f", msg->data);

}

void math_node::sub_callback(const std_msgs::msg::Float64::SharedPtr msg ){

    RCLCPP_INFO(get_logger(),"a-b = %f", msg->data);

}

void math_node::mult_callback(const std_msgs::msg::Float64::SharedPtr msg ){

    RCLCPP_INFO(get_logger(),"a*b = %f", msg->data);

}

void math_node::divide_callback(const std_msgs::msg::Float64::SharedPtr msg ){

    RCLCPP_INFO(get_logger(),"a/b = %f", msg->data);

}


