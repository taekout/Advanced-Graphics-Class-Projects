// Everything we know about the world
#ifndef World_hpp
#define World_hpp

// other classes we use DIRECTLY in our interface
#include "Vec3.hpp"
#include "Grid.hpp"
#include "ObjectList.hpp"
#include <list>
#include <stdio.h>

#define THREADNO 50
#define GRIDSIZE 250
#define WORLD_COORDINATE_MIN	-12.5,-12.5,-6
#define WORLD_COORDINATE_MAX	12.5,12.5,6

#define SPHERE_ID 10
#define POLYGON_ID 1000
#define CONE_ID 100000

struct Light {
    Vec3 pos;			// light position
    Vec3 col;			// light color
	int nLightID;		// light ID
    Light(Vec3 p, Vec3 c, int _nLightID) : pos(p), col(c), nLightID(_nLightID) {}
};
typedef std::list<Light> LightList;

class World {
public:// construct with defaults (where appropriate)
    World() :
	width(512), height(512),
	background(.5f,.7f,.9f),
	hither(1),
	eye(0,0,0),view(0,0,1),up(0,1,0),right(1,0,0)
	, m_dx(0.0f) , m_dy(0.0f) , m_dz(0.0f)
	, m_dx_reci(0.0f), m_dy_reci(0.0f), m_dz_reci(0.0f)
    {
		InitializeObjectList();
		for(int i = 0 ; i < 1024 ; i ++)
			for(int j = 0 ; j < 1024 ; j++)
			{
				shadowrayOptimization[i][j].coorX = j;
				shadowrayOptimization[i][j].coorY = i;
			}
	}

public:// world data -- somewhat poor form, but I'm making this
       // directly accessible for now.
    // image size
    int width, height;
    // background color
    Vec3 background;
    // near clipping plane distance
    float hither;
    // view origin and basis parameters
    Vec3 eye, view, up, right;
    // list of objects in the scene
    ObjectList *objects;
	// list of grids in the scene
	Grid m_Grid[GRIDSIZE][GRIDSIZE][GRIDSIZE];


	// aabb(axis aligned bounding box)
	aabb m_Extends;
    // list of lights
    LightList lights;
	// dx, dy , dz , 1/dx ,etc.
	float m_dx, m_dy, m_dz;
	float m_dx_reci, m_dy_reci, m_dz_reci;

	struct ShadowRayOptimization
	{
		int lightID[7];
//		int hitObjID[7];
		Object *pObj[7];
		int coorX, coorY;
		ShadowRayOptimization()
		{
			for(int i = 0 ; i < 7 ; i++)
			{
				lightID[i] = -1;
				pObj[i] = NULL;
			}
			coorX = coorY = -1;
		}
	} shadowrayOptimization[1024][1024];

public:// read world data from a file
    void read(FILE *f);
	void BuildGrid();
	Intersection TraverseGrids(Ray *ray);
	float GetGridSizeX() { return m_dx; }
	float GetGridSizeY() { return m_dy; }
	float GetGridSizeZ() { return m_dz; }
	Intersection GoToNearestGrid(Ray &ray);
	Intersection GoToNearestGridForShadowRayOptimized(Ray &shadowRay, int curLightID);
	void InitializeGrid(void);
	void InitializeObjectList();
};


#endif