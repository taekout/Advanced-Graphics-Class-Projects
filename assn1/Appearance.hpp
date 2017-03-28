// all info on an object's appearance
#ifndef APPEARANCE_HPP
#define APPEARANCE_HPP

// other classes we use DIRECTLY
#include "Vec3.hpp"

// classes we only use by pointer or reference
class World;
class Ray;

class Appearance {
    Vec3 d_color;	// diffuse color
    float d_ka, d_kd;	// ambient and diffuse coefficients
    float d_ks, d_e;	// specular coefficient & exponent
    float d_kr;		// mirror reflection coefficient
    float d_kt, d_ir;	// transmission coefficient & index of refraction

public: // constructors
    Appearance(const Vec3 &color = Vec3(1,1,1),
	       float ka=0, float kd = 0, float ks = 0, float e = 0,
	       float kr=0, float kt = 0, float ir = 0)
	: d_color(color), d_ka(ka), d_kd(kd), d_ks(ks), d_e(e), 
	d_kr(kr), d_kt(kt), d_ir(ir){}
    // also allow default copy constructor and assignment operator

public: // computational members
    // return color for appearance of this surface for point at p, with
    // normal n and view ray r
    const Vec3 eval(World &world, const Vec3 &p, 
		    const Vec3 &n, const Ray &r) const;
};


#endif
