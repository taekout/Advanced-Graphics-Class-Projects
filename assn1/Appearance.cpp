// implementation code for Appearance class

// include this class include file FIRST to ensure that it has
// everything it needs for internal self-consistency
#include "Appearance.hpp"

// other classes used directly in the implementation
#include "World.hpp"
#include "Ray.hpp"

// Color of this object
const Vec3
Appearance::eval(World &world, const Vec3 &p, 
		 const Vec3 &n, const Ray &r) const
{
    // base color
    Vec3 col = d_ka*d_color;

    // reflected view ray
    Vec3 Rv = (2.f*(n*r.direction())*n - r.direction()).normalize();

	Vec3 p1 = world.m_Extends.GetPos();
	int x1 = (int)((p.x() - p1.x()) * world.m_dx_reci);//, x2 = (int)((bv2.x() - p1.x()) * dx_reci) + 1;
	x1 = (x1 < 0)?0:x1;//, x2 = (x2 > (GRIDSIZE - 1))?GRIDSIZE - 1:x2;
	int y1 = (int)((p.y() - p1.y()) * world.m_dy_reci);//, y2 = (int)((bv2.y() - p1.y()) * dy_reci) + 1;
	y1 = (y1 < 0)?0:y1;//, y2 = (y2 > (GRIDSIZE - 1))?GRIDSIZE - 1:y2;
	int z1 = (int)((p.z() - p1.z()) * world.m_dz_reci);//, z2 = (int)((bv2.z() - p1.z()) * dz_reci) + 1;
	z1 = (z1 < 0)?0:z1;//, z2 = (z2 > (GRIDSIZE - 1))?GRIDSIZE - 1:z2;


    // diffuse and specular
    for (LightList::const_iterator li=world.lights.begin();
	 li != world.lights.end(); ++li) {

	int currentLightID = li->nLightID;
	// Check the neighboring shadow ray got some hit for the lights b/f shooting a shadow ray.
	Vec3 L = li->pos - p;	// light vector
	void *tmpObjP = NULL;

	// cast ray to see if it's in shadow
	static int shadowRayID = SHADOWRAY_ID;
	// 1. see which grid this shadow ray radiating point is in.
	// 2. --> m_Grid[iz][iy][ix].objectList().trace().t() 
	// 1.
//	Object *pObj = (Object *)world.objects.trace(rshadow, NULL).d_obj;
//	float realT = world.objects.trace(Ray(shadowRayID, p, L, 0, 0, 0), NULL).t();
	Ray shadowray(shadowRayID++, r.worldCoordinateX, r.worldCoordinateY,
		world.m_Extends.GetPos(), world.m_dx, world.m_dy, world.m_dz,
		p, L, 0, 0, 0);
	world.m_Grid[shadowray.iZ][shadowray.iY][shadowray.iX].GetBox()->Set_tMaxForRay(shadowray);

	bool bBlocked = false;
	if(r.worldCoordinateX > 2 && r.worldCoordinateX < world.width - 1 &&
		r.worldCoordinateY > 2 && r.worldCoordinateY < world.height - 1)
	{
		// insert here the below code later.
		for(int h = 0 ; h < 7 ; h++)
		{
			if(world.shadowrayOptimization[r.worldCoordinateX - 1][r.worldCoordinateY].lightID[h] == currentLightID
				&& world.shadowrayOptimization[r.worldCoordinateX - 1][r.worldCoordinateY].pObj[h] != NULL)
			{
				tmpObjP = (void *)world.shadowrayOptimization[r.worldCoordinateX - 1][r.worldCoordinateY].pObj[h];
//				Object * obj = world.objects->FindObject(nHitObjID_forTheLight);
				Object *pTmpObjInst = (Object *)tmpObjP;
				if(pTmpObjInst->intersect(r) < 1.0){
					bBlocked = true;
					break;
				}
			}
			else if(world.shadowrayOptimization[r.worldCoordinateX + 1][r.worldCoordinateY].lightID[h] == currentLightID
				&& world.shadowrayOptimization[r.worldCoordinateX + 1][r.worldCoordinateY].pObj[h] != NULL)
			{
				tmpObjP = world.shadowrayOptimization[r.worldCoordinateX + 1][r.worldCoordinateY].pObj[h];
				Object *pTmpObjInst = (Object *)tmpObjP;
				if(pTmpObjInst->intersect(r) < 1.0)
				{
					bBlocked = true;
					break; // break test + take out find obj func
				}
			}
			else if(world.shadowrayOptimization[r.worldCoordinateX][r.worldCoordinateY - 1].lightID[h] == currentLightID
				&& world.shadowrayOptimization[r.worldCoordinateX][r.worldCoordinateY - 1].pObj[h] != NULL)
			{
				tmpObjP = world.shadowrayOptimization[r.worldCoordinateX][r.worldCoordinateY - 1].pObj[h];
				Object *pTmpObjInst = (Object *)tmpObjP;
				if(pTmpObjInst->intersect(r) < 1.0)
				{
					bBlocked = true;
					break;
				}
			}
			else if(world.shadowrayOptimization[r.worldCoordinateX][r.worldCoordinateY + 1].lightID[h] == currentLightID
				&& world.shadowrayOptimization[r.worldCoordinateX][r.worldCoordinateY + 1].pObj[h] != NULL)
			{
				tmpObjP = world.shadowrayOptimization[r.worldCoordinateX][r.worldCoordinateY + 1].pObj[h];
				Object *pTmpObjInst = (Object *)tmpObjP;
				if(pTmpObjInst->intersect(r) < 1.0)
				{
					bBlocked = true;
					break;
				}
			}
		}
	}
	if(bBlocked == true)
		continue;
	Intersection tmpIn = world.GoToNearestGridForShadowRayOptimized(shadowray, currentLightID);
	if(tmpIn.t() >= 1.0)
//	if(world.m_Grid[z1][y1][x1].GetObjectList()->trace(Ray(shadowRayID++, p, L, 0, 0, 0), world.m_Grid[z1][y1][x1].GetBox()).t() >= 1.0)
	{
	    L = L.normalize();
	    float diffuse = n*L;
	    if (diffuse > 0) {
		Vec3 dc = Vec3(li->col[0]*d_color[0],
			       li->col[1]*d_color[1],
			       li->col[2]*d_color[2]);
		col = col + d_kd*diffuse*dc;
		
		float specular = Rv*L;
		if (specular > 0)
		    col = col + d_ks*pow(specular,d_e)*li->col;
	    }
	}
	else
	{
		// Update shadow ray blocked object Information so that later shadow rays can pick objects better to intersect first.
		for(int g = 0 ; g < 7 ; g++)
		{
			if(world.shadowrayOptimization[shadowray.worldCoordinateX][shadowray.worldCoordinateY].lightID[g] == -1)
			{
				world.shadowrayOptimization[shadowray.worldCoordinateX][shadowray.worldCoordinateY].lightID[g] = currentLightID;
				void *pTmp = tmpIn.object();
				world.shadowrayOptimization[shadowray.worldCoordinateX][shadowray.worldCoordinateY].pObj[g] = (Object *)pTmp;
			}
		}
	}
    }

    // reflected rays
    if (r.influence()*d_kr > .5/255 && r.bounces() > 0) {
	// reflect ray off surface
	Vec3 rv = r.direction() - 2*(n*r.direction())*n;

	// new ray with one less bounce and influence reduced by kr
	static int reflectedRayID = REFLECTRAY_ID;
	Ray rr(reflectedRayID++, r.worldCoordinateX, r.worldCoordinateY,
		world.m_Extends.GetPos(), world.m_dx, world.m_dy, world.m_dz,
		p,rv,r.bounces()-1,r.influence()*d_kr, r.ir());
	world.m_Grid[rr.iZ][rr.iY][rr.iX].GetBox()->Set_tMaxForRay(rr);
	Vec3 rc = world.GoToNearestGrid(rr).appearance(world, rr); // trace ray(reflection) through grids.
//	Vec3 rc = world.objects.trace(rr, NULL).appearance(world,rr); // trace ray
	col = col + d_kr * rc;
    }

    // refracted rays
    if (r.influence()*d_kt > .5/255 && r.bounces() > 0) {
	// compute refracted ray
	float tn = r.ir() / d_ir;	// combined index of refraction

	// ca = cosine of incoming ray w/ normal
	// note that r.direction isn't normalized, so ca = rlen cos(a)
	// instead of sin(a)^2 = 1 - cos(a)^2 we have 
	//   rlen sin(a)^2 = rlen^2 - ca^2
	float ca = n*r.direction();
	float rlen = r.direction()*r.direction();
	float cb2 = rlen - tn*tn * (rlen - ca*ca);
	if (cb2 > 0) {		// cb2<=0 for total internal reflection
	    // compute n component of refracted ray.
	    float cb = sqrt(cb2);

	    // Since r.direction points toward the surface, cb and ca
	    // should have the same sign. If >0, we're leaving the
	    // object, so revert index of refraction for ray to that
	    // of air. This will not handle nested objects correctly,
	    // for that, we'd need an ir stack, to push when we enter
	    // an object and pop when we leave.
	    float new_ir = 1;
	    if (ca < 0) {
		cb = -cb;
		new_ir = d_ir;
	    }

	    // refracted ray direction: start with old ray direction
	    // scaled by relative index of refraction. This is correct
	    // parallel to the surface but the component perpendicular
	    // to the surface is ca when it should be cb, so subtract
	    // cb*n and add ca*n.
	    Vec3 td = tn * r.direction() + (cb-ca) * n;

	    // new ray with one fewer bounce and influence reduced by kt
		static int refractedRayID = REFRACTRAY_ID;
	    Ray tr(refractedRayID++, r.worldCoordinateX, r.worldCoordinateY,
			world.m_Extends.GetPos(), world.m_dx, world.m_dy, world.m_dz,
			p, td, r.bounces()-1, r.influence()*d_kt, new_ir);
		world.m_Grid[tr.iZ][tr.iY][tr.iX].GetBox()->Set_tMaxForRay(tr);
		Vec3 tc = world.GoToNearestGrid(tr).appearance(world, tr); // trace ray(reflection) through grids.
//	    Vec3 tc = world.objects.trace(tr, NULL).appearance(world,tr); // trace ray
	    col = col + d_kt * Vec3(tc[0]*d_color[0],
				    tc[1]*d_color[1],
				    tc[2]*d_color[2]);
	}
    }

    return col;
}
