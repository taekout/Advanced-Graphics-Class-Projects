// implementation code for ObjectList class
// list of objects in scene

// include this class include file FIRST to ensure that it has
// everything it needs for internal self-consistency
#include "ObjectList.hpp"

// delete list and objects it contains
ObjectList::~ObjectList() {
    for(t_List::iterator i=d_list.begin(); i != d_list.end(); ++i) {
	delete *i;
    }
}

Object * ObjectList::FindObject(int nID)
{
	for(t_List::iterator i = d_list.begin() ; i != d_list.end() ; ++i)
	{
		Object * tmpObj = (*i);
		if(tmpObj->m_nID == nID)
			return tmpObj;
	}
	return NULL;
}

Intersection
ObjectList::trace(Ray &r, aabb *currentGrid) const
{
	Intersection intersect;	// no object, t = infinity
	for(t_List::const_iterator i=d_list.begin(); i != d_list.end(); ++i) {
		float tt;
		if((*i)->m_nID == r.m_lasttime.objID)
			tt = r.m_lasttime.tt;
		else
		{
			tt = (*i)->intersect(r);
			if(tt != INFINITY)
			{
				r.m_lasttime.tt = tt;
				r.m_lasttime.objID = (*i)->m_nID;
			}
		}
		if(currentGrid == NULL)
			if(tt < intersect.t())
				intersect = Intersection(*i, tt);
		if (tt < intersect.t() && currentGrid->Contains(r.start() + r.direction() * tt) )
			intersect = Intersection(*i, tt);
	}
	return intersect;
}


Intersection
	ObjectList::TraceForShadowRay(Ray &r, int nCurrnetLightID, aabb *currentGrid) const
{
	Intersection intersect;	// no object, t = infinity
	for(t_List::const_iterator i=d_list.begin(); i != d_list.end(); ++i) {
		float tt;
		if((*i)->m_nID == r.m_lasttime.objID)
			tt = r.m_lasttime.tt;
		else
		{
			tt = (*i)->intersect(r);
			if(tt != INFINITY)
			{
				r.m_lasttime.tt = tt;
				r.m_lasttime.objID = (*i)->m_nID;
			}
		}
		if(currentGrid == NULL)
			if(tt < intersect.t())
				intersect = Intersection(*i, tt);
		if (tt < intersect.t() && currentGrid->Contains(r.start() + r.direction() * tt) )
			intersect = Intersection(*i, tt);
	}
	return intersect;
}
