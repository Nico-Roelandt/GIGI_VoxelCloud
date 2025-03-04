/*$(ShaderResources)*/

float RecalculateWind(float w, bool IsAbsolute)
{
    if (IsAbsolute)
    {
        return abs((w - 0.5f));
    }
    return (w - 0.5f);
}

float RecalculateWindPercentage(float w)
{
    float y = RecalculateWind(w, true);
    return y;
}
 
/*$(_compute:csmain)*/(uint3 DTid : SV_DispatchThreadID)
{ 
    uint w, h, d;
    densityCompressed.GetDimensions(w, h, d);
    float3 dimensions = float3(w, h, d);
    
    float3 uvw = (float3(DTid.xyz) + 0.5) / dimensions;
    float4 simDensity;
    float windMovement = 4.0f;
    
    if (densitySimulated[DTid.xyz].a == 1)
    {  
        // if it's not the first frame, we sample the density from the simulated texture of the previous frame
        float3 percentage = velocity.SampleLevel(samplerLinear, uvw, 0).xyz;
        
        simDensity = densitySimulated[DTid.xyz];

        uint3 newPos;
 
        // First we remove all the density that will be taken by the others voxels

        float stayPercentage = 1.0f - RecalculateWind(percentage.x, true) - RecalculateWind(percentage.y, true) - RecalculateWind(percentage.z, true);
        simDensity.r = simDensity.r * stayPercentage;

        for (int axis = 0; axis < 3; axis++)
        {
            for (int offset = -1; offset <= 1; offset++)
            {
                if (offset == 0)
                    continue;  
                
                
                int3 neighborIdx = DTid;
                if (axis == 0)
                    neighborIdx.x += offset;
                else if (axis == 1)
                    neighborIdx.y += offset;
                else // axis == 2
                    neighborIdx.z += offset;
                
                neighborIdx.x = clamp(neighborIdx.x, 0, int(w) - 1);
                neighborIdx.y = clamp(neighborIdx.y, 0, int(h) - 1);
                neighborIdx.z = clamp(neighborIdx.z, 0, int(d) - 1);
                
                float3 neighborUVW = (float3(neighborIdx) + 0.5) / dimensions;
                
                float3 wind = velocity.SampleLevel(samplerLinear, neighborUVW, 0).xyz;
                float3 windRecalculated = RecalculateWind(wind, false); 
                 
                if (axis == 0)
                {
                    if (offset == -1 && windRecalculated.x > 0)
                        simDensity.r += densitySimulated[neighborIdx].x * abs(windRecalculated.x);
                    else if (offset == 1 && windRecalculated.x < 0)
                        simDensity.r += densitySimulated[neighborIdx].x * abs(windRecalculated.x);
                }
                else if (axis == 1)
                {
                    if (offset == -1 && windRecalculated.y > 0)
                        simDensity.r += densitySimulated[neighborIdx].x * abs(windRecalculated.y);
                    else if (offset == 1 && windRecalculated.y < 0)
                        simDensity.r += densitySimulated[neighborIdx].x * abs(windRecalculated.y);
                }
                else if (axis == 2)
                {
                    if (offset == -1 && windRecalculated.z > 0)
                        simDensity.r += densitySimulated[neighborIdx].x * abs(windRecalculated.z);
                    else if (offset == 1 && windRecalculated.z < 0)
                        simDensity.r += densitySimulated[neighborIdx].x * abs(windRecalculated.z);
                }
                
                if (simDensity.r > 1.0)
                {
                    simDensity.r = 1.0;
                    break;
                }
            }
            if (simDensity.r > 1.0)
            {
                simDensity.r = 1.0;
                break;
            }
        }
    }
    else
    {
        // if it's the first frame, we sample the density from the compressed texture give by the user
        simDensity = densityCompressed.SampleLevel(samplerLinear, uvw, 0);
    }
    
     
 

    // Écriture du résultat dans la texture de sortie
    densitySimulated[DTid.xyz] = float4(simDensity.r, 0.0f, 0.0f, 1.0f);
}