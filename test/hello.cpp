#include <string>
#include <iostream>
#include "apriltag/apriltag.h"
#include "apriltag/tagStandard41h12.h"

int main(int argc, char *argv[])
{
    std::cout << "hello" << std::endl;
    apriltag_family_t *tf = tagStandard41h12_create();
    apriltag_detector_t *td = apriltag_detector_create();
    apriltag_detector_add_family_bits(td, tf, 1);
    auto img = apriltag_to_image(tf,10);
    std::cout << tf->ncodes << std::endl;
    apriltag_image_write_pnm(img, "out.pnm");
    apriltag_image_destroy(img);
    apriltag_detector_destroy(td);
    tagStandard41h12_destroy(tf);
}
