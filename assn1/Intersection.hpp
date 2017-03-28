// intersection results
#ifndef INTERSECTION_HPP
#define INTERSECTION_HPP

// other classes we use DIRECTLY in our interface
#include "Vec3.hpp"

// system includes
#include <list>

// classes we only use by pointer or reference
class World;
class Object;
class Ray;

// intersection results: contains object hit and t of first intersection point
class Intersection {
public:
    const Object *d_obj;	// what did we hit?
    float d_t;			// where along ray?

public: // constructors
    // construct with no object, intersection at infinity
    Intersection(const Object *obj=0, float t=INFINITY) : d_obj(obj), d_t(t) {}

    // we also also allow default copy constructor and assignment

public: // accessors
    float t() const {return d_t;}
	Object *object(void) { return (Object *)d_obj; }

public: // computational members
    // get appearance for this intersection
    const Vec3 appearance(World&, const Ray&) const;

};


#endif
