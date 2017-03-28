#include "Grid.hpp"
#include "World.hpp"
#include "ObjectList.hpp"


void Grid::SetObject( Object* obj, World *_world)
{
	if(m_objectList == NULL)
		m_objectList = new ObjectList(_world);
	m_objectList->addObject(obj);
}

void Grid::SetBox(aabb &a_Box)
{
	if(m_box == NULL)
		m_box = new aabb(a_Box);
}

void Grid::AllocateObjectList(World *_world)
{
	m_objectList = new ObjectList(_world);
}

bool Grid::IntersectBox(aabb &a_Box)
{
	return m_box ->SmartIntersect(a_Box);
}
