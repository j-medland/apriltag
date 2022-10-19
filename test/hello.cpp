#include <string>
#include <iostream>
#include "apriltag/apriltag.h"

int main(int argc, char *argv[])
{
    std::cout << "hello" << std::endl;
    auto d = apriltag_detector_create();
    apriltag_detector_destroy(d);

}
