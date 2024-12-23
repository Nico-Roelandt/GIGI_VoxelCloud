// Unnamed technique, shader PathTrace
/*$(ShaderResources)*/


// Point d'entrée du shader
/*$(_compute:csmain)*/(uint3 DTid : SV_DispatchThreadID)
{

    // Récupération de la position du voxel
    uint3 voxelPosition = DTid.xyz;
    if (voxelPosition.x != 0 || voxelPosition.y != 0 || voxelPosition.z != 0)
    {
        return;
    }
    else
    {
        for (int x = 0; x < 5; x++)
        {
            for (int y = 0; y < 50; y++) 
            {
                for (int z = 0; z < 50; z++)
                {
                    float3 position = float3(0.0f, 0.0f, 0.0f);
                    world[DTid.xyz] = float4(position, 0.0f);
                }
            }
        } 
    }
}