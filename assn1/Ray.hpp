// Rays
#ifndef RAY_HPP
#define RAY_HPP

// other classes we use DIRECTLY in our interface
#include <stdio.h>
#include "Vec3.hpp"

#define SHADOWRAY_ID 500000
#define REFLECTRAY_ID 1000000
#define REFRACTRAY_ID 2000000

// a ray consists of a starting point and direction
// ray is defined as start + t*direction, for t>=0
class Ray {
    Vec3 d_start;	// ray start point
    Vec3 d_direction;	// ray direction
    float d_dsq;	// |direction|^2
    int d_bounces;	// number of bounces allowed for ray
    float d_influence;	// maximum contribution of this ray to the final image
    float d_ir;		// index of refraction for medium traversed by ray
    float d_near;	// closest to ray origin to count as intersection



public: // constructors
    Ray(int _rayID, int _worldcoordinateX, int _worldcoordinateY,
		Vec3 &wholegridarea_startingPosition, float _dx, float _dy, float _dz,
		const Vec3 &start, const Vec3 &direction, int bounces, 
		float influence, float ir, float near=1e-4)
	: d_start(start), d_direction(direction), d_dsq(direction*direction), 
	d_bounces(bounces), d_influence(influence), d_ir(ir), d_near(near),
	tmax_x(-1.0f), tmax_y(-1.0f), tmax_z(-1.0f),
	stepX(0), stepY(0), stepZ(0), tDelta(0.f, 0.f, 0.f), rayID(_rayID),
	worldCoordinateX(_worldcoordinateX), worldCoordinateY(_worldcoordinateY)
	{
		Vec3 p1(wholegridarea_startingPosition);
		float dx_reci = 1.0 / _dx, dy_reci = 1.0 / _dy, dz_reci = 1.0 / _dz;
		int x1 = (int)((start.x() - p1.x()) * dx_reci);//, x2 = (int)((bv2.x() - p1.x()) * dx_reci) + 1;
		x1 = (x1 < 0)?0:x1;//, x2 = (x2 > (GRIDSIZE - 1))?GRIDSIZE - 1:x2;
		int y1 = (int)((start.y() - p1.y()) * dy_reci);//, y2 = (int)((bv2.y() - p1.y()) * dy_reci) + 1;
		y1 = (y1 < 0)?0:y1;//, y2 = (y2 > (GRIDSIZE - 1))?GRIDSIZE - 1:y2;
		int z1 = (int)((start.z() - p1.z()) * dz_reci);//, z2 = (int)((bv2.z() - p1.z()) * dz_reci) + 1;
		z1 = (z1 < 0)?0:z1;//, z2 = (z2 > (GRIDSIZE - 1))?GRIDSIZE - 1:z2;

		// Now we have the grid No. -> traverse through Grids.
		// First, to determine tMaxX, tMaxY, tMaxZ, the ray intersects with the whole Grid cell area.
		//		m_Grid[z1][y1][x1].GetBox()->IntersectBox(Ray, dist);
		SetCurrentGridIndices(x1, y1, z1);
		InitGridData(_dx, _dy, _dz);
	}

	// For speed-up, data for Grid Traversal.
	// current grid index where the ray lies.
	int iX, iY, iZ;
	int rayID;

	// For speed-up, data for Grid Traversal.
	// current grid index where the ray lies.
	float tmax_x, tmax_y, tmax_z;
	int stepX, stepY, stepZ;
	Vec3 tDelta;

	// world coordinate to optimize shadow rays.
	int worldCoordinateX, worldCoordinateY;

	// which object did this ray hit last time?
	struct LastTime {
		int objID;
		float tt;
		LastTime()
		{
			objID = -1;
			tt = -1.0f;
		}
	} m_lasttime;

public: // accessors
    const Vec3 &start() const {return d_start;}
    const Vec3 &direction() const {return d_direction;}
    float directionLengthSquared() const {return d_dsq;}
    int bounces() const {return d_bounces;}
    float influence() const {return d_influence;}
    float ir() const {return d_ir;}

    // effective "infinity" for this ray
    float far() const {return INFINITY;}

    // effective "zero" for this ray (to avoid "self-intersection" errors)
    float near() const {return d_near;}

	// Set current grid indices
	void SetCurrentGridIndices(int x, int y, int z) { iX = x; iY = y; iZ = z; }
	void Set_tMax(Vec3 &_tMax) { tmax_x = _tMax.x(); tmax_y = _tMax.y(); tmax_z = _tMax.z(); }
	void SetSteps(int _stepX, int _stepY, int _stepZ) { stepX = _stepX; stepY = _stepY; stepZ = _stepZ; }
	void Set_tDelta(Vec3 &_tDelta) { this ->tDelta = _tDelta; }
	void InitGridData(float dx, float dy, float dz);
	Vec3 GetTMax() { return Vec3(tmax_x, tmax_y, tmax_z); }

	// TraverseGrid with the ray object

};


#endif
