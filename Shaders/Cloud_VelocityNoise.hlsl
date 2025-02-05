// Génération du champ de vélocité via curl noise à partir d'une texture de bruit 3D
/*$(ShaderResources)*/


float3 generateNoise(float3 p)
{
    p = frac(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return frac((p.xxy + p.yzz) * p.zyx);
}

/*$(_compute:csmain)*/(uint3 DTid : SV_DispatchThreadID)
{
    // Récupération des dimensions du volume de sortie (la texture 'velocity')
    uint w, h, d;
    velocity.GetDimensions(w, h, d);
    float3 dimensions = float3(w, h, d);
    float epsilon = 0.01f;
    float noiseScale = /*$(Variable:noiseScale)*/;
    float time = /*$(Variable:iTime)*/;
    float iFrame = /*$(Variable:iFrame)*/;
    float windIntensity = /*$(Variable:windIntensity)*/;

    // Calcul des coordonnées normalisées dans le volume (uvw)
    float3 uvw = (float3(DTid.xyz) + 0.5) / dimensions;
    
    // Transformation dans l'espace du bruit avec échelle et animation temporelle.
    // Ici, on ajoute 'time' pour animer le bruit (vous pouvez utiliser des offsets différents sur chaque axe si souhaité)
    float3 noisePos = uvw * noiseScale + float3(time, time, time);
    
    // Génération du bruit de base
    float3 noiseValue = generateNoise(noisePos);
    
    // On remappe les valeurs de [0,1] à [-1,1] pour obtenir un vecteur orienté
    float3 windDir = noiseValue * 2.0 - 1.0;
    
    // Normalisation pour obtenir uniquement la direction, puis application de l'intensité du vent
    windDir = normalize(windDir) * windIntensity;
    
    // Écriture dans la texture de sortie : les composantes RGB contiennent la vélocité, alpha = 1
    velocity[DTid.xyz] = float4(windDir, 1.0);
}