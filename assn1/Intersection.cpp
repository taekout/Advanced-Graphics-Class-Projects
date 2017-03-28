// implementation code for Intersection class

// include this class include file FIRST to ensure that it has
// everything it needs for internal self-consistency
#include "Intersection.hpp"

// other classes used directly in the implementation
#include "Object.hpp"
#include "World.hpp"

// standard includes
#include <stdio.h>

// return appearance for one intersection
const Vec3 
Intersection::appearance(World &w, const Ray &r) const {
    if (d_obj)
	return d_obj->appearance(w, r, d_t);
    else
	// background color
	return w.background;
}
