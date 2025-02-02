// Unnamed technique, shader PathTrace
/*$(ShaderResources)*/
 
 float GetWispyNoise(float3 samplePos, float mipLevel) {
    float lowFreqNoise = noise.SampleLevel(samplerNoise, samplePos, mipLevel).r;
    float highFreqNoise = noise.SampleLevel(samplerNoise, samplePos, mipLevel).g;
 
    return lerp(lowFreqNoise, highFreqNoise, lowFreqNoise);
}

/*$(_compute:csmain)*/(uint3 DTid : SV_DispatchThreadID)
{
    float2 fragCoordJittered = float2(DTid.xy);

    float3 rayOrigin;
    float3 rayDirection;

    uint w, h;
    output.GetDimensions(w, h);
    float2 dimensions = float2(w, h);

    float2 screenPos = fragCoordJittered / dimensions * 2.0 - 1.0;
    screenPos.y = -screenPos.y;

    float4 clipSpace = float4(screenPos, 0.0f, 1.0f);
    float4 viewSpace = mul(clipSpace, /*$(Variable:InvProjMtx)*/);
    viewSpace.xyz /= viewSpace.w;

    float4 worldSpace = mul(float4(viewSpace.xyz, 1.0f), /*$(Variable:InvViewMtx)*/);
 
    rayOrigin = /*$(Variable:CameraPos)*/;
    rayDirection = normalize(worldSpace.xyz - rayOrigin);


    float3 texCoord;
    float3 color = float3(0.2f, 0.3f, 1.0f); 
    float accumulatedDensity = 0.0f;
    float2 cCloudWindOffset = /*$(Variable:cCloudWindOffset)*/;
    float cVoxelFineDetailMipMapDistanceScale = 1.0f;
    float voxel_cloud_animation_speed = 2.0f;
    float stepSize =  /*$(Variable:stepDistance)*/;
    const float influenceFactor = 0.1f;
    float mipmapLevel = 0;
    float time = /*$(Variable:iTime)*/;
    for (int i = 0; i < 300; ++i)
    {
        texCoord = rayOrigin;

        texCoord -= float3(cCloudWindOffset.x, cCloudWindOffset.y, 0.0) * voxel_cloud_animation_speed;

        float phaseShift = sin(time) * 0.1 + cos(time); 
        float2 windOffset = cCloudWindOffset * (time * 0.05 + phaseShift);

        float3 distortion = noise.SampleLevel(samplerNoise, texCoord * 0.5, mipmapLevel).rgb * 0.1;
        float3 texCoordAnimated = texCoord + float3(windOffset, 0.0) + distortion;

        //float3 texCoordAnimated = texCoord + float3(windOffset, 0.0);

        float4 noiseValue = noise.SampleLevel(samplerNoise, texCoordAnimated, mipmapLevel);
        //float4 noiseValue = (1.0f, 1.0f, 1.0f, 1.0f);


        float3 baseDensity = density.SampleLevel(samplerLinear, texCoord, 0);

        float wispyFactor = GetWispyNoise(texCoordAnimated, mipmapLevel);
        float uprezzedDensity = saturate(baseDensity * (0.8 + wispyFactor * 1)); 
          
        //float uprezzedDensity = saturate(baseDensity * (0.8 + noiseValue.r));
        
        color = lerp(color, float3(1.0f, 1.0f, 1.0f), (uprezzedDensity) * influenceFactor);
  

 
        // if (color.x == 1.0f && color.y == 1.0f && color.z == 1.0f)
        // { 
        //      break;
        // }
        // if (texCoord.x > 100 && texCoord.y > 100 && texCoord.z > 100)
        // {
        //     break;
        // }
        
        rayOrigin += rayDirection * stepSize;
        // if (any(rayOrigin < 0.0f || rayOrigin > float3(40, 40, 40)))
        // {
        //     break;
        // }
    } 

    output[DTid.xy] = float4(color.xyz, 1.0f);
}