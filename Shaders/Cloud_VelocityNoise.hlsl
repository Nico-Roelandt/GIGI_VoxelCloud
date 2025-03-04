// Génération du champ de vélocité via curl noise à partir d'une texture de bruit 3D
/*$(ShaderResources)*/


float3 generateNoise(float3 p)
{
    p = frac(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return frac((p.xxy + p.yzz) * p.zyx);
}

/*$(_compute:csmain)*/(uint3 DTid : SV_DispatchThreadID)
{
    uint w, h, d;
    velocity.GetDimensions(w, h, d);
    float3 dimensions = float3(w, h, d);
    float epsilon = 0.01f;
    float noiseScale = /*$(Variable:noiseScale)*/;
    float time = /*$(Variable:iTime)*/;
    float iFrame = /*$(Variable:iFrame)*/;  
    float windIntensity = /*$(Variable:windIntensity)*/;


    // Apply of a fix wind by percentage
    float3 wind = (float3(0.5, 0.5, 0.5));     
    
    velocity[DTid.xyz] = float4(wind, 1.0f);
}