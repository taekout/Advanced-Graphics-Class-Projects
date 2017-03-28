--------------------------------------------------------------------

description of how the completed project corresponds to the proposal

--------------------------------------------------------------------

The goals for the proposal can be three things overally.

First - Attenuation.

Previous research’s shafts of lights often did not display such natural
attenuation. Our method based on analytically the scattering theories
can generate this effect.

Second – Particle effects.

It is nice to have particle jitter effects. Our method does not necessarily
achieve it in an obvious way since it is averaged out through thousands
of times of ray-marching in the algorithm. However, it can be quite obvious
especially the light shaft is lean. For example, when looking at some object
in the shafts of light, it can be quite noticeable.

Third – Physics based scattering effects.

We base all our method on previous research works, which were also based on
physics. The exceptions are computing the directions.

Fourth – Tyndall effect.

We did not incorporate this because most of lighting situations we face
in real life, the effect we particularly call the tyndall effect is rather
vague. To be straight-forward, a lot of general lighting situations, the
Rayleigh scattering theory is more than enough to render plausibly many
of the tyndall effects. There are some special situations such as rendering
of the atmosphere of the Earth regarding the Mie scattering theory.


-----------------------------------------------------------

an informal user's guide describing how to use your project

-----------------------------------------------------------

Development Environment : Windows 7/GPU: ATI Mobility Radeon hd 5730 1GB/Visual Studio 2010

Usage>

Visual Studio Project File:
Implementation/VolumeLight/Direct3D/Source/VolumeLight/VolumeLight.sln

It does not work in 64bit mode.

Since the probability functions are not computed on the fly, it needs to be manually fed.
I used Matlab to implement the functions. The matlab files are in (Implementation/VolumeLight)

DistributionFn.m ==> Computation of the probability function and save it in the texture (particleDensityDist.bmp)
                     Also read excel files to make textures for the surface radiance model (Gftn.bmp)












