// implementation code for Sphere object class

// include this class include file FIRST to ensure that it has
// everything it needs for internal self-consistency
#include "Sphere.hpp"

// other classes used directly in the implementation
#include "Ray.hpp"

#include "aabb.hpp"

// sphere-ray intersection
float
Sphere::intersect(const Ray &r) const
{
    // solve p=r.start-center + t*r.direction; p*p -radius^2=0
    float a = r.directionLengthSquared();
    Vec3 dc = r.start() - d_center;
    float b = 2*(r.direction() * dc);
    float c = dc*dc - d_radius*d_radius;

    float discriminant = b*b - 4*a*c;
    if (discriminant < 0) 	// no intersection
	return r.far();

    // solve quadratic equation for desired surface
    float dsq = sqrt(discriminant);
    float t = (-b - dsq) / (2*a); // first intersection in front of start?
    if (t > r.near()) return t;
    t = (-b + dsq) / (2*a);	// second intersection in front of start?
    if (t > r.near()) return t;
  
    return r.far();		// sphere entirely behind start point
}

// appearance of sphere at position t on ray r
const Vec3
Sphere::appearance(World &w, const Ray &r, float t) const
{
    Vec3 p = r.start() + r.direction() * t;	// intersection point
    Vec3 n = (p - d_center).normalize();

    return d_appearance.eval(w, p, n, r);
}

aabb Sphere::GetAABB()
{
	Vec3 size( d_radius, d_radius, d_radius );
	return aabb( d_center - size, size * 2 );
}

bool Sphere::IntersectBox(aabb & a_Box)
{	
	float dmin = 0;
	Vec3 v1 = a_Box.GetPos(), v2 = a_Box.GetPos() + a_Box.GetSize();
	if (d_center.x() < v1.x()) 
	{
		dmin = dmin + (d_center.x() - v1.x()) * (d_center.x() - v1.x());
	}
	else if (d_center.x() > v2.x())
	{
		dmin = dmin + (d_center.x() - v2.x()) * (d_center.x() - v2.x());
	}
	if (d_center.y() < v1.y())
	{
		dmin = dmin + (d_center.y() - v1.y()) * (d_center.y() - v1.y());
	}
	else if (d_center.y() > v2.y())
	{
		dmin = dmin + (d_center.y() - v2.y()) * (d_center.y() - v2.y());
	}
	if (d_center.z() < v1.z())
	{
		dmin = dmin + (d_center.z() - v1.z()) * (d_center.z() - v1.z());
	}
	else if (d_center.z() > v2.z())
	{
		dmin = dmin + (d_center.z() - v2.z()) * (d_center.z() - v2.z());
	}
	return (dmin <= d_radius * d_radius);
}