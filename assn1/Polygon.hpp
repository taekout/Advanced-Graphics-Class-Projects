// polygon objects
#ifndef POLYGON_HPP
#define POLYGON_HPP

// other classes we use DIRECTLY in our interface
#include "Object.hpp"
#include "Vec3.hpp"
#include "aabb.hpp"

// system includes necessary for the interface
#include <list>

// classes we only use by pointer or reference
class Appearance;
class World;
class Ray;
class aabb;

class Polygon : public Object {
    struct PolyVert {
	Vec3 v;			// vertex
	Vec3 vn;		// vertex normal
	// the rest are derived values used in intersection testing
	Vec3 e;			// edge from this vertex to next
	Vec3 en;		// normal to e in plane of polygon
	float e_e;		// e dot e
	float e_v;		// e dot v
	float en_v;		// en dot v
	PolyVert(const Vec3 &vert, const Vec3 &norm) : v(vert), vn(norm) {}
    };
    typedef std::list<PolyVert> VertexList;

    VertexList d_vertex;	// list of vertices
    bool d_useVN;		// use vertex normals?
    Vec3 d_normal;		// face normal
	float d_d;			// D as in the polygon equation(Ax + By + Cz + D = 0)

public:	// constructors
    Polygon(int nID, const Appearance &appearance, bool useVertexNormals)
	: Object(nID, appearance), d_useVN(useVertexNormals) {}

public: // manipulators
    // add a new vertex to the polygon
    // given vertex and per-vertex normal
    void addVertex(const Vec3 &v, const Vec3 &n);

    // close the polygon after the last vertex
    void closePolygon();
  
public: // object functions
    float intersect(const Ray &ray) const;
	bool IntersectBox(aabb &a_Box);
    const Vec3 appearance(World &w, const Ray &ray, float t) const;
	aabb GetAABB()
	{
		float minx = FLT_MAX, miny = FLT_MAX, minz = FLT_MAX;
		float maxx = -1000000000 ,maxy = -1000000000, maxz = -1000000000;
		for(VertexList::iterator i = d_vertex.begin() ; i != d_vertex.end() ; i++)
		{
			PolyVert p = (*i);
			if(p.v.x() < minx)
				minx = p.v.x();
			if(p.v.x() > maxx)
				maxx = p.v.x();
			if(p.v.y() < miny)
				miny = p.v.y();
			if(p.v.y() > maxy)
				maxy = p.v.y();
			if(p.v.z() < minz)
				minz = p.v.z();
			if(p.v.z() > maxz)
				maxz = p.v.z();
		}
		Vec3 aabb_v1(minx, miny, minz);
		Vec3 aabb_v2(maxx-minx, maxy-miny, maxz-minz);
		return aabb(aabb_v1, aabb_v2);
	}
};

#endif
