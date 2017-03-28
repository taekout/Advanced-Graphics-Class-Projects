#pragma once

#include "Vec3.hpp"
#include "Ray.hpp"

#define EPSILON 0.001f

class aabb
{
public:
	aabb() : m_Pos( Vec3( 0, 0, 0 ) ), m_Size( Vec3( 0, 0, 0 ) ), idX(-1), idY(-1), idZ(-1) {};
	aabb( Vec3& a_Pos, Vec3& a_Size ) : m_Pos( a_Pos ), m_Size( a_Size ), idX(-1), idY(-1), idZ(-1) {};
	Vec3& GetPos() { return m_Pos; }
	Vec3& GetSize() { return m_Size; }
	
	typedef struct rayResult
	{
		float t;
		Vec3 p;
	} rayResult;
	void Set_tMaxForRay( Ray& a_Ray);

	bool Intersect( aabb& b2 )
	{
		Vec3 v1 = b2.GetPos(), v2 = b2.GetPos() + b2.GetSize();
		Vec3 v3 = m_Pos, v4 = m_Pos + m_Size;
		return ((v4.x() > v1.x()) && (v3.x() < v2.x()) && // x-axis overlap
			(v4.y() > v1.y()) && (v3.y() < v2.y()) && // y-axis overlap
			(v4.z() > v1.z()) && (v3.z() < v2.z()));   // z-axis overlap
	}
	bool Contains( Vec3 a_Pos )
	{
		Vec3 v1 = m_Pos, v2 = m_Pos + m_Size;

		return ((a_Pos.x() > (v1.x() - EPSILON)) && (a_Pos.x() < (v2.x() + EPSILON)) &&
			(a_Pos.y() > (v1.y() - EPSILON)) && (a_Pos.y() < (v2.y() + EPSILON)) &&
			(a_Pos.z() > (v1.z() - EPSILON)) && (a_Pos.z() < (v2.z() + EPSILON)));
	}
	bool SmartIntersect(aabb &b2);
	bool SmartContains(Vec3 a_Pos);
	void SetGridIndex(int x, int y, int z) { idX = x; idY = y; idZ = z; }
private:
	Vec3 m_Pos, m_Size;
	int idX, idY, idZ;
};

