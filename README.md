# Flowing-Hue-Shift

Special thanks to Stokyll for inspiration, and Maloo for a lot of help with optimization and providing the 3D texture.

# How To Use

Extract the contents of the Zip file into a folder in your Unity project. Drag and drop ShaderSphere.prefab into your Unity scene, or create a game object with a mesh renderer and apply the included material. A rotation constraint is included in the prefab, as rotating the shader object will also rotate the screenspace effect. If this is what you want, you can remove the constraint.

# Material Settings

3D Noise Texture: This is where the 3D texture goes to produce the noise effect. Any 3D texture can go here, though any other style of texture has not been tested.

Minimum / Maximum Render Range: The distance (in meters from the shader object's origin to the player's camera) where the screenspace effect will begin to fade out, from fully visible below the minimum distance, to completely invisible past the maximum distance. Ideally, the minimum and maximum render range should be smaller than the inner bounds of the shader object.

Render Space: Changes how the screenspace effect is rendered. Screen space will create a static projection of the shader's texture over your view, while object space gives a more three-dimensional projection.

Noise Lerp Speed: Adjusts the speed of the 3D texture's back and forth blending between two color configurations.

Noise Scale: Scales the 3D texture.

Hue Shift speed: Adjusts the speed of the hue shift.

Saturation: Adjusts the saturation value on the screen. The shader mainly only affects the existing saturation values on the screen, so greys will barely be touched unless the saturation values are negative.

Invert Saturation: Takes the saturation values on the screen and inverts them, so that colorful parts of the screen will desaturate, and more grey parts will become colurful. Usually results in blown out compression artifacts, but sometimes it can look nice.

# Saturation Lerp

Saturation Lerp Toggle: Enables a back and forth blending between two saturation values, as a multiplier of the current saturation value on the material.

Saturation Lerp Speed: Adjust the speed of the saturation lerp.

Multiplier Value 1 / 2: Takes the current saturation value in the material and blends it between these two values, as a percentage multiplier. If your Saturation is set to 2, and the multiplier values are 0.5 and 1.5, then the Saturation will blend back and forth between 1 and 3.

# Noise Rotation

Rotation Vector: Causes the 3D texture to rotate along the given axis values, separate from the shader's objects rotation. The W axis is ignored.

Rotation Speed: The speed at which the texture rotates.

Swizzle Rotation: Makes the texture's rotation less static by throwing in a lot of wobble.
