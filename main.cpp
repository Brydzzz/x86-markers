#include <iostream>
#include <stdexcept>
#include <fstream>

#include <stdio.h>
#include <string.h>

// #define fname "./test_bmps/example_markers.bmp"

#define HEIGHT 240
#define WIDTH 320

#define HEADER_SIZE 54
#define MAX_NUMBER_OF_MARKERS 50

extern "C" int find_markers(char *bitmap, unsigned int *x_pos, unsigned int *y_pos);

int main(int argc, char *argv[])
{
    std::string fname;
    if (argc <= 1)
    {
        std::cout << "File not specified\n";
        return -1;
    }
    else if (argc > 2)
    {
        std::cout << "Too many arguments\n";
        return -1;
    }
    fname = argv[1];
    std::ifstream fileHandler;
    fileHandler.open(fname, std::ios::binary);
    if (fileHandler.good())
        std::cout << "File opened succesfully\n";
    else
    {
        std::cout << "Unable to open file\n";
        return -2;
    }

    // read header
    char header[HEADER_SIZE];
    fileHandler.read(header, HEADER_SIZE);

    auto fileSize = *reinterpret_cast<uint32_t *>(&header[2]);
    auto dataOffset = *reinterpret_cast<uint32_t *>(&header[10]);
    auto width = *reinterpret_cast<uint32_t *>(&header[18]);
    auto height = *reinterpret_cast<uint32_t *>(&header[22]);

    uint32_t numOfPix = HEIGHT * WIDTH;
    fileHandler.seekg(dataOffset); // change current read postion
    char image[3 * numOfPix];
    fileHandler.read(image, 3 * numOfPix);

    // declare arrays to store x and y coordinates of detected markers
    unsigned int x_positions[MAX_NUMBER_OF_MARKERS];
    unsigned int y_positions[MAX_NUMBER_OF_MARKERS];

    int numOfMarkers = find_markers(image, x_positions, y_positions);
    // std::cout << numOfMarkers << std::endl;
    for (int i = 0; i < numOfMarkers; ++i)
    {
        std::cout << "Marker no." << i + 1 << " at row:" << y_positions[i] << " and column: " << x_positions[i] << '\n';
    }
    std::cout << "End of program.\n";
    return 0;
}