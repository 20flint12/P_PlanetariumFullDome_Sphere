#include <effects\Bicubic.fxh>

//blend properties
//!!!!!!!!!!!!!!!!!!!!!
// Change here to match your blend region count.
// This should generally be equal your viewport*renderer count
#define nRegions 3
//!!!!!!!!!!!!!!!!!!!!!


// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (EX9)
float4x4 tP: PROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;

//texture
texture Tex <string uiname="Texture";>;

float yBlends[nRegions-1];
float blendWidth=0.1;
float3 gammaRGB=1;
bool calibrate=0;
float lineWidth=0.01;
float3 blendVector=float3(0,1,0);


//texture projection properties
bool useProjection=false; // false=use vertex tex coords, true=use world coords
float4x4 tProjector;

//viewports
int ViewIndex: VIEWPORTINDEX;

//samplers
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

//only for the neares neighbour ps
sampler SampPoint = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = point;         //sampler states
    MinFilter = point;
    MagFilter = point;
};

//texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

//alpha
float Alpha <float uimin=0.0; float uimax=1.0;> = 1;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float4 TexCd : TEXCOORD0;
    float4 PosW : TEXCOORD1;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

vs2ps VS(
    float4 PosO  : POSITION,
    float4 TexCd : TEXCOORD0
    )
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    //transform position
    Out.Pos = mul(PosO, tWVP);
    float4 PosW = mul(PosO, tW);

    //transform texturecoordinates
    if (useProjection)
    {
        Out.TexCd = mul(PosW, tProjector);
    }
    else
        Out.TexCd = mul(TexCd, tTex);
    
    Out.PosW = mul(PosO, tW);
    
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float3 factor(float pos)
{
    float xTop = yBlends[ViewIndex-1];
    float xBase = yBlends[ViewIndex];


	float factortop = clamp((pos - (xTop-blendWidth/2)) /
					((xTop+blendWidth/2)-(xTop-blendWidth/2)), 0, 1);
	
    if (ViewIndex==0)
        factortop=1;


    float factorbottom = 1 - clamp((pos - (xBase-blendWidth/2)) /
					((xBase+blendWidth/2)-(xBase-blendWidth/2)), 0, 1);
	
    if (ViewIndex==nRegions-1)
        factorbottom=1;

	return factorbottom * factortop;
	
    //return pow(factortop * factorbottom, gammaRGB);
}

float4 calPattern(float x)
{
    float top = yBlends[ViewIndex-1];
    float base = yBlends[ViewIndex];
    
    float4 col = 0;
    
    if (ViewIndex>0)
        col += 1-smoothstep(lineWidth/2,lineWidth,abs(top-x));
        
    if (ViewIndex<nRegions-1)
        col += 1-smoothstep(lineWidth/2,lineWidth,abs(base-x));

// checkerboard
//    col.a = ((PosW.xyz/0.2) - floor(PosW.xyz/0.2)>0.5).x;

 return col;
}

float4 PSGeneral(vs2ps In, float4 texCol)
{
  if (useProjection)
  {
  	In.TexCd /= In.TexCd.w;
  	In.TexCd.xy+=1;
  	In.TexCd.xy /=2;
  	In.TexCd.y=1-In.TexCd.y;
  }

  float4 col = texCol;
  
  col.a *= Alpha;
  
  float x = dot(In.PosW.xyz, blendVector);
	
  col.rgb *= factor(x);

  if (calibrate)
     col += calPattern(x);
  
  return col;
}

// PS Bicubic
float4 PSbic(vs2ps In) : COLOR
{
	return PSGeneral(In, tex2Dbicubic(Samp, In.TexCd));
}

// PS Bilinear
float4 PSlin(vs2ps In) : COLOR
{
	return PSGeneral(In, tex2D(Samp, In.TexCd));
}

// PS Nearest Neighbour
float4 PSnn(vs2ps In) : COLOR
{
	return PSGeneral(In, tex2D(SampPoint, In.TexCd));
}

technique Bicubic
{
    pass p0
    {
		VertexShader = compile vs_3_0 VS();
		PixelShader = compile ps_3_0 PSbic();
    }
}

technique Bilinear
{
    pass p0
    {
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSlin();
    }
}

technique NearestNeighbour
{
    pass p0
    {
		VertexShader = compile vs_1_1 VS();
		PixelShader = compile ps_2_0 PSnn();
    }
}
