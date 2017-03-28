// virtual class for any object
#ifndef OBJECT_HPP
#define OBJECT_HPP

// other classes we use DIRECTLY in our interface
#include "Appearance.hpp"
#include "Vec3.hpp"
#include "aabb.hpp"

// classes we only use by pointer or reference
class World;
class Ray;

class Object {
protected:	// data visible to children
    Appearance d_appearance;	// this object's appearance parameters


public:	// constructor & destructor
	int m_nID;
    Object(int nID) : m_nID(nID) {}
    Object(int nID, const Appearance &appearance) : m_nID(nID), d_appearance(appearance) {}
    virtual ~Object() {};

  
public: // computational members
    // return t for closest intersection with ray
    virtual float intersect(const Ray &ray) const = 0;
	virtual bool IntersectBox(aabb & a_Box) = 0;
	virtual aabb GetAABB() = 0;

    // return color for intersection at t
    virtual const Vec3 appearance(World &w, 
				  const Ray &ray, float t) const = 0;
};

#endif
