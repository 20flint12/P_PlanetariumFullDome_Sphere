// this is an effect template. use it to start writing your own effects.

 // -------------------------------------------------------------------------
 // PARAMETERS:
 // -------------------------------------------------------------------------


 //transforms
 float4x4 tW: WORLD; //the models world matrix
 float4x4 tV: VIEW; //view matrix as set via Renderer (DX9)
 float4x4 tP: PROJECTION; //projection matrix as set via Renderer (DX9)
 float4x4 tWVP: WORLDVIEWPROJECTION;

 //texture
 texture Tex <string uiname="Texture";>;
 sampler Samp = sampler_state //sampler for doing the texture-lookup
 {
 Texture = (Tex); //apply a texture to the sampler
     AddressU = Wrap;
    AddressV = Wrap;
 MipFilter = POINT; //set the sampler states LINEAR
 MinFilter = POINT;
 MagFilter = POINT;
 };
 //texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
 float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;


 //pin for pixeldiameter
 float TexWidth <string uiname="Texture Width";> = 1024;
 float TexHeight <string uiname="Texture Height";> = 1024;


 //the data structure: "vertexshader to pixelshader"
 //used as output data with the VS function
 //and as input data with the PS function
 struct vs2ps
 {
 float4 Pos : POSITION;
 float4 TexCd : TEXCOORD0;
 float2 Pixelsize : TEXCOORD1;

 };


 // -------------------------------------------------------------------------
 // VERTEXSHADERS
 // -------------------------------------------------------------------------

 vs2ps VS(float4 Pos : POSITION, float4 TexCd : TEXCOORD0, float2 Pixelsize : TEXCOORD1) {
 //inititalize all fields of output struct with 0
 vs2ps Out = (vs2ps)0;

 //transform position
 Out.Pos = mul(Pos, tWVP);

 //transform texturecoordinates
 Out.TexCd = mul(TexCd, tTex);

 //you can calculated things here aswell
 //we calculated here the "pixelsize" = 1/512
 //Out.Pixelsize.x = (1/TexWidth);
 //Out.Pixelsize.y = (1/TexHeight);

 //float2 size= (1/TexWidth,1/TexHeight);
 Out.Pixelsize = (1/TexWidth,1/TexHeight);

 return Out;
 }

 // -------------------------------------------------------------------------
 // PIXELSHADERS:
 // -------------------------------------------------------------------------

//Erode - Outputs the minimum of the center and neighbours
float4 PS_erode_fast(vs2ps In): COLOR {

  float4 tmpSample = 0.0f;
  float4 minSamp = tex2D(Samp, In.TexCd);

  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(-1,-1));
  minSamp = min(minSamp, tmpSample);
  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(0,-1));
  minSamp = min(minSamp, tmpSample);
  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(1,-1));
  minSamp = min(minSamp, tmpSample);

  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(-1,0));
  minSamp = min(minSamp, tmpSample);
  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(1,0));
  minSamp = min(minSamp, tmpSample);

  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(-1,1));
  minSamp = min(minSamp, tmpSample);
  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(0,1));
  minSamp = min(minSamp, tmpSample);
  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(1,1));
  minSamp = min(minSamp, tmpSample);

  minSamp.rgb=minSamp.b;
  return minSamp;
}


//Dilate - Outputs the minimum of the center and neighbours
float4 PS_dilate(vs2ps In): COLOR {

  float4 tmpSample = 0.0f;
  float4 maxSamp = tex2D(Samp, In.TexCd);

  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(-1,-1));
  maxSamp = max(maxSamp, tmpSample);
  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(0,-1));
  maxSamp = max(maxSamp, tmpSample);
  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(1,-1));
  maxSamp = max(maxSamp, tmpSample);

  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(-1,0));
  maxSamp = max(maxSamp, tmpSample);
  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(1,0));
  maxSamp = max(maxSamp, tmpSample);

  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(-1,1));
  maxSamp = max(maxSamp, tmpSample);
  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(0,1));
  maxSamp = max(maxSamp, tmpSample);
  tmpSample = tex2D(Samp, In.TexCd + In.Pixelsize * float2(1,1));
  maxSamp = max(maxSamp, tmpSample);

  maxSamp.rgb=maxSamp.b;
  return maxSamp;

}

// bypass
float4 PS0(vs2ps In): COLOR {
   float4 col = tex2D(Samp, float2 (In.TexCd.x, In.TexCd.y));
   return col;
}




 // -------------------------------------------------------------------------
 // TECHNIQUES:
 // -------------------------------------------------------------------------

 technique Erode {
   pass P0 {
     VertexShader = compile vs_1_1 VS();
     PixelShader = compile ps_2_0 PS_erode_fast();
   }
 }

 technique Dilate {
   pass P0 {
     VertexShader = compile vs_1_1 VS();
     PixelShader = compile ps_2_0 PS_dilate();
   }
 }



 technique Bypass {
   pass P0 {
     VertexShader = compile vs_1_1 VS();
     PixelShader = compile ps_2_0 PS0();
   }
 }
