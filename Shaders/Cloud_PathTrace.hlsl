// Unnamed technique, shader PathTrace
/*$(ShaderResources)*/

// Fonction de hachage pour le RNG
uint wang_hash(inout uint seed)
{
    seed = uint(seed ^ uint(61)) ^ uint(seed >> uint(16));
    seed *= uint(9);
    seed = seed ^ (seed >> 4);
    seed *= uint(0x27d4eb2d); 
    seed = seed ^ (seed >> 15);
    return seed;
}

float RandomFloat01(inout uint state)
{
    return float(wang_hash(state)) / 4294967296.0;
}


// Fonction de ray marching
float3 RayMarch(float3 rayOrigin, float3 rayDirection)
{
    float3 color = float3(0.0f, 0.0f, 0.0f);
    float t = 0.0f;
    for (int i = 0; i < 64; i++)
    {
        float3 p = rayOrigin + rayDirection * t;
        float d = length(p) - 1.0f;
        if (d < 0.001f)
        {
            color = float3(1.0f, 0.0f, 0.0f);
            break;
        }
        t += d;
    }
    return color;
}


// Point d'entrée du shader
/*$(_compute:csmain)*/(uint3 DTid : SV_DispatchThreadID)
{
    // Initialisation de l'état du générateur de nombres aléatoires
    uint rngState = uint(uint(DTid.x) * uint(1973) + uint(DTid.y) * uint(9277) + uint(/*$(Variable:iFrame)*/) * uint(26699)) | uint(1);

    // Ajout de jitter pour anti-crénelage
    float2 fragCoordJittered = float2(DTid.xy) + (float2(RandomFloat01(rngState), RandomFloat01(rngState)) - 0.5f);

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
    float3 color = RayMarch(rayOrigin, rayDirection);

    // Accumulation du résultat
    output[DTid.xy] = float4(color, 1.0f);
}
 