import numpy as np
from PIL import Image
from noise import pnoise2

# Paramètres de la texture
def generate_cloud_texture(width=512, height=512, scale=100, octaves=6, persistence=0.5, lacunarity=2.0):
    """
    Génère une texture de nuages en utilisant le bruit de Perlin.

    :param width: Largeur de l'image générée
    :param height: Hauteur de l'image générée
    :param scale: Échelle du bruit
    :param octaves: Nombre d'octaves pour le bruit de Perlin
    :param persistence: Persistance du bruit
    :param lacunarity: Lacunarité du bruit
    :return: Image de nuages sous forme de tableau NumPy
    """
    if scale <= 0:
        raise ValueError("L'échelle doit être un nombre positif.")

    # Initialiser le tableau des pixels
    cloud_data = np.zeros((height, width), dtype=np.float32)

    for y in range(height):
        for x in range(width):
            # Calculer les coordonnées normalisées
            nx = x / scale
            ny = y / scale

            # Générer le bruit de Perlin pour les coordonnées données
            noise_value = pnoise2(
                nx, ny,
                octaves=octaves,
                persistence=persistence,
                lacunarity=lacunarity,
                repeatx=width,
                repeaty=height,
                base=42
            )
            # Remapper le bruit de Perlin de [-0.5, 0.5] à [0, 1]
            cloud_data[y, x] = (noise_value + 0.5)

    # Étendre les valeurs à [0, 255] pour une image
    cloud_data = (cloud_data * 255).astype(np.uint8)

    return cloud_data

# Générer une texture de nuages
cloud_texture = generate_cloud_texture(width=512, height=512, scale=150)

# Sauvegarder en tant qu'image
image = Image.fromarray(cloud_texture, mode='L')  # 'L' pour des images en niveaux de gris
image.save("cloud_texture.png")
image.show()