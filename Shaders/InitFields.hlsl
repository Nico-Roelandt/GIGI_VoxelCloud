// InitFields.hlsl

/*$(ShaderResources)*/

uint hash(uint x){
    x ^= x >> 17; x *= 0xed5ad4bb;
    x ^= x >> 11; x *= 0xac4c1b51;
    x ^= x >> 15; x *= 0x31848bab;
    x ^= x >> 14; return x;
}

float rand3(uint3 p, uint seed){
    uint h = hash(p.x ^ (p.y<<10) ^ (p.z<<20) ^ seed);
    return (h & 0x00FFFFFF) / 16777215.0; // [0,1)
}

/*$(_compute:CS)*/(uint3 DTid : SV_DispatchThreadID)
{
    if (any(DTid >= gridSize)) return;

    float z = (DTid.z + 0.5) * cellSize.z;

    // Profils verticaux simples
    float theta = thetaSurface + dThetaDz * z;
    float qv    = max(0.0, qvSurface - dQvDz * z);

    // Petites perturbations aléatoires (~5%) pour amorcer la convection
    float p = rand3(DTid, randSeed) * 2.0 - 1.0;
    qv *= (1.0 + 0.05 * p);

    // Écriture des champs scalaires
    TH[DTid] = theta;
    QV[DTid] = qv;
    QC[DTid] = 0.0;
    QR[DTid] = 0.0;

    // Vent initial avec un léger cisaillement vertical
    float u = 2.0 + 6.0 * saturate(z / max(zTop, 1.0));
    float v = 0.0;
    float w = 0.0;

    Ux[DTid] = u; Uy[DTid] = v; Uz[tid] = w;
}


/*
Shader Resources:
	Texture Th (as UAV)
	Texture QV (as UAV)
	Texture QC (as UAV)
	Texture QR (as UAV)
	Texture Ux (as UAV)
	Texture Uv (as UAV)
	Texture Uz (as UAV)
	Buffer SimParams (as UAV)
*/
