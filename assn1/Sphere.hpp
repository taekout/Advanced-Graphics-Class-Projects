// sphere objects
#ifndef SPHERE_HPP
#define SPHERE_HPP

// other classes we use DIRECTLY in the interface
#include "Object.hpp"
#include "Vec3.hpp"

// classes we only use by pointer or reference
class Appearance;
class World;
class Ray;

// sphere objects
class Sphere : public Object {
    Vec3 d_center;
    float d_radius;

public:	// constructors
    Sphere(int nID, const Appearance &appearance, const Vec3 &center, float radius)
	: Object(nID, appearance), d_center(center), d_radius(radius) {}

public: // object functions
    float intersect(const Ray &ray) const;
	bool IntersectBox(aabb &a_Box);
    const Vec3 appearance(World &w, const Ray &ray, float t) const;
	aabb GetAABB();
};

#endif
