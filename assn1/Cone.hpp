// cone objects
#ifndef CONE_HPP
#define CONE_HPP

// other classes we use DIRECTLY in the interface
#include "Object.hpp"
#include "Vec3.hpp"

// classes we only use by pointer or reference
class Appearance;
class World;
class Ray;

// cone objects
class Cone : public Object {
    Vec3 d_base, d_axis;	// base point and axis vector
    float d_rBase, d_rDiff;	// radius at base and difference to apex
    Vec3 d_scaledAxis;		// axis divided by squared length

public:	// constructors
    Cone(int nID, const Appearance &appearance, 
	 const Vec3 &base, float base_radius,
	 const Vec3 &apex, float apex_radius);

public: // object functions
    float intersect(const Ray &ray) const;
	bool IntersectBox(aabb &a_Box);
    const Vec3 appearance(World &w, const Ray &ray, float t) const;
	aabb GetAABB();
};

#endif
