// implementation code World object
// World holds everything we know about the world.
// Code here initializes it based on file input

// include this class include file FIRST to ensure that it has
// everything it needs for internal self-consistency
#include <iostream>
#include "World.hpp"

// local includes
#include "Polygon.hpp"
#include "Sphere.hpp"
#include "Cone.hpp"
#include "Appearance.hpp"
#include "aabb.hpp"
#include "Grid.hpp"
#include "Vec3.hpp"

// system includes
#include <stdio.h>
#include <math.h>

using namespace std;

#ifdef _WIN32
#pragma warning( disable: 4996 )
#endif

extern World world;

static int sphereID = SPHERE_ID;
static int polygonID = POLYGON_ID;
static int coneID = CONE_ID;

static void err()
{
    fprintf(stderr, "NFF file error\n");
    exit(1);
}

// read input file
// modeled somewhat after ReadNFF.c by Eduard [esp] Schwan
void World::read(FILE *f)
{
    int c;			// first character of line
    Appearance currentAppearance; // current object appearance

    while((c = getc(f)) != EOF) {
	switch(c) {
	case ' ': case '\t':	// white space and blank lines
	case '\f': case '\r': case '\n':
	    continue;

	case '#':			// comments
	    fscanf(f,"%*[^\n]");
	    break;

	case 'v': {			// view point
	    float x,y,z;

	    if (fscanf(f," from %f %f %f", &x, &y, &z) != 3) err();
	    eye = Vec3(x,y,z);

	    if (fscanf(f," at %f %f %f", &x, &y, &z) != 3) err();
	    view = (Vec3(x,y,z) - eye).normalize();

	    if (fscanf(f," up %f %f %f", &x, &y, &z) != 3) err();
	    right = (view ^ Vec3(x,y,z)).normalize();
	    up = right ^ view;

	    // solve w/2d = tan(fov/2), where w=2 and fov must be in radians
	    if (fscanf(f," angle %f", &x) != 1) err();
		float t = float(tan(x*M_PI/360));
	    right = right*t;
	    up = up*t;

	    if (fscanf(f," hither %f", &x) != 1) err();
	    hither = x;

	    if (fscanf(f, " resolution %d %d", &width, &height) != 2) err();

	    break;
	}

	case 'b': {			// background
	    float r, g, b;
	    if (fscanf(f,"%f %f %f", &r, &g, &b) != 3) err();
	    background = Vec3(r,g,b);

	    break;
	}

	case 'l': {			// light
	    float x,y,z;

	    // default light color if not read
	    float r=1, g=1, b=1;

	    if (fscanf(f,"%f %f %f %f %f %f", &x, &y, &z, &r, &g, &b) < 3)
		err();

	    // rescale existing lights according to NFF expectation
	    float lscale = 1/sqrt(lights.size()+1.f);
	    float ladjust = sqrt(float(lights.size()))*lscale;
	    for(LightList::iterator li=lights.begin(); li!=lights.end(); ++li)
		li->col = li->col*ladjust;

	    // add new light
		static int nLightID = 1;
	    lights.push_back(Light(Vec3(x,y,z),lscale*Vec3(r,g,b), nLightID ++));

	    break;
	}

	case 'f': {			// fill/material properties
	    float r,g,b,kd,ks,e,kt,ir;
	    if (fscanf(f,"%f %f %f %f %f %f %f %f",
		       &r,&g,&b,&kd,&ks,&e,&kt,&ir) != 8) err();
	    // note that ka=0 and kr=ks
	    currentAppearance = Appearance(Vec3(r,g,b),0,kd,ks,e,ks,kt,ir);
		   
	    break;
	}

	case 'c': {			// cone or cylinder
	    float bx,by,bz,br;
	    if (fscanf(f," %f %f %f %f",&bx,&by,&bz,&br) != 4) err();

	    float ax,ay,az,ar;
	    if (fscanf(f," %f %f %f %f",&ax,&ay,&az,&ar) != 4) err();

	    objects->addObject(new Cone(coneID ++, currentAppearance,
				       Vec3(bx,by,bz), br,
				       Vec3(ax,ay,az), ar));

	    break;
	}

	case 's': {			// sphere
	    float x,y,z,r;
	    if (fscanf(f," %f %f %f %f",&x,&y,&z,&r) != 4) err();
	    objects->addObject(new Sphere(sphereID++, currentAppearance,
					 Vec3(x, y, z), r));
	    
	    break;
	}

	case 'p': {			// p or pp polygon primitives
	    int i, nv;
	    float x,y,z, nx,ny,nz;

	    // p primitive with single facet normal?
	    if (fscanf(f,"%d", &nv) == 1) {
		if (nv < 3) err();

		Polygon *poly = new Polygon(polygonID++, currentAppearance, false);

		// read first three to get facet normal
		// not actually used yet!
		if (fscanf(f," %f %f %f", &x, &y, &z) != 3) err();
		Vec3 v0(x,y,z);

		if (fscanf(f," %f %f %f", &x, &y, &z) != 3) err();
		Vec3 v1(x,y,z);

		if (fscanf(f," %f %f %f", &x, &y, &z) != 3) err();
		Vec3 v2(x,y,z);

		Vec3 n = (v2-v1)^(v1-v0);
		poly->addVertex(v0,n);
		poly->addVertex(v1,n);
		poly->addVertex(v2,n);
		
		// read remaining vertices
		for(i=3; i<nv; ++i) {
		    if (fscanf(f," %f %f %f", &x, &y, &z) != 3) err();
		    poly->addVertex(Vec3(x,y,z),n);
		}

		poly->closePolygon();
		objects->addObject(poly);
	    }
	    // pp primitive with per-vertex normals?
	    else if (fscanf(f,"p %d", &nv) == 1) {
		Polygon *poly = new Polygon(polygonID ++, currentAppearance, true);

		// read all vertices
		for(i=0; i<nv; ++i) {
		    if (fscanf(f," %f %f %f %f %f %f",
			       &x, &y, &z, &nx, &ny, &nz) != 6) err();
		    poly->addVertex(Vec3(x,y,z),Vec3(nx,ny,nz));
		}

		poly->closePolygon();
		objects->addObject(poly);
	    }
	    else
		err();

	    break;
	}
	default:
	    err();
	}
    }
}

Intersection World::TraverseGrids(Ray *ray)
{
	/*
	At this point, add
	1. determine which grid the view point is in.
	2. if it is outside, intersect the m_Extends aabb box.
	3. if it is inside the extend grid area, start from the corresponding grid.
	4. traverse through grids.
		4.5 while traversing, intersecting with objs in each grid.
	*/
	// 1.
	if(m_Extends.Contains(eye))
	{
		// 2. Inside
		// If it is inside the whole grid area, just find which grid it is in.

		// Now we have the grid No. -> traverse through Grids.
		// First, to determine tMaxX, tMaxY, tMaxZ, the ray intersects with the whole Grid cell area.
		m_Grid[ray->iZ][ray->iY][ray->iX].GetBox() ->Set_tMaxForRay(*ray);
		// Now ray data(grid data) have been set. Go on to traverse through grids.
		return GoToNearestGrid(*ray);
	}
	else
	{
		// If it is outside the whole grid area, intersect with the grid m_Extends.(to find where it intersects. Then it will traverse from the point.)
	}
	return Intersection();
}

void World::InitializeObjectList()
{
	objects = new ObjectList(this);
}

Intersection World::GoToNearestGridForShadowRayOptimized(Ray &ray, int nCurLightID)
{
	int outX, outY , outZ;
	outX = outY = outZ = GRIDSIZE;
	while (1)
	{
		int X = ray.iX, Y = ray.iY, Z = ray.iZ;
		ObjectList *objList_curGrid = m_Grid[Z][Y][X].GetObjectList();
		//		cout << objList_curGrid << endl;
		aabb * curGrid = m_Grid[Z][Y][X].GetBox(); // I give out this to check the intersection happened in the grid where the ray lies.
		Intersection gridIntersections = objList_curGrid ->TraceForShadowRay(ray, nCurLightID, curGrid);
		if(gridIntersections.t() != INFINITY)
		{
			return gridIntersections;
		}
		if (ray.tmax_x < ray.tmax_y)
		{
			if (ray.tmax_x < ray.tmax_z)
			{
				ray.iX += ray.stepX;//X = X + stepX;
				if(ray.iX == outX || ray.iX == -1) return Intersection();//if (X == outX) return MISS;
				ray.tmax_x += ray.tDelta.x(); //tmax.x += tdelta.x;
			}
			else
			{
				ray.iZ += ray.stepZ;  // Z = Z + stepZ;
				if(ray.iZ == outZ || ray.iZ == -1) return Intersection(); //if (Z == outZ) return MISS;
				ray.tmax_z += ray.tDelta.z(); //tmax.z += tdelta.z;
			}
		}
		else
		{
			if (ray.tmax_y < ray.tmax_z)
			{
				ray.iY += ray.stepY; //Y = Y + stepY;
				if(ray.iY == outY || ray.iY == -1) return Intersection(); //if (Y == outY) return MISS;
				ray.tmax_y += ray.tDelta.y(); //tmax.y += tdelta.y;
			}
			else
			{
				ray.iZ += ray.stepZ; //Z = Z + stepZ;
				if(ray.iZ == outZ || ray.iZ == -1)  return Intersection(); //if (Z == outZ) return MISS;
				ray.tmax_z += ray.tDelta.z(); //tmax.z += tdelta.z;
			}
		}
	}
}

Intersection World::GoToNearestGrid(Ray &ray)
{
	int outX, outY , outZ;
	outX = outY = outZ = GRIDSIZE;
	while (1)
	{
		int X = ray.iX, Y = ray.iY, Z = ray.iZ;
		ObjectList *objList_curGrid = m_Grid[Z][Y][X].GetObjectList();
//		cout << objList_curGrid << endl;
		aabb * curGrid = m_Grid[Z][Y][X].GetBox(); // I give out this to check the intersection happened in the grid where the ray lies.
		Intersection gridIntersections = objList_curGrid ->trace(ray, curGrid);
		if(gridIntersections.t() != INFINITY)
		{
			return gridIntersections;
		}
		if (ray.tmax_x < ray.tmax_y)
		{
			if (ray.tmax_x < ray.tmax_z)
			{
				ray.iX += ray.stepX;//X = X + stepX;
				if(ray.iX == outX || ray.iX == -1) return Intersection();//if (X == outX) return MISS;
				ray.tmax_x += ray.tDelta.x(); //tmax.x += tdelta.x;
			}
			else
			{
				ray.iZ += ray.stepZ;  // Z = Z + stepZ;
				if(ray.iZ == outZ || ray.iZ == -1) return Intersection(); //if (Z == outZ) return MISS;
				ray.tmax_z += ray.tDelta.z(); //tmax.z += tdelta.z;
			}
		}
		else
		{
			if (ray.tmax_y < ray.tmax_z)
			{
				ray.iY += ray.stepY; //Y = Y + stepY;
				if(ray.iY == outY || ray.iY == -1) return Intersection(); //if (Y == outY) return MISS;
				ray.tmax_y += ray.tDelta.y(); //tmax.y += tdelta.y;
			}
			else
			{
				ray.iZ += ray.stepZ; //Z = Z + stepZ;
				if(ray.iZ == outZ || ray.iZ == -1)  return Intersection(); //if (Z == outZ) return MISS;
				ray.tmax_z += ray.tDelta.z(); //tmax.z += tdelta.z;
			}
		}
	}
}


void World::BuildGrid()
{
	/// p1.x/y/z must be smaller than p2.x/y/z respectively.
	Vec3 p1(WORLD_COORDINATE_MIN), p2(WORLD_COORDINATE_MAX);//p1(-14, -5, -6), p2( 14, 8, 30 );
	// calculate cell width, height and depth
	float dx = (p2.x() - p1.x()) / GRIDSIZE, dx_reci = 1.0f / dx;
	float dy = (p2.y() - p1.y()) / GRIDSIZE, dy_reci = 1.0f / dy;
	float dz = (p2.z() - p1.z()) / GRIDSIZE, dz_reci = 1.0f / dz;
	m_dx = dx; m_dy = dy; m_dz = dz; m_dx_reci = dx_reci; m_dy_reci = dy_reci; m_dz_reci = dz_reci;
	float _x = p1.x(), _y = p1.y() , _z = p1.z();
	float curX = _x, curY = _y, curZ = _z;
	Vec3 size(dx, dy, dz);

	// initialize regular grid
	for(int i = 0 ; i < GRIDSIZE ; i ++)
	{
		curZ = dz * i + _z;
		for(int j = 0; j < GRIDSIZE ; j++)
		{
			curY = dy * j + _y;
			for(int k = 0 ; k < GRIDSIZE ; k++)
			{
				curX = dx * k + _x;
				Vec3 pos(curX, curY, curZ);
				aabb *tmp = new aabb(pos, size);
				m_Grid[i][j][k].SetBox(*tmp);
				m_Grid[i][j][k].GetBox()->SetGridIndex(k, j, i);
				m_Grid[i][j][k].AllocateObjectList(this);
				delete tmp;
			}
		}
	}

	m_Extends = aabb( p1, p2 - p1 ); // Check m_Extends. WHy need aabb class instead of Grid? => Yes, we need it to save the whole grid area.
	//m_Light = new Primitive*[MAXLIGHTS];
	//m_Lights = 0;
	// store primitives in the grid cells
	for(ObjectList::t_List::iterator i = objects->d_list.begin() ; i != objects->d_list.end() ; ++i)
	{ // for all objects
		//if (m_Primitive[p]->IsLight()) m_Light[m_Lights++] = m_Primitive[p];
		aabb bound = (*i) ->GetAABB();//objectsdsfd[p]->GetAABB();
		Vec3 bv1 = bound.GetPos(), bv2 = bound.GetPos() + bound.GetSize();
		// find out which cells could contain the primitive (based on aabb)
		int x1 = (int)((bv1.x() - p1.x()) * dx_reci), x2 = (int)((bv2.x() - p1.x()) * dx_reci);
		x1 = (x1 < 0)?0:x1, x2 = (x2 > (GRIDSIZE - 1))?GRIDSIZE - 1:x2;
		int y1 = (int)((bv1.y() - p1.y()) * dy_reci), y2 = (int)((bv2.y() - p1.y()) * dy_reci);
		y1 = (y1 < 0)?0:y1, y2 = (y2 > (GRIDSIZE - 1))?GRIDSIZE - 1:y2;
		int z1 = (int)((bv1.z() - p1.z()) * dz_reci), z2 = (int)((bv2.z() - p1.z()) * dz_reci);
		z1 = (z1 < 0)?0:z1, z2 = (z2 > (GRIDSIZE - 1))?GRIDSIZE - 1:z2;
		// loop over candidate cells
		for( int z = z1; z <= z2; z++ )
		{
			for ( int y = y1; y <= y2; y++ )
			{
				for ( int x = x1; x <= x2; x++ )
				{
					// construct aabb for current cell
//					int idx = x + y * GRIDSIZE + z * GRIDSIZE * GRIDSIZE;
//					Vec3 pos( p1.x() + x * dx, p1.y() + y * dy, p1.z() + z * dz );
//					aabb cell( pos, Vec3( dx, dy, dz ) );
					// do an accurate aabb / primitive intersection test
//					if (m_Grid[z][y][x].IntersectBox( bound ))
//					{
						// object intersects cell; add to object list
						m_Grid[z][y][x].SetObject((*i), this);
//					}
				}
			}
		}
	}
	return;
}

void World::InitializeGrid(void)
{
}
