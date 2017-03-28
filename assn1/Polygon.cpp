// implementation code for Polygon object class

// include this class include file FIRST to ensure that it has
// everything it needs for internal self-consistency
#include "Polygon.hpp"

// other classes used directly in the implementation
#include "Ray.hpp"

void
Polygon::addVertex(const Vec3 &v, const Vec3 &n)
{
    // after first vertex, can compute edge data for previous vertex
    if (d_vertex.size() > 0) {
	Vec3 e = d_vertex.back().e = v - d_vertex.back().v;
	d_vertex.back().e_e = e * e;
	d_vertex.back().e_v = e * d_vertex.back().v;
    }

    // on third vertex can compute polygon normal
    if (d_vertex.size() == 2) {
	d_normal = d_vertex.front().e ^ d_vertex.back().e;
	d_d = (d_normal * v) * -1.0f;

	// fill in missing normal-based edge data for first edge
	Vec3 en = d_vertex.front().en = d_vertex.front().e ^ d_normal;
	d_vertex.front().en_v = en * d_vertex.back().v;
    }

    // for third vertex on, compute normal-based edge data
    if (d_vertex.size() >= 2) {
	Vec3 en = d_vertex.back().en = d_vertex.back().e ^ d_normal;
	d_vertex.back().en_v = en * d_vertex.back().v;
    }

    // add new vertex
    d_vertex.push_back(PolyVert(v,n));
}

void
Polygon::closePolygon()
{
    // fill in edge data for final edge
    Vec3 e = d_vertex.back().e = d_vertex.front().v - d_vertex.back().v;
    d_vertex.back().e_e = e * e;
    d_vertex.back().e_v = e * d_vertex.back().v;
    Vec3 en = d_vertex.back().en = e ^ d_normal;
    d_vertex.back().en_v = en * d_vertex.back().v;

    // normalize normal
    d_normal = d_normal.normalize();
}

bool Polygon::IntersectBox(aabb &a_Box) // a_Box ==> Object Bounding Box, 
{
	Vec3 v[2];
	v[0] = a_Box.GetPos(), v[1] = a_Box.GetPos() + a_Box.GetSize();
	int side1, side2; int i ;
	for ( side1 = 0, side2 = 0, i = 0; i < 8; i++ )
	{
		// vector3 p <== It takes each vertex's x,y,z so that p in the loop expresses all the vertices in the box.
		Vec3 p( v[i & 1].x(), v[(i >> 1) & 1].y(), v[(i >> 2) & 1].z() );
		//DOT(p, m_Plane.N) = aX+bY+cZ because p=(x,y,z) and N=(A,B,C) ==> so  (DOT( p, m_Plane.N ) + m_Plane.D == Ax+By+Cz+D
		// If Ax+By+Cz+D < 0, then it is under the plane.
		if ((d_d + (p * d_normal)) < 0) side1++; else side2++;
	}
	if ((side1 == 0) || (side2 == 0)) return false; else return true;
}

float
Polygon::intersect(const Ray &ray) const 
{
    // check for ray parallel to plane
    float n_d = d_normal * ray.direction();
    if (n_d == 0) return ray.far();
  
    // compute intersection point with plane
    float t = d_normal * (d_vertex.front().v - ray.start()) / n_d;
    if (t < ray.near()) return ray.far();	// behind ray start
  
    Vec3 p = ray.start() + ray.direction()*t;

    // check if intersection is inside or outside
    // trace ray from p in direction of first edge, and count even/odd
    // intersections
    bool inside = false;
    VertexList::const_iterator v = d_vertex.begin();
    const Vec3 tr = v->e;	// test ray, in direction of first edge

    // skip first edge (since we know it's parallel to the test ray),
    // but check the rest
    for(++v; v != d_vertex.end(); ++v) {
	// points on test ray: q = p + s*tr
	// points on edge: en*q = en*v
	// solving for s = (en*v - en*p) / en*tr
	float s = (v->en_v - v->en*p) / (v->en*tr);

	// outbound on test ray?
	if (s > 0 && s < INFINITY) {
	    // is the intersection between the vertices?
	    Vec3 q = p + s*tr;	// intersection point on edge
	    float u = v->e*q - v->e_v;
	    if (u >=0 && u < v->e_e) // within bounds of edge itself?
		inside = !inside;
	}
    }

    if (inside) return t;
  
    return ray.far();
}

const Vec3
Polygon::appearance(World &w, const Ray &r, float t) const {
    Vec3 p = r.start() + r.direction() * t;

    if (! d_useVN)
	// per-polygon normal is easy and fast
	return d_appearance.eval(w, p, d_normal, r);
    else {
	// inefficiently re-test all edges to find vertex normals!

	VertexList::const_iterator v = d_vertex.begin();
	const Vec3 tr = v->e;	// test ray, in direction of first edge

	// vertex and ray parameter for first edge on each side of p
	float s0=-INFINITY, s1=INFINITY, u0=0, u1=0;
	VertexList::const_iterator v0, v1;

	// first edge is parallel to ray, but check the rest
	for(++v; v != d_vertex.end(); ++v) {
	    float s = (v->en_v - v->en*p) / (v->en*tr);
	    Vec3 q = p + s*tr;	// intersection point on edge
	    float u = v->e*q - v->e_v;

	    if (u >=0 && u < v->e_e) { // within bounds of edge itself?
		if (s<0 && s>s0) {
		    s0 = s; u0 = u/v->e_e; v0 = v;
		}
		else if (s>0 && s<s1) {
		    s1 = s; u1 = u/v->e_e; v1 = v;
		}
	    }
	}

	// interpolate normal along v0 - (v0+1) edge
	v = v0++;
	if (v0 == d_vertex.end()) v0 = d_vertex.begin();
	Vec3 n0 = u0*(v0->vn) + (1-u0)*(v->vn);

	// interpolate normal along v1 - (v1+1) edge
	v = v1++;
	if (v1 == d_vertex.end()) v1 = d_vertex.begin();
	Vec3 n1 = u1*(v1->vn) + (1-u1)*(v->vn);

	// interpolate between n0 and n1 to get final normal
	float s = -s0/(s1-s0);
	Vec3 n = (1-s)*n0 + s*n1;

	return d_appearance.eval(w, p, n.normalize(), r);
    }
}
