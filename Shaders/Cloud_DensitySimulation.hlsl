/*$(ShaderResources)*/

/*$(_compute:csmain)*/(uint3 DTid : SV_DispatchThreadID)
{
    // Récupération des dimensions de la texture volumétrique de sortie
    uint w, h, d;
    densityCompressed.GetDimensions(w, h, d);
    float3 dimensions = float3(w, h, d);
    
    // Calcul des coordonnées normalisées (uvw) dans le volume
    float3 uvw = (float3(DTid.xyz) + 0.5) / dimensions;
    float simDensity;
    float windMovement = 4.0f;
    
    if (densitySimulated[DTid.xyz].a == 1)
    {
        // Lecture de la vélocité depuis la texture velocity (échantillonnée avec uvw)
        float3 vel = velocity.SampleLevel(samplerLinear, uvw, 0).xyz;
        
        // Calcul du déplacement à appliquer (la vélocité modulée par windMovement)
        float3 displacement = vel * windMovement;
        
        // Calcul de la nouvelle position (en coordonnées flottantes) dans la grille
        float3 newPos = float3(DTid.xyz) + displacement;
        
        // Gestion du wrapping : si newPos sort des bornes, on la ramène dans l'intervalle [0, dimensions)
        if (newPos.x < 0.0) newPos.x += dimensions.x;
        if (newPos.y < 0.0) newPos.y += dimensions.y;
        if (newPos.z < 0.0) newPos.z += dimensions.z;
        if (newPos.x >= dimensions.x) newPos.x = 0.0;
        if (newPos.y >= dimensions.y) newPos.y = 0.0;
        if (newPos.z >= dimensions.z) newPos.z = 0.0;
        
        // Conversion en coordonnées entières pour accéder à la texture simulée
        uint3 densityPos = uint3(newPos);
        
        // Récupération de la densité simulée depuis la position décalée
        simDensity = densitySimulated[densityPos].r;
    }
    else
    {
        // Sinon, on lit la densité d'origine dans la texture compressée
        simDensity = densityCompressed.SampleLevel(samplerLinear, uvw, 0);
    }
    
     
 

    // Écriture du résultat dans la texture de sortie
    densitySimulated[DTid.xyz] = float4(simDensity, 0.0, 0.0, 1.0);
}