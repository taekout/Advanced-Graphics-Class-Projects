// ray tracer main program
// includes input file parsing and spawning screen pixel rays

// classes used directly by this file
#include "ObjectList.hpp"
#include "Polygon.hpp"
#include "Sphere.hpp"
#include "Ray.hpp"
#include "World.hpp"
#include "Vec3.hpp"

// standard includes
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <iostream>
#include <list>
#include <time.h>
#include <process.h>
#include <fstream>

using namespace std;

#ifdef _WIN32
#pragma warning( disable: 4996 )
#endif

World world;

typedef struct rayInfo
{
	int threadID;
	Vec3 dir0;
	Vec3 dx;
	Vec3 dy;
	World *world;
	rayInfo(int _threadID, Vec3 _dir0, Vec3 _dx, Vec3 _dy, World *_world)
	{
		threadID = _threadID; dir0 = _dir0; dx = _dx; dy = _dy; world = _world;
	}
} rayInfo;

unsigned char (*pixels)[3];


unsigned __stdcall Traverse( void* info )
{
	rayInfo *rayinfo = (rayInfo *)info;
	Vec3 dir0 = rayinfo->dir0;
	Vec3 dx = rayinfo->dx, dy = rayinfo->dy;
	int threadID = rayinfo->threadID;
	int height = rayinfo->world->height;
	int width = rayinfo->world->width;
	World *world = rayinfo->world;


	// spawn a ray for each pixel and place the result in the pixel
	Vec3 dir;				// current ray direction
	int i,j;				// pixel index on screen
	unsigned char (*pixel)[3] = pixels;	// current pixel

	int offset = threadID - 1;
	pixel += offset;
	for( j = 0; j < height; ++j, dir0 = dir0 + dy) {
		//if (j % 32 == 0) printf("line %d\n",j); // show current line
		for( i = offset, dir = dir0 + dx * float(offset) ; i < width ; i += THREADNO, pixel += THREADNO, dir = dir + dx * THREADNO) {
			// new ray allowing up to 5 bounces, ray contribution=1,
			// index of refraction=1, don't trace closer than hither plane
			Ray ray(j * height + i + 1, i, j, world->m_Extends.GetPos(), world->m_dx, world->m_dy, world->m_dz,
				world->eye, dir, 5, 1, 1, world->hither); // ray Id starts from 1.
			ray.InitGridData(world->GetGridSizeX(), world->GetGridSizeY(), world->GetGridSizeZ());
			Vec3 col = world->TraverseGrids(&ray).appearance(*world, ray);
//			Vec3 col = world->objects.trace(ray).appearance(*world, ray);
			(*pixel)[0] = col.r();
			(*pixel)[1] = col.g();
			(*pixel)[2] = col.b();
//			if(i == 256 && j == 256)
//				printf("");
		}
		offset = i - width;
	}
	_endthreadex( 0 );
    return 0;
} 

int main(int argc, char **argv)
{
    // everything we know about the world
    // image parameters, camera parameters

    // short version of program name
    char *progname = strrchr(argv[0], '/');
    if (progname) progname += 1;
    else progname = argv[0];

    // parse command line
	FILE *input = fopen(argv[1], "r");
	if(input == NULL)
	{
		printf("Exit\n");
		exit(-1);
	}
	/*while (argc > 1) {
		if (strcmp(*argv, "-f")==0 && argc > 2) {
		    input = fopen(argv[1], "r");
			argc -= 2; argv += 2;
		    break;
		}

	    printf("usage: %s [options]\n"
		   "legal options are:\n"
		   "\t-f filename: use input file filename instead of stdin\n",
		   progname);
	    return 1;
    }*/

    // read input file to set lists of lights and spheres  
//	__time64_t  t1, t2;
//	_time64(&t1);
	int clo = clock();
    world.read(input);
    fclose(input);

	world.BuildGrid();

    // array of image data in ppm-file order
    pixels = new unsigned char[world.height*world.width][3];
    // vectors to step one pixel to the right and one pixel down
    // i= -1 to 1 maps to x= -.5 to width-.5
    // x = (i+.5)*2/width - 1;  y = (j+.5)*2/height - 1;
    Vec3 dx = world.right*(2.f/world.width), dy = world.up*(-2.f/world.height);

    // ray direction to first pixel of scan line
    Vec3 dir0 = world.view +
	(-1+1.f/world.width)*world.right + 
	(1-1.f/world.height)*world.up;

	HANDLE hThread[THREADNO];
	unsigned threadID[THREADNO];
	rayInfo *info[THREADNO];
	for(int i = 0 ; i < THREADNO ; i ++)
	{ // THread Creation
		info[i] = new rayInfo(i+1, dir0, dx, dy, &world);
		hThread[i] = (HANDLE) _beginthreadex(NULL, 0, &Traverse, info[i], 0, &threadID[i]);
	}
	// Thread Join here.
	for(int i = 0 ; i < THREADNO ; i++)
		WaitForSingleObject( hThread[i], INFINITE );
//	_time64(&t2);
//	double diff = difftime(t2, t1);
	int clo2 = clock();
	cout << "Execution Time : " << double(clo2 - clo) / 1000.0 << endl;
	printf("done\n");

    // write ppm file of pixels
    FILE *output = fopen("trace.ppm","wb");
    fprintf(output, "P6\n%d %d\n%d\n", world.width, world.height, 255);
    fwrite(pixels, world.height*world.width*3, 1, output);
    fclose(output);

	fstream out;
	out.open("result.txt", fstream::in | fstream::out | fstream::app);
	out << argv[1] << "," << double(clo2 - clo) / 1000.0 << endl;
	out.close();

    delete[] pixels;
	system("convert trace.ppm trace.jpg");
    return 0;
}

