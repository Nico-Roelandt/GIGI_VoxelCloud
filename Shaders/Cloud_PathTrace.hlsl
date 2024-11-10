// Unnamed technique, shader PathTrace
/*$(ShaderResources)*/

// Dimensions du monde voxel
static const int numberOfVoxelX = 100;
static const int numberOfVoxelY = 100;
static const int numberOfVoxelZ = 100;

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

// Calcul d’un index linéaire dans un tableau 3D
int LinearIndex(int x, int y, int z) {
    return x + y * numberOfVoxelX + z * numberOfVoxelX * numberOfVoxelY;
}

// Initialisation des voxels dans le monde
void InitiateWorldCloudVoxel(uint rngState)
{
    for (int x = 0; x < numberOfVoxelX; ++x)
    {
        for (int y = 0; y < numberOfVoxelY; ++y)
        { 
            for (int z = 0; z < numberOfVoxelZ; ++z)
            {
                VoxelCloud voxel;
                voxel.pos = float3(x, y, z);
                voxel.density = RandomFloat01(rngState);
                arrayVoxelWorld[LinearIndex(x, y, z)] = voxel;
            }
        }
    }
}

// Fonction de ray marching
float3 RayMarch(float3 rayOrigin, float3 rayDirection)
{
    float3 currentPos = rayOrigin;
    float acculumatedDensity = 0.0f;
    for (int itOfVoxelCross = 0; itOfVoxelCross < /*$(Variable:maxVoxelCross)*/; ++itOfVoxelCross)
    {
        currentPos += rayDirection * /*$(Variable:stepDistance)*/;
        int ix = int(currentPos.x);
        int iy = int(currentPos.y);
        int iz = int(currentPos.z);

        if (ix >= 0 && ix < numberOfVoxelX && iy >= 0 && iy < numberOfVoxelY && iz >= 0 && iz < numberOfVoxelZ)
        {
            acculumatedDensity += arrayVoxelWorld[LinearIndex(ix, iy, iz)].density;
        }

        if (acculumatedDensity > 1.0f)
        {
            return float3(0.0f, 0.0f, 0.0f);
        }
    }
    return float3(1.0f, 1.0f, 1.0f); // Couleur par défaut si aucune intersection dense
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

    // Initialisation des voxels
    InitiateWorldCloudVoxel(rngState);

    // Calcul de la couleur via ray marching
    float3 color = RayMarch(rayOrigin, rayDirection);

    // Accumulation du résultat
    output[DTid.xy] = float4(color, 1.0f);
}
 