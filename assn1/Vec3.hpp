// 3D vector class
#ifndef VEC3_HPP
#define VEC3_HPP

#define _USE_MATH_DEFINES
#include <math.h>

#ifndef INFINITY
#define INFINITY float(HUGE_VAL)
#endif

//////////////////////////////////////////////////////////////////////
// 3D vector
class Vec3 {
private:			// private data
    float d_[3];

public:			// constructors & destructors
    Vec3() {d_[0] = d_[1] = d_[2] = 0; }
    Vec3(float x, float y, float z) { 
	d_[0] = x; d_[1] = y; d_[2] = z;
    }
    // also can use default copy constructor

public:			// access
    float operator[](int i) const { return d_[i]; }
    float &operator[](int i) { return d_[i]; }

    // as cartesian vector
    float x() const {return d_[0];}
    float y() const {return d_[1];}
    float z() const {return d_[2];}

    // as color, scaled and clamped to 0-255
    int r() const {
	return d_[0] < 0 ? 0 : (d_[0] > 1 ? 255 : int(255*d_[0]+.5));
    }
    int g() const {
	return d_[1] < 0 ? 0 : (d_[1] > 1 ? 255 : int(255*d_[1]+.5));
    }
    int b() const {
	return d_[2] < 0 ? 0 : (d_[2] > 1 ? 255 : int(255*d_[2]+.5));
    }

public:			// other member functions
    float length() const;	// length of vector
    Vec3 normalize() const;	// copy of vector normalized to unit length
	void Set(float x, float y, float z) {d_[0] = x; d_[1] = y; d_[2] = z;}
};

//////////////////////////////
// other operators

// cross product, v1^v2
inline Vec3 operator^(const Vec3 &v1, const Vec3 &v2) {
    return Vec3(v1[1]*v2[2] - v1[2]*v2[1],
		v1[2]*v2[0] - v1[0]*v2[2],
		v1[0]*v2[1] - v1[1]*v2[0]);
}

// vector addition, v1+v2
inline Vec3 operator+(const Vec3 &v1, const Vec3 &v2) {
    return Vec3(v1[0] + v2[0], v1[1] + v2[1], v1[2] + v2[2]);
}

// vector subtraction, v1-v2
inline Vec3 operator-(const Vec3 &v1, const Vec3 &v2) {
    return Vec3(v1[0] - v2[0], v1[1] - v2[1], v1[2] - v2[2]);
}

// vector dot product, v1*v2
inline float operator*(const Vec3 &v1, const Vec3 &v2) {
    return (v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2]);
}

// scalar multiplication, s*v
inline Vec3 operator*(float s, const Vec3 &v) {
    return Vec3(s*v[0], s*v[1], s*v[2]);
}

// scalar multiplication, v*s
inline Vec3 operator*(const Vec3 &v, float s) {
    return Vec3(s*v[0], s*v[1], s*v[2]);
}

// scalar division, v/s
inline Vec3 operator/(const Vec3 &v, float s) {
    return v*(1/s);
}

// return length vector, v.length()
inline float Vec3::length() const {
    return sqrt(*this * *this);
}
    
// return normalized vector, v.normalize()
inline Vec3 Vec3::normalize() const {
    return *this / this->length();
}
    
#endif
