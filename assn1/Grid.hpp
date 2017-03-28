#pragma once

#include <stdio.h>

extern class Object;
extern class ObjectList;
extern class World;
extern class aabb;

class Grid
{
public:
	Grid() : m_objectList( NULL ), m_box(NULL) {}
	~Grid() { }
	void SetObject( Object* obj, World *_world);
	void SetBox(aabb &a_Box);
	inline aabb *GetBox() { return m_box; }
	inline ObjectList * GetObjectList() { return m_objectList; }
	bool IntersectBox(aabb &a_Box);
	void AllocateObjectList(World *_world);
private:
	aabb *m_box;
	ObjectList* m_objectList;
};// add list for grid objects.

