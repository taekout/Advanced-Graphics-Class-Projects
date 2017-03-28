#ifndef RAY_CPP
#define RAY_CPP

#include "ray.hpp"

void Ray::InitGridData(float dx, float dy, float dz)
{
	int step_x, step_y, step_z ; 
	if(d_direction.x() > 0)
		step_x = 1;
	else if(d_direction.x() != 0)
		step_x = -1;
	else step_x = 0;
	if(d_direction.y() > 0)
		step_y = 1;
	else if(d_direction.y() != 0)
		step_y = -1;
	else step_y = 0;
	if(d_direction.z() > 0)
		step_z = 1;
	else if(d_direction.z() != 0)
		step_z = -1;
	else step_z = 0;
	SetSteps(step_x, step_y, step_z);

	// Now set Delta
	float dist[3];
	Vec3 d(d_direction), o(d_start);
	bool retval = 0; // 0 = MISS
	for ( int i = 0; i < 3; i++ ) dist[i] = -1; //init
	if (d.x()) 
	{ // dist[0/1/2] == tDelta for x/y/z.
		float rc = 1.0f / d.x();
		dist[0] = abs((dx) * rc);
	}
	if (d.y())
	{
		float rc = 1.0f / d.y();
		dist[1] = abs((dy) * rc);
	}
	if (d.z()) 
	{
		float rc = 1.0f / d.z();
		dist[2] = abs((dz) * rc);
	}
	Vec3 _tDelta(dist[0], dist[1], dist[2]);
	Set_tDelta(_tDelta);
}

#endif