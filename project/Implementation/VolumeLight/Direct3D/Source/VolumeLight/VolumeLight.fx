//----------------------------------------------------------------------------------
// File:   VolumeLight.fx
// Author: Evgeny Makarov
// Email:  sdkfeedback@nvidia.com
// 
// Copyright (c) 2007 NVIDIA Corporation. All rights reserved.
//
// TO  THE MAXIMUM  EXTENT PERMITTED  BY APPLICABLE  LAW, THIS SOFTWARE  IS PROVIDED
// *AS IS*  AND NVIDIA AND  ITS SUPPLIERS DISCLAIM  ALL WARRANTIES,  EITHER  EXPRESS
// OR IMPLIED, INCLUDING, BUT NOT LIMITED  TO, IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE.  IN NO EVENT SHALL  NVIDIA OR ITS SUPPLIERS
// BE  LIABLE  FOR  ANY  SPECIAL,  INCIDENTAL,  INDIRECT,  OR  CONSEQUENTIAL DAMAGES
// WHATSOEVER (INCLUDING, WITHOUT LIMITATION,  DAMAGES FOR LOSS OF BUSINESS PROFITS,
// BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS)
// ARISING OUT OF THE  USE OF OR INABILITY  TO USE THIS SOFTWARE, EVEN IF NVIDIA HAS
// BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
//
//
//----------------------------------------------------------------------------------

#define RANDOM_IA 16807
#define RANDOM_IM 2147483647
#define RANDOM_AM (1.0f/float(RANDOM_IM))
#define RANDOM_IQ 127773
#define RANDOM_IR 2836
#define RANDOM_MASK 123459876

#define PI 3.14159265f

// The per-color weighting to be used for luminance calculations in RGB order.
static const float3 LUMINANCE_VECTOR  = float3(0.2125f, 0.7154f, 0.0721f);
static const float  MIDDLE_GRAY = 0.72f;
static const float  LUM_WHITE = 1.5f;
static const float  BRIGHT_THRESHOLD = 0.5f;

Texture2D DiffuseTexture;
Texture2D VolumeLightTexture;
Texture2D<float1> DepthTexture;
Texture2D<float1> DepthBufferTexture;

Texture2D NoiseTexture;

//Taekyu
Texture2D ParticleTex;
Texture2D DirTex;
Texture2D AnalyticFuncTex;
//Texture2D GFuncTex;
//Texture2D GFunc10Tex;
//Texture2D NormalTex;
//Texture2D ReflectionTex;
//Taekyu so far

Texture2D s0;
Texture2D s1;
Texture2D s2;

#define MAX_STEPS 2000

SamplerState samplerLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Wrap;
    AddressV = Wrap;
};

SamplerState samplerLinearClamp
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState samplerPoint
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Wrap;
    AddressV = Wrap;
};

SamplerState samplerPointClamp
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState samplerDepthMinMax
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
	BorderColor = float4(10000.0, 10000.0, 10000.0, 10000.0);
};

SamplerComparisonState samplerDepthLinear
{
    Filter = COMPARISON_ANISOTROPIC;
    AddressU = Border;
    AddressV = Border;
    ComparisonFunc = LESS;
    BorderColor = float4(1.0, 1.0, 1.0, 1.0);
};

SamplerComparisonState samplerPoint_Less
{
    Filter = COMPARISON_MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
    ComparisonFunc = LESS;
	//BorderColor = float4(10000.0, 10000.0, 10000.0, 10000.0);
	BorderColor = float4(0, 0, 0, 0);
};

SamplerComparisonState samplerPoint_LessWrap
{
	Filter = COMPARISON_MIN_MAG_MIP_POINT;
	AddressU = Wrap;
	AddressV = Wrap;
	ComparisonFunc = LESS;
};

SamplerComparisonState samplerPoint_Greater
{
    Filter = COMPARISON_MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
    ComparisonFunc = GREATER;
	BorderColor = float4(10000.0, 10000.0, 10000.0, 10000.0);
};

RasterizerState RenderFrontFace
{
    CullMode = Back;
    FrontCounterClockwise = TRUE;
};

RasterizerState RenderBackFace
{
    CullMode = Front;
    FrontCounterClockwise = TRUE;
};

RasterizerState RenderNoCull
{
    CullMode = NONE;
};

DepthStencilState RenderDepthAlways
{
    DepthEnable = true;
    DepthWriteMask = ALL;
    DepthFunc = ALWAYS;
};

DepthStencilState RenderDepthNormal
{
    DepthEnable = true;
    DepthWriteMask = ALL;
    DepthFunc = LESS_EQUAL;
};

DepthStencilState NoDepthStencil
{
    DepthEnable = false;
    StencilEnable = false;
};

BlendState NoBlending
{
	BlendEnable[0] = FALSE;
};

BlendState SrcAlphaBlendingAdd
{
    BlendEnable[0] = TRUE;
    SrcBlend = SRC_ALPHA;
    DestBlend = INV_SRC_ALPHA;
    BlendOp = ADD;
    SrcBlendAlpha = ZERO;
    DestBlendAlpha = ZERO;
    BlendOpAlpha = ADD;
    RenderTargetWriteMask[0] = 0x0F;
};

BlendState SrcAlphaBlendingAddDstZero
{
    BlendEnable[0] = TRUE;
    SrcBlend = SRC_ALPHA;
    DestBlend = ZERO;
    BlendOp = ADD;
    SrcBlendAlpha = ZERO;
    DestBlendAlpha = ZERO;
    BlendOpAlpha = ADD;
    RenderTargetWriteMask[0] = 0x0F;
};

struct DummyInput
{
};

struct VSIn_Diffuse
{
    float3 position : POSITION;
	float2 texCoord : TEXCOORD;
	float3 normal   : NORMAL;
	float3 tangent  : TANGENT;
};

struct VSIn_Simple
{
    float3 position : Position;
};

struct VSIn_PostVS
{
    float4 position : Position;
    float3 texCoord : TEXCOORD0;
    float4 shadowUV : TEXCOORD1;
};

struct PSIn_Tracing
{
    float4 position : SV_Position;
};

struct PSIn_Diffuse
{
    float4 position : SV_Position;
    float2 texCoord : TEXCOORD0;
	float3 normal   : TEXCOORD1;
};

struct PSIn_ShadowMap
{
    float4 position : SV_Position;
};

struct PSOut
{
    float4 color : SV_Target;
};

struct PSInQuad
{
	float4 position : SV_Position;
    float2 texCoord : TEXCOORD0;	
};

shared cbuffer cb0
{
    row_major float4x4 g_ModelViewProj; // g_ModelViewProj actually has view and projection both.
    row_major float4x4 g_MWorldViewProjectionInv; // inverse of g_ModelViewProj
	row_major float4x4 g_ProjectionInv;
    row_major float4x4 g_ModelLightProj;
	row_major float4x4 g_ModelLightProjInv;
    float3 g_EyePosition;
    float3 g_WorldRight;
    float3 g_WorldUp;
	float3 g_WorldFront;
	float g_ZNear;
	float g_ZFar;
    
	float g_BufferWidth;
    float g_BufferHeight;

	float g_BufferWidthInv;
    float g_BufferHeightInv;
    
	float3 g_LightPosition;
	float3 g_LightRight;
	float3 g_LightUp;
	float3 g_LightForward;

	float g_CoarseDepthTexelSize; // assume the texture is squared

	float g_CoarseTextureWidthInv;
	float g_CoarseTextureHeightInv;
};

shared cbuffer cb1
{
    float g_rSamplingRate;
	bool  g_UseAngleOptimization = true;
};

shared cbuffer cb2
{
	float4 g_avSampleOffsetsHorizontal[15];
	float4 g_avSampleOffsetsVertical[15];
	float4 g_avSampleWeights[15];
};

shared cbuffer userVar
{
	float3 g_curPos;
}

//--------------------------------------------------------------------------------------
// Shader main functions
//--------------------------------------------------------------------------------------

float4 VSMainQuad() : SV_Position
{
	float4 output = 0;
	return output;
}

PSIn_Diffuse VS_Diffuse(VSIn_Diffuse input)
{
    PSIn_Diffuse output;

    output.position = mul( float4(input.position, 1.0), g_ModelViewProj );
    output.texCoord = input.texCoord.xy;
	output.normal = input.normal.xyz;
    
    return output;
}

VSIn_PostVS VS_Simple(VSIn_Simple input)
{
    VSIn_PostVS output;
   
    output.position = float4( input.position, 1.0 );
    output.texCoord = 0;
    output.shadowUV = 0;
    
    return output;
}

PSIn_Tracing VS_Tracing(VSIn_Simple input)
{
    PSIn_Tracing output;
   
    output.position = mul( float4(input.position, 1.0), g_ModelViewProj );
    
    return output;
}

PSIn_ShadowMap VS_ShadowMap(VSIn_Diffuse input)
{
    PSIn_ShadowMap output;
   
    output.position = mul( float4( input.position, 1.0 ), g_ModelLightProj );
    
    return output;
}

[maxvertexcount(4)]
void GSMainQuad( point DummyInput inputPoint[1], inout TriangleStream<PSInQuad> outputQuad, uint primitive : SV_PrimitiveID )
{
    PSInQuad output;
    
    output.position.z = 0.5;
    output.position.w = 1.0;
    
    output.position.x = -1.0;
    output.position.y = 1.0;
    output.texCoord.xy = float2( 0.0, 0.0 );
    outputQuad.Append( output );
    
    output.position.x = 1.0;
    output.position.y = 1.0;
    output.texCoord.xy = float2( 1.0, 0.0 );
    outputQuad.Append( output );
    
    output.position.x = -1.0;
    output.position.y = -1.0;
    output.texCoord.xy = float2( 0.0, 1.0 );
    outputQuad.Append( output );
        
    output.position.x = 1.0;
    output.position.y = -1.0;
    output.texCoord.xy = float2( 1.0, 1.0 );
    outputQuad.Append( output );
    
    outputQuad.RestartStrip();
}

PSOut PS_Diffuse(PSIn_Diffuse input)
{
    PSOut output;
    
    float3 lightVector = normalize( g_LightPosition.xyz - g_EyePosition.xyz );
		
	float3 Diffuse = DiffuseTexture.Sample( samplerLinear, input.texCoord ).xyz;
	output.color.xyz = Diffuse * 0.9 * saturate( dot( lightVector, normalize(input.normal) ) );
	output.color.w = 1.0;

	float4 clipPos;
	clipPos.x = 2.0 * input.position.x * g_BufferWidthInv - 1.0;
	clipPos.y = -2.0 * input.position.y * g_BufferHeightInv + 1.0;
	clipPos.z = input.position.z;
	clipPos.w = 1.0;
							
	float4 positionWS = mul(clipPos, g_MWorldViewProjectionInv);
	positionWS.w = 1.0 / positionWS.w;
	positionWS.xyz *= positionWS.w;
    
    float4 shadowUV = mul( float4(positionWS.xyz, 1.0), g_ModelLightProj );
	float3 coordinates = shadowUV.xyz / shadowUV.w;
    
    coordinates.x = ( coordinates.x + 1.0 ) * 0.5;
    coordinates.y = ( 1.0 - coordinates.y ) * 0.5;
    
    float shadow = DepthTexture.SampleCmp( samplerDepthLinear, coordinates.xy, coordinates.z ).x;
	output.color.xyz *= shadow;

	output.color.xyz += Diffuse * 0.05;

    return output;
}

float random ( float low, float high )
{
	int random_x = 107;// seed;
    int k;
    float ans;
    random_x ^= RANDOM_MASK;
    k = random_x / RANDOM_IQ;
    random_x = RANDOM_IA * (random_x - k * RANDOM_IQ ) - RANDOM_IR * k;
    if ( random_x < 0 )
			 		random_x += RANDOM_IM;
    ans = RANDOM_AM * random_x;
    random_x ^= RANDOM_MASK;
	float v = ans;
    return low * ( 1.0f - v ) + high * v;
}


void seed ( int value )
{
    int random_x = value;
}

float surfaceRadianceModel( float srBeta, float Kd, float Ks, float I0, float3 renderPoint,
					float3 surfacePoint, float3 lightSource, float3 vecForward, float particleDensity )
{
	float3 SP = surfacePoint - lightSource;
	float Dsp = 0.1 * sqrt( dot(SP, SP) );
	float Tsp = srBeta * Dsp;
	// Make textures for normal map, scattering reflection map.
	// Then set theta from reflection map then set normal from normal map.(Make sure normal looks at eye position.
	// you can do it by doing dot(vecForward, normal) < 0. If dot() > 0, flip the normal by (normal = -normal)
	float2 uv = float2( renderPoint.x+renderPoint.y, renderPoint.x+renderPoint.y+renderPoint.z );	// natural uv. noise function may work.
	uv.x = (uv.x < 0.f) ? -uv.x : uv.x;
	uv.y = (uv.y < 0.f) ? -uv.y : uv.y;
	uv = fmod(uv, 1);
	float3 normal = DirTex.SampleLevel( samplerPoint, uv, 0 ); // Use DirTex instead of NormalTex. (NormalTex is NOT working!)
	if( dot(normal, vecForward) > 0 ) normal = -normal;
	uv = float2(1.f, 1.f) - uv; // shuffle the indices.
	float3 scatteringReflectionDir = DirTex.SampleLevel( samplerPoint, uv, 0 ); // Use DirTex instead of ReflectionTex. (ReflectionTex is NOT working!)
	// reflection scattering direction must be also that way as well.
	if( dot(scatteringReflectionDir, normal) < 0 ) scatteringReflectionDir = -scatteringReflectionDir;
	normal = normalize(normal);
	scatteringReflectionDir = normalize(scatteringReflectionDir);
	// From parameterization, theta from (N.L), newTheta from (R~, L)
	SP = normalize(SP);
	float srTheta = acos( dot(normal, -SP) );			// reflect func --> v = i - 2 * n * dot(i�n)
	srTheta = clamp(srTheta, 0, PI/2.f);
	// in the reflect func, you are supposed to use the direction towards the surface.(Ex : surface point - view point, NOT view point - surface point)
	float3 reflectedDir = reflect(-scatteringReflectionDir, normal);
	reflectedDir = normalize(reflectedDir);
	float srNewTheta = acos( dot(normal, reflectedDir) );
	srNewTheta = clamp(srNewTheta, 0, PI/2.f);
	// Surface radiance model should work only when density is > 0 or > 1.
	// then implement surface radiance model.
	// Don't forget to normalize the uv coordinates.
	Tsp = clamp(Tsp, 0.f, 10.f);
	uv = float2( Tsp / 10.f , srTheta / (PI/2.f) ); // UV must be interpolated in the range.
	float G0 = AnalyticFuncTex.SampleLevel( samplerLinear, uv, 0 ); // I loaded G function(G0) in AnalyticFuncTex since GFuncTex is NOT working.
	G0 *= 8.0676f;
	//uv = float2( Tsp / 10.f , srNewTheta / (PI/2.f) );
	//float G20 = GFunc10Tex.SampleLevel( samplerLinear, uv, 0 );
	float diffuse = I0 * Kd * ( exp(-Tsp) * cos(srTheta) / (Dsp * Dsp) + srBeta * srBeta * G0 / (2 * PI * Tsp) );
	//float specular = I0 * Ks * ( exp(-Tsp) * pow(cos(srNewTheta), 20) / (Dsp * Dsp) + srBeta * srBeta * G20 / (2 * PI * Tsp) );
	float surfaceRadiance = diffuse; // + specular; // for now, no specular.
	diffuse *= exp( -(particleDensity * particleDensity) );
	// I guess, to get a more natural-looking image, I should loop. Every time, I should manually change 
	return surfaceRadiance;
}

float4 PS_TracingFullscreen( PSInQuad input, uniform bool useZOptimizations ) : SV_Target
{
	bool bMultiSampling = false;
	float srBeta = 0.01f;
	float distCoeff = 7;

	float sceneDepth = DepthBufferTexture.Sample( samplerPoint, input.texCoord.xy );
	
    float4 clipPos;
	clipPos.x = 2.0 * input.texCoord.x - 1.0;
	clipPos.y = -2.0 * input.texCoord.y + 1.0;
	clipPos.z = sceneDepth;
	clipPos.w = 1.0;
	// Clip pos is now the space-end of it. no need to ray cast beyond that point.

	// World space position of the texel from the depth buffer
    float4 positionWS = mul( clipPos, g_MWorldViewProjectionInv );
	positionWS.w = 1.0 / positionWS.w;
	positionWS.xyz *= positionWS.w;
	// Why need to xyz/ w? Don't we want the ending point.clipping point?

	// I think it's a ray for raytracing
	float3 vecForward = normalize( positionWS.xyz - g_EyePosition.xyz ); // ray defined.
	// zNear is probably the near plane.
	float traceDistance = dot( positionWS.xyz - ( g_EyePosition.xyz + vecForward * g_ZNear ), vecForward );
	// I think it basically gets the difference btw. cur pos and the desired position to get how far it should go further.
	traceDistance = clamp( traceDistance, 0.0, 2500.0 ); // Far trace distance
	
	// positionWS is a point on the near plane.
	positionWS.xyz = g_EyePosition.xyz + vecForward * g_ZNear;

	if( g_UseAngleOptimization )
	{
		// I think it gets the angle between V and L.
		float dotViewLight = dot( vecForward, g_LightForward );
		// e ^ (cos theta)^2
		vecForward *= exp( dotViewLight * dotViewLight );
	}

	vecForward *= g_rSamplingRate * 2.0;
	uint stepsNum = min( traceDistance / length( vecForward ), MAX_STEPS );

	// Add jittering
	float jitter = NoiseTexture.Sample( samplerLinear, input.texCoord.xy ).x;
	
	float step = length( vecForward );
	float scale = step * 0.0005; // Set base brightness factor
	float4 shadowUV;
	float3 coordinates;
	
	// Calculate coordinate delta ( coordinate step in light space )
	// Q. Is the shadow map that way? (Comparison of depth in terms of light source and the viewer)
	// positionWS = point on the near plane.
	float3 curPosition = positionWS.xyz + vecForward * jitter; // I think Forward the ray(Ray Traversal) The reason is it's at the near plane. Precision problem(Zero Crossing kind of problem)
	// D3DXMatrixOrthoLH(( D3DXMATRIX*)&g_LightProjMatrix, LIGHT_SIZE, LIGHT_SIZE, LIGHT_NEAR, LIGHT_FAR );
	// g_ModelLightProj = g_MLight * g_MLightProjection;
	// Q. Why divide by W?
	// g_ModelLightProj is camera(up,right,forward) vector * the orthogonal matrix  = opengl pipelining 
	shadowUV = mul( float4( curPosition, 1.0 ), g_ModelLightProj );
	coordinates = shadowUV.xyz / shadowUV.w;
	coordinates.x = ( coordinates.x + 1.0 ) * 0.5;
	coordinates.y = ( 1.0 - coordinates.y ) * 0.5;
	coordinates.z = dot( curPosition - g_LightPosition, g_LightForward );

	float3 oriCurPos = curPosition;
	float3 oriVecForward = vecForward * (1.0 + jitter);
	curPosition = positionWS.xyz + vecForward * ( 1.0 + jitter );
	shadowUV = mul( float4( curPosition, 1.0 ), g_ModelLightProj );
	float3 coordinateEnd = shadowUV.xyz / shadowUV.w;
	coordinateEnd.x = ( coordinateEnd.x + 1.0 ) * 0.5;
	coordinateEnd.y = ( 1.0 - coordinateEnd.y ) * 0.5;
	coordinateEnd.z = dot( curPosition - g_LightPosition, g_LightForward );

	float3 coordinateDelta = coordinateEnd - coordinates;

	float2 vecForwardProjection;
	// vecForwardProject.x , y == how much does should vecForward go forward in terms of light vector?
	vecForwardProjection.x = dot( g_LightRight, vecForward );
	vecForwardProjection.y = dot( g_LightUp, vecForward );

	// Calculate coarse step size
	float longStepScale = int( g_CoarseDepthTexelSize / length( vecForwardProjection ) );
	longStepScale = max( longStepScale, 1 );
	
	float sampleFine;
	float2 sampleMinMax;
	float light = 0.0;
	float scatteredLight = 0.0;
	float coordinateZ_end;
	float isLongStep;
	float longStepScale_1 = longStepScale - 1;

	float longStepsNum = 0; 
	float realStepsNum = 0;

	//Taekyu so far
	float density = 0.0;
	//bool bForward = true;
	//bool bForwardNeighbor = true;
	//float3 prevPos;
	//float3 prevNeighborPoint;
	[loop]
	for( uint i = 0; i < stepsNum ; i++ )
    {
	// s0
	// s1
		//if(i != -1) continue;
		// I think that sampleMinMax.x stores minimum z value, y stores the maximum z value.
		sampleMinMax = s0.SampleLevel( samplerDepthMinMax, coordinates.xy, 0 ).xy;
// Q. SampleState. ==> How lighting texture works?
// Q. When techniques are exactly loaded? ==> Got the answer.
// Q. What are s0, s1 texture maps? s1 seems to be for light density.
// I think that DepthTexture is it.
		// Use point sampling. Linear sampling can cause the whole coarse step being incorrect
		// DepthTexture is just light map. How bright one vertex should be.
			// Taekyu
			// First, we get the light value for the ray marching point for every loop(ray-marching stops)
			shadowUV = mul( float4( oriCurPos, 1.0 ), g_ModelLightProj );
			coordinates = shadowUV.xyz / shadowUV.w;
			coordinates.x = ( coordinates.x + 1.0 ) * 0.5;
			coordinates.y = ( 1.0 - coordinates.y ) * 0.5;
			coordinates.z = dot( curPosition - g_LightPosition, g_LightForward );
			sampleFine = DepthTexture.SampleCmpLevelZero( samplerPoint_Less, coordinates.xy, coordinates.z );
			// b/f moving forward the ray, now we get the random neighbor point
			float particleDensity = ParticleTex.SampleLevel( samplerPoint, coordinates.xy, 0 );
			particleDensity = 1 - particleDensity;
			float3 directions = DirTex.SampleLevel( samplerPoint, coordinates.xy, 0 );
			/*float3x3 rotM = { 1., 0., 0.,
							0., cos(PI/2.), -sin(PI/2.),
							0., sin(PI/2.), sin(PI/2.)
							};
							directions = mul(rotM, directions);
							directions = normalize(directions);*/
//			float jitterX = NoiseTexture.SampleLevel( samplerPoint, coordinates.xy, 0 );
	//		directions.x += jitterX;
			directions = normalize( directions );
			//float distCoeff = sqrt(1.0) ;  // theory behind this. accordance with nishita model, density going up => scatter distance down, attenuation up ==> light down
			//float neighborDistance = 1.0 / exp(particleDensity * particleDensity * -1.0 * distCoeff); // the var name 'neighborAttenuation' makes more sense actually.
			float neighborDistance = distCoeff * (particleDensity);
			float3 neighborPoint = oriCurPos.xyz + directions.xyz * neighborDistance;
			// now we have the random neighbor point, then we get light value at the neighbor point.
			float4 neighborShadowUV;
			float3 neighborCoordinates;
			neighborShadowUV = mul(float4( neighborPoint, 1.0 ), g_ModelLightProj );
			neighborCoordinates = neighborShadowUV.xyz / neighborShadowUV.w;
			neighborCoordinates.x = ( neighborCoordinates.x + 1.0 ) * 0.5;
			neighborCoordinates.y = ( 1.0 - neighborCoordinates.y ) * 0.5;
			neighborCoordinates.z = dot( neighborPoint - g_LightPosition, g_LightForward );
			//return neighborCoordinates.y - coordinates.y;
			// diff bwt. neighbor and the original Position must be around 1 (suggested)
			// samplerPoint_LessWrap is wrong! for the light map.
			float neighborSample = DepthTexture.SampleCmpLevelZero( samplerPoint_Less, neighborCoordinates.xy, neighborCoordinates.z );
			//scatteredLight += neighborSample * exp(-1.0 * distCoeff);
			//Taekyu So far
			/////////////// Remember!!! The neighbor coor is farther which means that it is NOT dense air. ironically,
			/////////////// in this case, light intensity will be attenuated due to the distance.(though it should be brighter) Block that!
			/////////////// You need to place amplifying constant term based on particle density(after doing some experiment)
			//neighborSample = 0.1;
			/*
			const static float PI = 3.14159265f;
			float beta = 0.02f;
			float StoV = neighborPoint - g_EyePosition;
			float cosGamma = dot( normalize(StoV), normalize(vecForward) );
			float sinGamma = sqrt( 1 - cosGamma * cosGamma );
			float Dsv = sqrt( dot(StoV, StoV) );
			float Tsv = beta * Dsv;
			// Assume that Tvp = Dvp = infinity.
			float A0 = beta * beta * neighborSample * exp( -Tsv * cosGamma );
			A0 /= ( 2 * PI * Tsv * sinGamma );
			float A1 = Tsv * sinGamma;
			float2 uv = float2( A1, PI / 2.f );
			float F1 = AnalyticFuncTex.SampleLevel( samplerLinear, uv, 0 );
			uv = float2( A1, acos( cosGamma ) / 2.f );
			float F2 = AnalyticFuncTex.SampleLevel( samplerLinear, uv, 0 );
			float La = A0 * ( F1 - F2 );
			La = (La < 0.f) ? 0.f : La;
			*/
			// AirLight model.
			/*float beta = 1.0f;
			float gamma = acos(dot(normalize(neighborPoint - curPosition), normalize(vecForward)));
			float sv = g_EyePosition.xyz - neighborPoint; // I could use the point on the near plane or g_EyePosition. Which one is better?
			float Tsv = sqrt(dot(sv, sv)) * beta;
			float Tvp = sqrt(dot(g_EyePosition, g_EyePosition)) * beta;
			// Now I have the input setup. Get Texture.
			const static float PI = 3.14159265f;
			float A0 = beta * beta * neighborSample * exp(-Tsv * cos(gamma)) / ( 2 * PI * Tsv * sin(gamma) );
			float A1 = Tsv * sin(gamma);
			float2 uv = float2(A1, PI/4. + (1./2.) * atan(Tvp - Tsv * cos(gamma) / (Tsv * sin(gamma))  ) );
			uv.x = ( uv.x < 0.0 ) ? 0 : uv.x;
			uv.x = ( uv.x > 10.0 ) ? 10.0 : uv.x;
			uv.y = ( uv.y < 0.0 ) ? 0 : uv.y;
			uv.y = ( uv.y > PI / 2.f ) ? PI / 2.f : uv.y;
			// Now I must interpolate fit uv value in the range of u=[], v=[] to the coordinates.x,y=[0,512]
			uv.x = uv.x / 10.f;
			uv.y = uv.y / (PI / 2.f);
			float funcF1 = AnalyticFuncTex.SampleLevel( samplerLinear, uv, 0 );
			funcF1 = funcF1 * 2.0f; //every time you get F, you must multiply it by 2.0f.
			uv = float2(A1, gamma/2.f);
			uv.x /= 10.f;
			uv.y /= (PI / 2.f);
			float funcF2 = AnalyticFuncTex.SampleLevel( samplerLinear, uv, 0 );
			funcF2 = funcF2 * -2.0f;
			float La = A0 * (funcF1 + funcF2);
			//La = (La < 0.f) ? 0.f : La;*/
			
			// surface radiance model
			//float srBeta = 0.04;
srBeta = (particleDensity + 0.005) * 0.03;
			float Kd = 0.4;
			float Ks = 0.1;
			float I0 = 1.f;
			float3 SP = neighborPoint - g_LightPosition;
			float Dsp = 0.1 * sqrt( dot(SP, SP) );
			float Tsp = srBeta * Dsp;
			// Make textures for normal map, scattering reflection map.
			// Then set theta from reflection map then set normal from normal map.(Make sure normal looks at eye position.
			// you can do it by doing dot(vecForward, normal) < 0. If dot() > 0, flip the normal by (normal = -normal)
			float2 uv = float2( oriCurPos.x+oriCurPos.y, oriCurPos.x+oriCurPos.y+oriCurPos.z );	// natural uv. noise function may work.
			uv.x = (uv.x < 0.f) ? -uv.x : uv.x;
			uv.y = (uv.y < 0.f) ? -uv.y : uv.y;
			uv = fmod(uv, 1);
			float3 normal = DirTex.SampleLevel( samplerPoint, uv, 0 ); // Use DirTex instead of NormalTex. (NormalTex is NOT working!)
			if( dot(normal, vecForward) > 0 ) normal = -normal;
			uv = float2(1.f, 1.f) - uv; // shuffle the indices.
			float3 scatteringReflectionDir = DirTex.SampleLevel( samplerPoint, uv, 0 ); // Use DirTex instead of ReflectionTex. (ReflectionTex is NOT working!)
			// reflection scattering direction must be also that way as well.
			if( dot(scatteringReflectionDir, normal) < 0 ) scatteringReflectionDir = -scatteringReflectionDir;
			normal = normalize(normal);
			scatteringReflectionDir = normalize(scatteringReflectionDir);
			// From parameterization, theta from (N.L), newTheta from (R~, L)
			SP = normalize(SP);
			float srTheta = acos( dot(normal, -SP) );			// reflect func --> v = i - 2 * n * dot(i�n)
			srTheta = clamp(srTheta, 0, PI/2.f);
			// in the reflect func, you are supposed to use the direction towards the surface.(Ex : surface point - view point, NOT view point - surface point)
			float3 reflectedDir = reflect(-scatteringReflectionDir, normal);
			reflectedDir = normalize(reflectedDir);
			float srNewTheta = acos( dot(normal, reflectedDir) );
			srNewTheta = clamp(srNewTheta, 0, PI/2.f);
			// Surface radiance model should work only when density is > 0 or > 1.
			// then implement surface radiance model.
			// Don't forget to normalize the uv coordinates.
			Tsp = clamp(Tsp, 0.f, 10.f);
			uv = float2( Tsp / 10.f , srTheta / (PI/2.f) ); // UV must be interpolated in the range.
			float G0 = AnalyticFuncTex.SampleLevel( samplerLinear, uv, 0 ); // I loaded G function(G0) in AnalyticFuncTex since GFuncTex is NOT working.
			G0 *= 8.0676f;
			//uv = float2( Tsp / 10.f , srNewTheta / (PI/2.f) );
			//float G20 = GFunc10Tex.SampleLevel( samplerLinear, uv, 0 );
			float diffuse = I0 * Kd * ( exp(-Tsp) * cos(srTheta) / (Dsp * Dsp) + srBeta * srBeta * G0 / (2 * PI * Tsp) );
			diffuse *= 1 - pow(particleDensity, 0.4);//exp( -(particleDensity *particleDensity) );
			//float specular = I0 * Ks * ( exp(-Tsp) * pow(cos(srNewTheta), 20) / (Dsp * Dsp) + srBeta * srBeta * G20 / (2 * PI * Tsp) );
			float surfaceRadiance = diffuse; // for now, no specular.
			// I guess, to get a more natural-looking image, I should loop. Every time, I should manually change 

			// multi-sampling
			if( bMultiSampling == true )
			{
				distCoeff = distCoeff * 0.5f + random(0.f, 0.1f);
				float2 uv2 = float2(1.0 , 1.0);
				//uv2.x = noise(uv.y);
				uv2.x = scatteringReflectionDir.y;
				uv2.y = scatteringReflectionDir.z;
				particleDensity = ParticleTex.SampleLevel( samplerPoint, uv2, 0 );
				directions = DirTex.SampleLevel( samplerPoint, uv2 , 0 );
				neighborDistance = distCoeff * (particleDensity);
				neighborPoint = oriCurPos.xyz + directions.xyz * neighborDistance;
				// now we have the random neighbor point, then we get light value at the neighbor point.
				float4 neighborShadowUV;
				float3 neighborCoordinates;
				neighborShadowUV = mul(float4( neighborPoint, 1.0 ), g_ModelLightProj );
				neighborCoordinates = neighborShadowUV.xyz / neighborShadowUV.w;
				neighborCoordinates.x = ( neighborCoordinates.x + 1.0 ) * 0.5;
				neighborCoordinates.y = ( 1.0 - neighborCoordinates.y ) * 0.5;
				neighborCoordinates.z = dot( neighborPoint - g_LightPosition, g_LightForward );
				// diff bwt. neighbor and the original Position must be around 1 (suggested)
				float neighborSample = DepthTexture.SampleCmpLevelZero( samplerPoint_Less, neighborCoordinates.xy, neighborCoordinates.z );
				surfaceRadiance += surfaceRadianceModel( srBeta, Kd, Ks, I0, oriCurPos, neighborPoint, g_LightPosition, vecForward, particleDensity );
			}

		float zStart = s1.SampleLevel( samplerPoint, coordinates.xy, 0 );
		
		const float transactionScale = 100.0f;
		
		// Add some attenuation for smooth light fading out
		float attenuation = ( coordinates.z - zStart ) / ( ( sampleMinMax.y + transactionScale ) - zStart );
		attenuation = saturate( attenuation );
		attenuation = 1.0 - attenuation;
		attenuation *= attenuation;

		float attenuation2 = ( ( zStart + transactionScale ) - coordinates.z ) * ( 1.0 / transactionScale );
		attenuation2 = 1.0 - saturate( attenuation2 );

		attenuation *= attenuation2;
		
		// Use this value to increase light factor for "indoor" areas
		density = s1.SampleCmpLevelZero( samplerPoint_Greater, coordinates.xy, coordinates.z );
		density *= 10.0 * attenuation;
		density += 0.25;
		neighborSample *= density;
		sampleFine *= density;
		surfaceRadiance *= density * 25.7905201051118;
		//La *= density;
		coordinateZ_end = coordinates.z + coordinateDelta.z * longStepScale;
		
		float comparisonValue = max( coordinates.z, coordinateZ_end );
		float isLight = comparisonValue < sampleMinMax.x; // .x stores min depth values
		
		comparisonValue = min( coordinates.z, coordinateZ_end );
		float isShadow = comparisonValue > sampleMinMax.y; // .y stores max depth values
		
		// We can perform coarse step if all samples are in light or shadow
		isLongStep = isLight + isShadow;

		longStepsNum += isLongStep;
		realStepsNum += 1.0;

		if( useZOptimizations )
		{
			light += scale * sampleFine * ( 1.0 + isLongStep * longStepScale_1 ); // longStepScale should be >= 1 if we use a coarse step

			coordinates += coordinateDelta * ( 1.0 + isLongStep * longStepScale_1 );
			i += isLongStep * longStepScale_1;
		}
		else
		{
			light += scale * sampleFine;
			//scatteredLight += scale * La;
			scatteredLight += surfaceRadiance;
//			coordinates += coordinateDelta;
			oriCurPos += vecForward;
			//vecForward.x = (vecForward.x  < 0.0f) ? -vecForward.x : vecForward.x ;
			//vecForward.y = (vecForward.y  < 0.0f) ? -vecForward.y : vecForward.y ;
			//vecForward.z = (vecForward.z  < 0.0f) ? -vecForward.z : vecForward.z ;
			//return vecForward.y/2 ;
		}
		/*if(prevPos.y == oriCurPos.y)
			{bForward = false; return -1;}
		if(prevNeighborPoint.y == neighborPoint.y)
			{bForwardNeighbor = false; return -2;}*/
    }


	// Do correction for final coarse steps.
	if( useZOptimizations )
	{
		light -= scale * sampleFine * ( i - stepsNum );
	}

	//return longStepsNum / realStepsNum;
	//return light * cos( light );
//	if(scatteredLight < 0.0)
//		return 1;
//	else if(scatteredLight >= 0 && scatteredLight <= 1.0)
//		return 0;
//	else if(scatteredLight > 1.)
//		return -1;

	return light * 0.25 + scatteredLight;
}

// Build min max texture for 2x2 kernel from original map
float2 MinMax2x2_1( PSInQuad input ) : SV_Target
{
	float2 textureOffset;
	textureOffset.x = g_BufferWidthInv * 0.25;
	textureOffset.y = g_BufferHeightInv * 0.25;
	
	float depth1 = s0.Sample( samplerPointClamp, input.texCoord + float2(textureOffset.x, textureOffset.y) );
	float depth2 = s0.Sample( samplerPointClamp, input.texCoord + float2(textureOffset.x, -textureOffset.y) );
	float depth3 = s0.Sample( samplerPointClamp, input.texCoord + float2(-textureOffset.x, textureOffset.y) );
	float depth4 = s0.Sample( samplerPointClamp, input.texCoord + float2(-textureOffset.x, -textureOffset.y) );
		
	float minDepth = min( depth1, depth2 );
	minDepth = min( minDepth, depth3 );
	minDepth = min( minDepth, depth4 );
	
	float maxDepth = max( depth1, depth2 );
	maxDepth = max( maxDepth, depth3 );
	maxDepth = max( maxDepth, depth4 );

	minDepth -= 25.0;
	maxDepth += 25.0;
	
	return float2( minDepth, maxDepth );
}

// Build min max texture mip
float2 MinMax2x2_2( PSInQuad input ) : SV_Target
{
	float2 textureOffset;
	textureOffset.x = g_BufferWidthInv * 0.25;
	textureOffset.y = g_BufferHeightInv * 0.25;
	
	float2 depth1 = s0.Sample( samplerPointClamp, input.texCoord + float2(textureOffset.x, textureOffset.y) );
	float2 depth2 = s0.Sample( samplerPointClamp, input.texCoord + float2(textureOffset.x, -textureOffset.y) );
	float2 depth3 = s0.Sample( samplerPointClamp, input.texCoord + float2(-textureOffset.x, textureOffset.y) );
	float2 depth4 = s0.Sample( samplerPointClamp, input.texCoord + float2(-textureOffset.x, -textureOffset.y) );
	
	float minDepth = min( depth1.x, depth2.x );
	minDepth = min( minDepth, depth3.x );
	minDepth = min( minDepth, depth4.x );

	float maxDepth = max( depth1.y, depth2.y );
	maxDepth = max( maxDepth, depth3.y );
	maxDepth = max( maxDepth, depth4.y );

	return float2( minDepth, maxDepth );
}

// Get min and max values for 3x3 sample grid for coarse tracing.
// Use many steps ("heavy" shader), but the texture is relatively small.
float2 MinMax3x3( PSInQuad input ) : SV_Target
{
	float2 depth1 = s0.Sample( samplerPointClamp, input.texCoord);
	float2 depth2 = s0.Sample( samplerPointClamp, input.texCoord, int2(0,1) );
	float2 depth3 = s0.Sample( samplerPointClamp, input.texCoord, int2(1,1) );
	float2 depth4 = s0.Sample( samplerPointClamp, input.texCoord, int2(1,0) );
	float2 depth5 = s0.Sample( samplerPointClamp, input.texCoord, int2(1,-1) );
	float2 depth6 = s0.Sample( samplerPointClamp, input.texCoord, int2(0,-1) );
	float2 depth7 = s0.Sample( samplerPointClamp, input.texCoord, int2(-1,-1) );
	float2 depth8 = s0.Sample( samplerPointClamp, input.texCoord, int2(-1,0) );
	float2 depth9 = s0.Sample( samplerPointClamp, input.texCoord, int2(-1,1) );

	float minDepth = min( depth1.x, depth2.x );
	minDepth = min( minDepth, depth3.x );
	minDepth = min( minDepth, depth4.x );
	minDepth = min( minDepth, depth5.x );
	minDepth = min( minDepth, depth6.x );
	minDepth = min( minDepth, depth7.x );
	minDepth = min( minDepth, depth8.x );
	minDepth = min( minDepth, depth9.x );
	
	float maxDepth = max( depth1.y, depth2.y );
	maxDepth = max( maxDepth, depth3.y );
	maxDepth = max( maxDepth, depth4.y );
	maxDepth = max( maxDepth, depth5.y );
	maxDepth = max( maxDepth, depth6.y );
	maxDepth = max( maxDepth, depth7.y );
	maxDepth = max( maxDepth, depth8.y );
	maxDepth = max( maxDepth, depth9.y );

	return float2( minDepth, maxDepth );
}

float PropagateMinDepth_0( PSInQuad input ) : SV_Target
{	
	float depth0 = s0.Sample( samplerPoint, input.texCoord ).y;
	float threshold = depth0 - 100.0;

	float depth1 = s0.Sample( samplerPoint, input.texCoord, int2(1,0) ).y;
	float depth2 = s0.Sample( samplerPoint, input.texCoord, int2(0,-1) ).y;
	float depth3 = s0.Sample( samplerPoint, input.texCoord, int2(-1,0) ).y;
	float depth4 = s0.Sample( samplerPoint, input.texCoord, int2(0,1) ).y;

	float depthMin = min( depth1, depth2 );
	depthMin = min( depthMin, depth3 );
	depthMin = min( depthMin, depth4 );

	depth1 = s0.Sample( samplerPoint, input.texCoord, int2( 1, 1) ).y;
	depth2 = s0.Sample( samplerPoint, input.texCoord, int2( 1,-1) ).y;
	depth3 = s0.Sample( samplerPoint, input.texCoord, int2(-1,-1) ).y;
	depth4 = s0.Sample( samplerPoint, input.texCoord, int2(-1, 1) ).y;

	depthMin = min( depthMin, depth1 );
	depthMin = min( depthMin, depth2 );
	depthMin = min( depthMin, depth3 );
	depthMin = min( depthMin, depth4 );
	
	float propogate = threshold > depthMin;
	
	return lerp( depth0, depthMin, propogate ); 
}

float PropagateMinDepth_1( PSInQuad input ) : SV_Target
{	
	float depth0 = s0.Sample( samplerPoint, input.texCoord);
	float threshold = depth0 - 100.0;

	float depth1 = s0.Sample( samplerPoint, input.texCoord, int2(1,0) );
	float depth2 = s0.Sample( samplerPoint, input.texCoord, int2(0,-1) );
	float depth3 = s0.Sample( samplerPoint, input.texCoord, int2(-1,0) );
	float depth4 = s0.Sample( samplerPoint, input.texCoord, int2(0,1) );

	float depthMin = min( depth1, depth2 );
	depthMin = min( depthMin, depth3 );
	depthMin = min( depthMin, depth4 );

	depth1 = s0.Sample( samplerPoint, input.texCoord, int2( 1, 1) );
	depth2 = s0.Sample( samplerPoint, input.texCoord, int2( 1,-1) );
	depth3 = s0.Sample( samplerPoint, input.texCoord, int2(-1,-1) );
	depth4 = s0.Sample( samplerPoint, input.texCoord, int2(-1, 1) );

	depthMin = min( depthMin, depth1 );
	depthMin = min( depthMin, depth2 );
	depthMin = min( depthMin, depth3 );
	depthMin = min( depthMin, depth4 );
	
	float propogate = threshold > depthMin;
	
	return lerp( depth0, depthMin, propogate ); 
}

float PropagateMaxDepth( PSInQuad input ) : SV_Target
{	
	float depth0 = s0.Sample( samplerPoint, input.texCoord);
	float threshold = depth0 + 100.0; 

	float depth1 = s0.Sample( samplerPoint, input.texCoord, int2(1,0) );
	float depth2 = s0.Sample( samplerPoint, input.texCoord, int2(0,-1) );
	float depth3 = s0.Sample( samplerPoint, input.texCoord, int2(-1,0) );
	float depth4 = s0.Sample( samplerPoint, input.texCoord, int2(0,1) );

	float depth5 = s0.Sample( samplerPoint, input.texCoord, int2(1,1) );
	float depth6 = s0.Sample( samplerPoint, input.texCoord, int2(1,-1) );
	float depth7 = s0.Sample( samplerPoint, input.texCoord, int2(-1,-1) );
	float depth8 = s0.Sample( samplerPoint, input.texCoord, int2(-1,1) );

	float depthMax = max( depth1, depth2 );
	depthMax = max( depthMax, depth3 );
	depthMax = max( depthMax, depth4 );
	depthMax = max( depthMax, depth5 );
	depthMax = max( depthMax, depth6 );
	depthMax = max( depthMax, depth7 );
	depthMax = max( depthMax, depth8 );

	float propogate = threshold < depthMax;
	propogate = saturate( propogate );
	
	return lerp( depth0, depthMax, propogate ); 
}

// Converts depth values to world scale depth
float ConvertToWorld( PSInQuad input ) : SV_Target
{
	float sceneDepth = s0.Sample( samplerPoint, input.texCoord.xy );
	
    float4 clipPos;
	clipPos.x = 2.0 * input.texCoord.x - 1.0;
	clipPos.y = -2.0 * input.texCoord.y + 1.0;
	clipPos.z = sceneDepth;
	clipPos.w = 1.0;
						
	float4 positionWS = mul( clipPos, g_ModelLightProjInv );
	positionWS.w = 1.0 / positionWS.w;
	positionWS.xyz *= positionWS.w;

	return dot( positionWS.xyz - g_LightPosition, g_LightForward );
}

// Converts depth values to world scale depth
float ConvertDepthWorldNormalized( PSInQuad input ) : SV_Target
{
	float sceneDepth = s0.Sample( samplerPoint, input.texCoord.xy );
	
    float4 clipPos;
	clipPos.x = 2.0 * input.texCoord.x - 1.0;
	clipPos.y = -2.0 * input.texCoord.y + 1.0;
	clipPos.z = sceneDepth;
	clipPos.w = 1.0;
						
	float4 positionWS = mul( clipPos, g_MWorldViewProjectionInv );
	positionWS.w = 1.0 / positionWS.w;
	positionWS.xyz *= positionWS.w;

	return dot( positionWS.xyz - g_EyePosition, g_WorldFront );
}

PSOut PS_ShadowMap( PSIn_ShadowMap input )
{
    PSOut output;
    output.color = 1.0;
    return output;
}

//-----------------------------------------------------------------------------
// Name: DownScale2x2_Lum
// Type: Pixel shader                                      
// Desc: Scale down the source texture from the average of 3x3 blocks and
//       convert to grayscale
//-----------------------------------------------------------------------------
float4 DownScale2x2_Lum ( PSInQuad input ) : SV_TARGET
{    
    float3 vColor;
    float fAvg = 0.0f;
    
    for( int y = -1; y < 1; y++ )
    {
        for( int x = -1; x < 1; x++ )
        {
            // Compute the sum of color values
            vColor = s0.Sample( samplerLinearClamp, input.texCoord, int2(x,y) ).rgb;
            fAvg += dot( vColor.rgb, LUMINANCE_VECTOR );
        }
    }
    
    fAvg *= 0.25;

    return float4(fAvg, fAvg, fAvg, 1.0f);
}


//-----------------------------------------------------------------------------
// Name: DownScale3x3
// Type: Pixel shader                                      
// Desc: Scale down the source texture from the average of 3x3 blocks
//-----------------------------------------------------------------------------
float4 DownScale3x3( PSInQuad input ) : SV_TARGET
{
    float fAvg = 0.0f; 
    float vColor;
    
    for( int y = -1; y <= 1; y++ )
    {
        for( int x = -1; x <= 1; x++ )
        {
            // Compute the sum of color values
            vColor = s0.Sample( samplerLinearClamp, input.texCoord, int2(x,y) ).x;
            fAvg += vColor.r; 
        }
    }
    
    // Divide the sum to complete the average
    fAvg /= 9;

    return float4(fAvg, fAvg, fAvg, 1.0f);
}


//-----------------------------------------------------------------------------
// Name: DownScale3x3_BrightPass
// Type: Pixel shader                                      
// Desc: Scale down the source texture from the average of 3x3 blocks
//-----------------------------------------------------------------------------
float4 DownScale3x3_BrightPass( PSInQuad input ) : SV_TARGET
{   
    float3 vColor = 0.0f;
    float4 vLum = s1.Sample( samplerPoint, float2(0, 0) );
    float  fLum;
    
    fLum = vLum.r;
       
    for( int y = -1; y <= 1; y++ ) 
    {
        for( int x = -1; x <= 1; x++ )
        {
            // Compute the sum of color values
            float4 vSample = s0.Sample( samplerLinearClamp, input.texCoord, int2(x,y) );
            vColor += vSample.rgb;
        }
    }
    
    // Divide the sum to complete the average
    vColor /= 9;
 
    // Bright pass and tone mapping
    vColor = max( 0.0f, vColor - BRIGHT_THRESHOLD );
    vColor *= MIDDLE_GRAY / (fLum + 0.001f);
    vColor *= (1.0f + vColor/LUM_WHITE);
    vColor /= (1.0f + vColor);
    
    return float4(vColor, 1.0f);
}


//-----------------------------------------------------------------------------
// Name: Bloom
// Type: Pixel shader                                      
// Desc: Blur the source image along the horizontal using a gaussian
//       distribution
//-----------------------------------------------------------------------------
float4 BloomHorizontal( PSInQuad input ) : SV_TARGET
{    
    float4 vSample = 0.0f;
    float4 vColor = 0.0f;
    float2 vSamplePosition;
    
    for( int iSample = 0; iSample < 15; iSample++ )
    {
        // Sample from adjacent points
        vSamplePosition = input.texCoord + g_avSampleOffsetsHorizontal[iSample].xy;
        vColor = s0.Sample( samplerLinearClamp, vSamplePosition );
        
        vSample += g_avSampleWeights[iSample] * vColor;
    }
    
    return vSample;
}

float4 BloomVertical( PSInQuad input ) : SV_TARGET
{    
    float4 vSample = 0.0f;
    float4 vColor = 0.0f;
    float2 vSamplePosition;
    
    for( int iSample = 0; iSample < 15; iSample++ )
    {
        // Sample from adjacent points
        vSamplePosition = input.texCoord + g_avSampleOffsetsVertical[iSample].xy;
        vColor = s0.Sample( samplerLinearClamp, vSamplePosition );
        
        vSample += g_avSampleWeights[iSample] * vColor;
    }
    
    return vSample;
}

float GradientBlur( PSInQuad input ) : SV_TARGET
{    
    float2 gradient = s2.Sample( samplerLinearClamp, input.texCoord ).xy;
	float2 offset;

	offset.x = g_CoarseTextureWidthInv * gradient.y; 
	offset.y = g_CoarseTextureWidthInv * gradient.x;
	
	float vColor = s0.Sample( samplerLinearClamp, input.texCoord ); //0.0f;
    /*
    for( int iSample = -7; iSample < 8; iSample++ )
    {
		vColor += s0.Sample( samplerLinearClamp, input.texCoord + offset * iSample );
    }*/
    
//    vColor *= ( 1.0 / 15.0 );
	return vColor;
}

float ImageBlur( PSInQuad input ) : SV_TARGET
{    
	float sample0 = s0.Sample( samplerLinearClamp, input.texCoord, int2(-1, -1) );
	float sample1 = s0.Sample( samplerLinearClamp, input.texCoord, int2( 0, -1) );
	float sample2 = s0.Sample( samplerLinearClamp, input.texCoord, int2( 1, -1) );
	
	float sample3 = s0.Sample( samplerLinearClamp, input.texCoord, int2(-1, 0) );
	float sample4 = s0.Sample( samplerLinearClamp, input.texCoord, int2( 0, 0) );
	float sample5 = s0.Sample( samplerLinearClamp, input.texCoord, int2( 1, 0) );

	float sample6 = s0.Sample( samplerLinearClamp, input.texCoord, int2(-1, 1) );
	float sample7 = s0.Sample( samplerLinearClamp, input.texCoord, int2( 0, 1) );
	float sample8 = s0.Sample( samplerLinearClamp, input.texCoord, int2( 1, 1) );
    
/*	float vColor = sample0 + sample1 + sample2;
	vColor += sample3 + sample4 + sample5;
	vColor += sample6 + sample7 + sample8;
 */
	float vColor = sample4;   
//    vColor *= ( 1.0 / 9.0 );
	return vColor;
}


//-----------------------------------------------------------------------------
// Name: FinalPass
// Type: Pixel Shader
// Desc: 
//-----------------------------------------------------------------------------
float4 FinalPass( PSInQuad input ) : SV_TARGET
{   
    float4 vColor = s0.Sample( samplerPointClamp, input.texCoord );
    float vLum = s1.Sample( samplerPointClamp, float2(0,0) ).r;
    float3 vBloom = s2.Sample( samplerLinearClamp, input.texCoord );
    
    // Tone mapping
    vColor.rgb *= MIDDLE_GRAY / ( vLum + 0.001f );
    vColor.rgb *= ( 1.0f + vColor/LUM_WHITE );
    vColor.rgb /= ( 1.0f + vColor );
    
    vColor.rgb += 0.6f * vBloom;
	vColor.a = 1.0f;
    
    return vColor;
}


//-----------------------------------------------------------------------------
// Name: BlendLight
// Type: Pixel Shader
// Desc: Blend light shafts with the final image
//-----------------------------------------------------------------------------
float4 BlendLight( PSInQuad input ) : SV_TARGET
{   
	float4 vColor;
	
	vColor.xyz = 0.75;
	vColor.w = s0.Sample( samplerLinearClamp, input.texCoord ).x;
	
	return vColor;
}

//-----------------------------------------------------------------------------
// Name: EdgeDetection
// Type: Pixel Shader
// Desc: Detect edges for final image bluring
//-----------------------------------------------------------------------------
float2 EdgeDetection( PSInQuad input ) : SV_TARGET
{
	float isEdge = 0;

	float offsetX = g_CoarseTextureWidthInv * 0.5;
	float offsetY = g_CoarseTextureHeightInv * 0.5;
		
	float c0 = s0.Sample( samplerLinearClamp, input.texCoord ).x;

	float c1 = s0.Sample( samplerLinearClamp, input.texCoord + float2( offsetX, 0) ).x;
	float c2 = s0.Sample( samplerLinearClamp, input.texCoord + float2( 0,-offsetY) ).x;
	float c3 = s0.Sample( samplerLinearClamp, input.texCoord + float2(-offsetX, 0) ).x;
	float c4 = s0.Sample( samplerLinearClamp, input.texCoord + float2( 0, offsetY) ).x;

	float c5 = s0.Sample( samplerLinearClamp, input.texCoord + float2( offsetX, offsetY) ).x;
	float c6 = s0.Sample( samplerLinearClamp, input.texCoord + float2( offsetX,-offsetY) ).x;
	float c7 = s0.Sample( samplerLinearClamp, input.texCoord + float2(-offsetX,-offsetY) ).x;
	float c8 = s0.Sample( samplerLinearClamp, input.texCoord + float2(-offsetX, offsetY) ).x;

	float c9 =  s0.Sample( samplerLinearClamp, input.texCoord + float2( -2.0 * offsetX, -2.0 * offsetY) ).x;
	float c10 = s0.Sample( samplerLinearClamp, input.texCoord + float2( -1.0 * offsetX, -2.0 * offsetY) ).x;
	float c11 = s0.Sample( samplerLinearClamp, input.texCoord + float2(  0.0 * offsetX, -2.0 * offsetY) ).x;
	float c12 = s0.Sample( samplerLinearClamp, input.texCoord + float2(  1.0 * offsetX, -2.0 * offsetY) ).x;
	float c13 = s0.Sample( samplerLinearClamp, input.texCoord + float2(  2.0 * offsetX, -2.0 * offsetY) ).x;

	float c14 = s0.Sample( samplerLinearClamp, input.texCoord + float2( -2.0 * offsetX, 2.0 * offsetY) ).x;
	float c15 = s0.Sample( samplerLinearClamp, input.texCoord + float2( -1.0 * offsetX, 2.0 * offsetY) ).x;
	float c16 = s0.Sample( samplerLinearClamp, input.texCoord + float2(  0.0 * offsetX, 2.0 * offsetY) ).x;
	float c17 = s0.Sample( samplerLinearClamp, input.texCoord + float2(  1.0 * offsetX, 2.0 * offsetY) ).x;
	float c18 = s0.Sample( samplerLinearClamp, input.texCoord + float2(  2.0 * offsetX, 2.0 * offsetY) ).x;

	float c19 = s0.Sample( samplerLinearClamp, input.texCoord + float2( -2.0 * offsetX, -1.0 * offsetY) ).x;
	float c20 = s0.Sample( samplerLinearClamp, input.texCoord + float2(  2.0 * offsetX, -1.0 * offsetY) ).x;
	float c21 = s0.Sample( samplerLinearClamp, input.texCoord + float2( -2.0 * offsetX,  0.0 * offsetY) ).x;
	float c22 = s0.Sample( samplerLinearClamp, input.texCoord + float2(  2.0 * offsetX,  0.0 * offsetY) ).x;
	float c23 = s0.Sample( samplerLinearClamp, input.texCoord + float2( -2.0 * offsetX,  1.0 * offsetY) ).x;
	float c24 = s0.Sample( samplerLinearClamp, input.texCoord + float2(  2.0 * offsetX,  1.0 * offsetY) ).x;

	// Apply Sobel 5x5 edge detection filter
	float Gx = 1.0 * ( -c9 -c14 + c13 + c18 ) + 2.0 * ( -c19 -c23 - c10 - c15 + c12 + c17 + c20 + c24 ) + 3.0 * ( -c21 -c7 -c8 + c6 + c5 + c22 ) + 5.0 * ( -c3 + c1 );
	float Gy = 1.0 * ( -c14 -c18 + c9 + c13 ) + 2.0 * ( -c15 -c17 - c23 - c24 + c19 + c20 + c10 + c12 ) + 3.0 * ( -c16 -c8 -c5 + c6 + c7 + c11 ) + 5.0 * ( -c4 + c2 );
	float scale = 25.0; // Blur scale, can be depth dependent

	return float2( Gx * scale, Gy * scale );
}


//-----------------------------------------------------------------------------
// Name: BlendLightPP
// Type: Pixel Shader
// Desc: Blend light shafts with the final image and PP
//------------------------------------------------------------------- ----------
float4 BlendLightPP( PSInQuad input ) : SV_TARGET
{   
	float4 vColor = 0;

	float lightBlend = s1.Sample( samplerLinearClamp, input.texCoord ).x;
	
	vColor.xyz = 0.75;
	vColor.w = lightBlend;

	return vColor;
}


//--------------------------------------------------------------------------------------
// Compiled shaders used in different techniques
//--------------------------------------------------------------------------------------

VertexShader vsCompiledQuad = CompileShader( vs_4_0, VSMainQuad() );

GeometryShader gsCompiledQuad = CompileShader( gs_4_0, GSMainQuad() );

//--------------------------------------------------------------------------------------
// Rendering techniques
//--------------------------------------------------------------------------------------

technique10 RenderDiffuse
{
    pass p0
    {
        SetRasterizerState( RenderNoCull );
		SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
        
        SetVertexShader( CompileShader( vs_4_0, VS_Diffuse() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_Diffuse() ) );
    }
}

technique10 Tracing
{
 	pass FullScreen_Base
    {
        SetRasterizerState( RenderBackFace );
        SetDepthStencilState( NoDepthStencil, 0 );
		//SetBlendState( SrcAlphaBlendingAdd, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
        
        SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, PS_TracingFullscreen( false ) ) );
    }

	pass FullScreen_Optimized
    {
        SetRasterizerState( RenderBackFace );
        SetDepthStencilState( NoDepthStencil, 0 );
		//SetBlendState( SrcAlphaBlendingAdd, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
        
        SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, PS_TracingFullscreen( true ) ) );
    }
}

technique10 ShadowmapPass
{
    pass p0
    {
        SetRasterizerState( RenderNoCull );
		SetRasterizerState( RenderFrontFace );
		//SetRasterizerState( RenderBackFace );
		
		SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
        
        SetVertexShader( CompileShader( vs_4_0, VS_ShadowMap() ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, PS_ShadowMap() ) );
    }
}

technique10 DummyPass
{
    pass p0
    {
	
		SetRasterizerState( RenderNoCull );
		SetDepthStencilState( RenderDepthNormal, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
    }
}

technique10 tDownScale2x2_Lum
{
    pass p0
    {
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		SetDepthStencilState( NoDepthStencil, 0 );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, DownScale2x2_Lum() ) );
    }
}

technique10 tDownScale3x3
{
    pass p0
    {
        SetDepthStencilState( NoDepthStencil, 0 );
		SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, DownScale3x3() ) );
    }
}

technique10 tDownScale3x3_BrightPass
{
    pass p0
    {
        SetDepthStencilState( NoDepthStencil, 0 );
		SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, DownScale3x3_BrightPass() ) );
    }
}

technique10 tFinalPass
{
    pass p0
    {
        SetDepthStencilState( NoDepthStencil, 0 );
		SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
				
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, FinalPass() ) );
    }
}

technique10 BlendFullscreen
{
    pass p0
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( SrcAlphaBlendingAdd, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, BlendLight() ) );
    }

	pass p1
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( SrcAlphaBlendingAddDstZero, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, BlendLight() ) );
    }
}

technique10 BlendFullscreenPP
{
	pass p0
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( SrcAlphaBlendingAdd, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, BlendLightPP() ) );
    }

	pass p1
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( SrcAlphaBlendingAddDstZero, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, BlendLightPP() ) );
    }
}

technique10 DepthProcessing
{
    pass pMinMax2x2_1
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, MinMax2x2_1() ) );
    }
	
	pass pMinMax2x2_2
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, MinMax2x2_2() ) );
    }

	pass pMinMax3x3
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, MinMax3x3() ) );
    }

	pass pConvertToWorld
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, ConvertToWorld() ) );
    }

	pass pPropagateMinDepth_0
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, PropagateMinDepth_0() ) );
    }

	pass pPropagateMinDepth_1
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, PropagateMinDepth_1() ) );
    }

	pass pPropagateMaxDepth
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, PropagateMaxDepth() ) );
    }

	pass pConvertDepthWorldNormalized
	{
		 SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, ConvertDepthWorldNormalized() ) );	
	}
}

//-----------------------------------------------------------------------------
// Technique: Bloom
// Desc: 
//-----------------------------------------------------------------------------
technique10 BloomTech
{
    pass p0
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, BloomHorizontal() ) );
    }

	pass p1
    {
        SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, BloomVertical() ) );
    }
}


technique10 EdgeProcessing
{
	pass pEdgeDetection
	{
		SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, EdgeDetection() ) );
	}

	pass pGradientBlur
	{
		SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, GradientBlur() ) );	
	}

	pass pImageBlur
	{
		SetDepthStencilState( NoDepthStencil, 0 );
        SetBlendState( NoBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
		
		SetVertexShader( vsCompiledQuad );
        SetGeometryShader( gsCompiledQuad );
        SetPixelShader( CompileShader( ps_4_0, ImageBlur() ) );	
	}
}