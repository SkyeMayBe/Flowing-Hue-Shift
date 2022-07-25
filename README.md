# Flowing-Hue-Shift

Special thanks to Stokyll for inspiration, and Maloo for a lot of help with optimization and providing the 3D texture.

# How To Use

Extract the contents of the Zip file into a folder in your Unity project. Drag and drop ShaderSphere.prefab into your Unity scene, or create a game object with a mesh renderer and apply the included material.

# Material Settings

3D Noise Texture: This is where the 3D texture goes to produce the noise effect. Any 3D texture can go here, though any other style of texture has not been tested.

Minimum / Maximum Render Range: The distance (in meters from the shader object's origin to the player's camera) where the screenspace effect will begin to fade out, from fully visible below the minimum distance, to completely invisible past the maximum distance.

Render Space: Changes how the screenspace effect is rendered. View space will create a static projection of the shader's texture over your view, while world space gives a more three-dimensional projection.

Noise Lerp Speed: Adjusts the speed of the 3D texture's back and forth blending between noise layers.

Noise Scale: Scales the 3D texture.

Hue Shift speed: Adjusts the speed of the texture's hue shift.

Saturation Multiplier: Multiplier for the saturation value on the screen.

Screen Saturation: Determines how the saturation is drawn on the screen. Normal: Grabs the saturation values on the screen; Inverted: Inverts the saturation values on the screen; Combined: Inverts the saturation values on the screen and then adds it onto the normal values.

# Saturation Lerp

Saturation Lerp Toggle: Enables a back and forth blending between two saturation values, as a multiplier of the current saturation value on the material.

Saturation Lerp Speed: Adjust the speed of the saturation lerp.
Minimum / Maximum Saturation Multiplier: Takes the current saturation value in the material and blends it between these two values, as a percentage multiplier.

# Rotation and Movement

Orbit Speed: Moves the 3D texture in an orbiting pattern around its center point, determined by the Orbit Vector.

Rotation Speed: Rotates the 3D texture around its axis, determined by the Rotation Angle. The pivot point is determined by the texture's orbit position.

Offset Speed: Moves the 3D texture in a straight line, determined by the Offset Angle
