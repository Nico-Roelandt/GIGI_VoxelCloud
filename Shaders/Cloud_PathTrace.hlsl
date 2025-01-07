// Unnamed technique, shader PathTrace
/*$(ShaderResources)*/

// Définition des structures et constantes nécessaires
struct CloudRenderingRaymarchInfo {
    float mDistance;
};

SamplerState Cloud3DNoiseSamplerC;

// Function: GetVoxelCloudMipLevel
float GetVoxelCloudMipLevel(CloudRenderingRaymarchInfo inRaymarchInfo, float inMipLevel)
{
    return clamp(inMipLevel, 0.0, 4.0); // Example implementation, adjust range as needed
}

// Function: ValueRemap
float ValueRemap(float value, float srcMin, float srcMax, float dstMin, float dstMax)
{
    return dstMin + (value - srcMin) * (dstMax - dstMin) / (srcMax - srcMin);
}

// Function: ValueErosion
float ValueErosion(float inDimensionalProfile, float noiseComposite)
{
    return saturate(inDimensionalProfile - noiseComposite * 0.1); // Example erosion logic
}

// Function: GetFractionFromValue 
float GetFractionFromValue(float value, float minRange, float maxRange)
{
    return saturate((value - minRange) / (maxRange - minRange));
}

//
// Function to up-rez a Dimensional Profile NVDF using noise Detail Type and Density Scale NVDF’s (BY ANUBIS)
//
float GetUprezzedVoxelCloudDensity(CloudRenderingRaymarchInfo inRaymarchInfo, float3 inSamplePosition, float inDimensionalProfile, float inType, float inDensityScale, float inMipLevel, bool inHFDetails)
{
    // Apply wind offset  
    float2 cCloudWindOffset = /*$(Variable:cCloudWindOffset)*/;
    //inSamplePosition -= float3(cCloudWindOffset.x, cCloudWindOffset.y, 0.0) * /*$(Variable:voxel_cloud_animation_speed)*/;
    
    // Sample noise
    float3 uvw = inSamplePosition;
    float3 noise = /*$(Image:voxel1.dds:BC7_Unorm_sRGB:float4:false)*/.SampleLevel(samplerLinear, uvw, 0);
     // Define wispy noise
    float wispy_noise = lerp(noise.x, noise.z, inDimensionalProfile);
     // Define billowy noise 
    float billowy_type_gradient = pow(inDimensionalProfile, 0.25);
    float billowy_noise = lerp(noise.x * 0.3, noise.y * 0.3, billowy_type_gradient);
     // Define Noise composite - blend to wispy as the density scale decreases.
    float noise_composite = lerp(wispy_noise, billowy_noise, inType);
    
     // Get the hf noise which is to be applied nearby - First, get the distance from the sample to camera and only do the work within a distance of 150 meters. 
    /*if (inHFDetails)
    {
        // Get the hf noise by folding the highest frequency billowy noise. 
        float hhf_noise = saturate(lerp(1.0 - pow(abs(abs(noise.g * 2.0 - 1.0) * 2.0 - 1.0), 4.0), pow(abs(abs(noise.a * 2.0 - 1.0) * 2.0 - 1.0), 2.0), inType));
    
        // Apply the HF nosie near camera.
        float hhf_noise_distance_range_blender = ValueRemap(inRaymarchInfo.mDistance, 50.0, 150.0, 0.9, 1.0);
        noise_composite = lerp(hhf_noise, noise_composite, hhf_noise_distance_range_blender);
    }*/
     // Composote Noises and use as a Value Erosion
    float uprezzed_density = ValueErosion(inDimensionalProfile, noise_composite);
     // Modify User density scale
    float powered_density_scale = pow(saturate(inDensityScale), 4.0);
     // Apply User Density Scale Data to Result
    uprezzed_density *= powered_density_scale; 
        
    // Sharpen result and lower Density close to camera to both add details and reduce undersampling noise
    uprezzed_density = pow(uprezzed_density, lerp(0.3, 0.6, max(EPSILON, powered_density_scale)));
    if (inHFDetails)
    {
        float distance_range_blender = GetFractionFromValue(inRaymarchInfo.mDistance, 50.0, 150.0);
        uprezzed_density = pow(uprezzed_density, lerp(0.5, 1.0, distance_range_blender)) * lerp(0.666, 1.0, distance_range_blender);
    }
    
     // Return result with softened edges
    return noise_composite;
}
 

 
// Point d'entrée du shader
/*$(_compute:csmain)*/(uint3 DTid : SV_DispatchThreadID)
{
    float2 fragCoordJittered = float2(DTid.xy);

    float3 rayOrigin;
    float3 rayDirection; 
    {
        uint w, h;
        output.GetDimensions(w, h);
        float2 dimensions = float2(w, h);

        float2 screenPos = fragCoordJittered / dimensions * 2.0 - 1.0;
        screenPos.y = -screenPos.y;

        float4 world = mul(float4(screenPos, 0.0f, 1), /*$(Variable:InvViewProjMtx)*/);
        world.xyz /= world.w;

        rayOrigin = /*$(Variable:CameraPos)*/;
        rayDirection = normalize(world.xyz - rayOrigin); 
    }

    // Initialisation des paramètres pour GetUprezzedVoxelCloudDensity

    float3 texCoord;
    float3 color = float3(0.2f, 0.3f, 1.0f);
    float accumulatedDensity = 0.0f;
    float stepSize =  /*$(Variable:stepDistance)*/;
    const float influenceFactor = 0.09f;
    float uprezzedDensity;
    for (int i = 0; i < 3000; ++i)
    {
        CloudRenderingRaymarchInfo raymarchInfo;
        raymarchInfo.mDistance = length(rayOrigin - /*$(Variable:CameraPos)*/);
        texCoord = rayOrigin;

        // Appel à GetUprezzedVoxelCloudDensity pour calculer la densité améliorée
        uprezzedDensity = uprezzedDensity + GetUprezzedVoxelCloudDensity(
            raymarchInfo,
            texCoord,
            /* Profil dimensionnel */ 0.5f,
            /* Type */ 0.8f,
            /* Échelle de densité */ 1.0f,
            /* Niveau de mip */ 2.0f,
            /* Détails HF */ true
        );
        // Utilisation de la densité améliorée pour ajuster la couleur
        color = lerp(color, float3(1.0f, 1.0f, 1.0f), uprezzedDensity * influenceFactor);

        if (color.x == 1.0f && color.y == 1.0f && color.z == 1.0f)
        {
             break;
        }
        if (texCoord.x > 100 && texCoord.y > 100 && texCoord.z > 100)
        {
            break;
        }
        
        rayOrigin += rayDirection * stepSize;
    }

    // Accumulation du résultat
    output[DTid.xy] = float4(color, 1.0f);
}

