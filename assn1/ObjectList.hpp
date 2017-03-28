// lists of objects in scene
#ifndef OBJECTLIST_HPP
#define OBJECTLIST_HPP

// other classes we use DIRECTLY in our interface
#include "Intersection.hpp"
#include "Object.hpp"
#include "World.hpp"

// system includes
#include <list>

// classes we only use by pointer or reference
class Ray;

class ObjectList {
	World *m_world;
    // list of objects
public:
	typedef std::list<Object*> t_List;
	t_List d_list;

public:	// constructor & destructor
    ObjectList(World *_world) : m_world(_world) {}
    ~ObjectList();

	World * GetWorldObj(void) {return m_world;}

public:
    // Add an object to the list. Objects should be allocated with
    // new. Objects will be deleted when this ObjectList is destroyed
    void addObject(Object *obj) { d_list.push_back(obj); }
	Object * FindObject(int nID);
  
public: // computational members
    // trace ray r through all objects, returning first intersection
    Intersection trace(Ray &r, aabb *currentGrid) const;
	Intersection TraceForShadowRay(Ray &r, int nCurrentLightID, aabb *currentGrid) const;
};

#endif
