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
                voxelWorld[LinearIndex(x, y, z)].pos = float3(x, y, z);
                voxelWorld[LinearIndex(x, y, z)].density = RandomFloat01(rngState);
            }
        }
    }
}

// Point d'entrée du shader
/*$(_compute:csmain)*/(uint3 DTid : SV_DispatchThreadID)
{
    // Initialisation de l'état du générateur de nombres aléatoires
    uint rngState = uint(uint(DTid.x) * uint(1973) + uint(DTid.y) * uint(9277) + uint(/*$(Variable:iFrame)*/) * uint(26699)) | uint(1);
    // Initialisation des voxels
    InitiateWorldCloudVoxel(rngState);
}
 