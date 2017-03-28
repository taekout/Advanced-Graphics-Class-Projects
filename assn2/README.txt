Project2 (Graphics)
- Taekyu Shin

help : no help I got.
how I did it./ What I did : I tried 2 ways. One way failed, but I would say that the other way succeeded.
	(1) I used openGL to render a basic scene.
	(2) I drew a sphere without using the glutSolidSphere function
		to further tweak surface normals manually.
	(3) I tried to implement some part of the method described in :
		1) Anisotropic Lighting at http://www.bluevoid.com/opengl/sig00/advanced00/notes/node159.html
		2) Efficient rendering of anisotropic surfaces using computer graphics hardware.
		3) Fast display of illuminated field lines.
	I indicated 3 because in my opinion, 3 papers were very closely related that
	I did not think that I could implement without reading all those.
	Each paper does not describe all the necessary information in my opinion.

	(4) It failed. : I think that the problem was that I tried to do it without texture maps.
			I think where it went wrong is :
				1. The content of the texture map.
				2. In this case, there are numerous candidates for normal vector for each vertex. (adapted from paper (3) )
				   We pick the most significant vector (adapted from paper (1) ) --> I think that these two information may not be for the same technique.
			Also, I think paper 2) and 3) contents had some discrepancies. 
			For example, I thought some contents I summarized below may not
			have been a match between the two papers.
	2nd Method
	(1) It is simple. I downloaded Rendermonkey anisotropic sample.
	(2) I loaded a sphere model and tweaked the color.
	One thing I noticed was that it had the very same data-set as described in the paper.
	I suppose that it used a similar technique described in the papers.


how well I think it worked:
	Not so well since my opengl code did not work very well. Also, that is why
	I commented out the original implementation and I revived the phong implementation.
	Rendermonkey result looks good in my opinion. I placed an avi video.


what further I might do:
	I would love to figure out what I was missing in the openGl project. I think that next time, I will start with figuring out
	exactly how to make the texture map.(line where dot(L,T) and dot(V,t) are reciprocal (Figure 3 in paper (3)) )

What hardware / software I used:
	(1) Os : Windows 7 64 bit
	(2) CPU : i7 1.7Ghz.
	(3) GPU : ATI HD5730 1Gb
	(4) Laptop
	(5) Software : Rendermonkey / Visual Studio 2010 + OpenGL