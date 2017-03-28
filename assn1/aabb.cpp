#include "aabb.hpp"
#include "Ray.hpp"


void aabb::Set_tMaxForRay(Ray &ray)
{
	float _tmaxX, _tmaxY, _tmaxZ;
	Vec3 p1 = GetPos(), p2 = GetPos() + GetSize();
	if(ray.stepX > 0){
		float dc = abs(1.0 / ray.direction().x());
		_tmaxX = (p2.x() - ray.start().x()) * dc;
	}
	else if(ray.stepX < 0){
		float dc = abs(1.0 / ray.direction().x());
		_tmaxX = (ray.start().x() - p1.x()) * dc;
	}
	else {
		_tmaxX = INFINITY;
	}

	if(ray.stepY > 0){
		float dc = abs(1.0 / ray.direction().y());
		_tmaxY = (p2.y() - ray.start().y()) * dc;
	}
	else if(ray.stepY < 0){
		float dc = abs(1.0 / ray.direction().y());
		_tmaxY = (ray.start().y() - p1.y()) * dc;
	}
	else {
		_tmaxY = INFINITY;
	}

	if(ray.stepZ > 0){
		float dc = abs(1.0 / ray.direction().z());
		_tmaxZ = (p2.z() - ray.start().z()) * dc;
	}
	else if(ray.stepZ < 0){
		float dc = abs(1.0 / ray.direction().z());
		_tmaxZ = (ray.start().z() - p1.z()) * dc;
	}
	else {
		_tmaxZ = INFINITY;
	}
	Vec3 tMax(_tmaxX, _tmaxY, _tmaxZ);
	ray.Set_tMax(tMax);
}


/*


int aabb::IntersectBox( Ray& a_Ray, float& a_Dist )
{
	float dist[6];
	Vec3 ip[6], d = a_Ray.direction(), o = a_Ray.start();
	bool retval = 0; // 0 = MISS
	for ( int i = 0; i < 6; i++ ) dist[i] = -1; //init
	Vec3 v1 = GetPos(), v2 = GetPos() + GetSize();
	if (d.x()) 
	{ // dist[0-5] must be positive values.(cuz they are tMax value. t must be positive
		// since t is a ray parameter. ray only moves forward!
		float rc = 1.0f / d.x();
		dist[0] = abs((o.x() - v1.x()) * rc);
		dist[3] = abs((o.x() - v2.x()) * rc);
	}
	if (d.y())
	{
		float rc = 1.0f / d.y();
		dist[1] = abs((o.y() - v1.y()) * rc);
		dist[4] = abs((o.y() - v2.y()) * rc);
	}
	if (d.z()) 
	{
		float rc = 1.0f / d.z();
		dist[2] = abs((o.z() - v1.z()) * rc);
		dist[5] = abs((o.z() - v2.z()) * rc);
	}
	for ( int i = 0; i < 6; i++ ) if (dist[i] > 0)
	{
		// Dist == tMaxX, tMaxY, tMaxz --> Update it in the ray object.
		ip[i] = o + dist[i] * d;
		if ((ip[i].x() > (v1.x() - EPSILON)) && (ip[i].x() < (v2.x() + EPSILON)) && 
			(ip[i].y() > (v1.y() - EPSILON)) && (ip[i].y() < (v2.y() + EPSILON)) &&
			(ip[i].z() > (v1.z() - EPSILON)) && (ip[i].z() < (v2.z() + EPSILON)))
		{
			if (dist[i] < a_Dist) 
			{
				a_Dist = dist[i];
				retval = 1; // 1 == HIT
			}
		}
	}
	float x, y, z;
	for(int i = 0 ; i < 6 ; i ++)
	{
		if(dist[i] < 0)
			dist[i] = INFINITY;
	}
	if(dist[0] > dist[3])
		x = dist[3];
	else
		x = dist[0];
	if(dist[1] > dist[4])
		y = dist[4];
	else
		y = dist[1];
	if(dist[2] > dist[5])
		z = dist[5];
	else
		z = dist[2];
	Vec3 _tMax(x, y, z);
	a_Ray.Set_tMax(_tMax);
	return retval;
}
*/

bool SmartContains(Vec3 a_Pos)
{
	return false;

}


bool aabb::SmartIntersect(aabb &b2)
{
	Vec3 v1 = b2.GetPos(), v2 = b2.GetPos() + b2.GetSize(); // input cell's box
	Vec3 v3 = m_Pos, v4 = m_Pos + m_Size; // this instance's box
	float minx = 10000000000.0f,  maxx = -10000000000.f,
		miny = 10000000000.f,  maxy = -10000000000.f,
		minz = 10000000000.f,  maxz = -10000000000.f;
	float minx2 = 10000000000.0f,  maxx2 = -10000000000.f,
		miny2 = 10000000000.f,  maxy2 = -10000000000.f,
		minz2 = 10000000000.f,  maxz2 = -10000000000.f;
	// about v1 and v2
	if(v1.x() < v2.x())
	{
		minx = v1.x(); maxx = v2.x();
	}
	else
	{
		minx = v2.x(); maxx = v1.x();
	}
	if(v1.y() < v2.y())
	{
		miny = v1.y(); maxy = v2.y();
	}
	else
	{
		miny = v2.y(); maxy = v1.y();
	}
	if(v1.z() < v2.z())
	{
		minz = v1.z(); maxz = v2.z();
	}
	else
	{
		minz = v2.z(); maxz = v1.z();
	}

	// about v3 and v4
	if(v3.x() < v4.x())
	{
		minx2 = v3.x(); maxx2 = v4.x();
	}
	else
	{
		minx2 = v4.x(); maxx2 = v3.x();
	}
	if(v3.y() < v4.y())
	{
		miny2 = v3.y(); maxy2 = v4.y();
	}
	else
	{
		miny2 = v4.y(); maxy2 = v3.y();
	}
	if(v3.z() < v4.z())
	{
		minz2 = v3.z(); maxz2 = v4.z();
	}
	else
	{
		minz2 = v4.z(); maxz2 = v3.z();
	}
	// now min_ max_ have been set.
	return !( (minx > maxx2) || (minx2 > maxx) || (miny > maxy2) || (miny2 > maxy) || (minz > maxz2) || (minz2 > maxz));
}