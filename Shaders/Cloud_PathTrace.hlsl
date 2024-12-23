// Unnamed technique, shader PathTrace
/*$(ShaderResources)*/

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

    // Calcul de la couleur via ray marching
    float3 texCoord;
    float3 color = float3(0.0f, 0.0f, 0.0f);
    float accumulatedDensity = 0.0f; // Total accumulated density
    for (int i = 0; i < 1000; i++) 
    {
        texCoord = rayOrigin * 0.5f + 0.5f; 

        float4 sampledValue = world.SampleLevel(samplerLinear, texCoord, 0);
        float density = sampledValue.r;
        accumulatedDensity += density;

        // Appliquer la densité pour influencer la couleur renvoyée
        color += sampledValue.rgb * density; // Contribution en fonction de la densité

        if (accumulatedDensity > 1.0f) {
            break; 
        } 

        // Advance the ray position
        rayOrigin += rayDirection * /*$(Variable:stepDistance)*/;
    }

    // Appliquer un ton final basé sur la densité accumulée
    color = lerp(float3(0.8f, 0.8f, 0.8f), color, min(accumulatedDensity, 1.0f));
    
    // Accumulation du résultat
    output[DTid.xy] = float4(color, 1.0f);
}
