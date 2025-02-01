// Unnamed technique, shader PathTrace
/*$(ShaderResources)*/
 
// Point d'entrée du shader
/*$(_compute:csmain)*/(uint3 DTid : SV_DispatchThreadID)
{
    float2 fragCoordJittered = float2(DTid.xy);

    float3 rayOrigin;
    float3 rayDirection;

    // Obtenez les dimensions de l'image de sortie
    uint w, h;
    output.GetDimensions(w, h);
    float2 dimensions = float2(w, h);

    // Coordonnées écran normalisées
    float2 screenPos = fragCoordJittered / dimensions * 2.0 - 1.0;
    screenPos.y = -screenPos.y;

    // Reprojetez dans l'espace vue et monde
    float4 clipSpace = float4(screenPos, 0.0f, 1.0f);
    float4 viewSpace = mul(clipSpace, /*$(Variable:InvProjMtx)*/);
    viewSpace.xyz /= viewSpace.w;

    float4 worldSpace = mul(float4(viewSpace.xyz, 1.0f), /*$(Variable:InvViewMtx)*/);

    // Initialise le rayon
    rayOrigin = /*$(Variable:CameraPos)*/;
    rayDirection = normalize(worldSpace.xyz - rayOrigin);

    // Initialisation des paramètres pour GetUprezzedVoxelCloudDensity

    float3 texCoord;
    float3 color = float3(0.2f, 0.3f, 1.0f); 
    float accumulatedDensity = 0.0f;
    float stepSize =  /*$(Variable:stepDistance)*/;
    const float influenceFactor = 0.1f;

    for (int i = 0; i < 300; ++i)
    {
        texCoord = rayOrigin;

        float3 uprezzedDensity = density.SampleLevel(samplerLinear, rayOrigin, 0);
        // Utilisation de la densité améliorée pour ajuster la couleur
        
        color = lerp(color, float3(1.0f, 1.0f, 1.0f), (uprezzedDensity.x + uprezzedDensity.y + uprezzedDensity.z) * influenceFactor);
 
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

    // Accumulation du résultat
    output[DTid.xy] = float4(color.xyz, 1.0f);
}