# Flowing-Hue-Shift

Special thanks to Stokyll for inspiration, and Maloo for a lot of help with optimization and providing the 3D texture.

# Changelog
# 08-07-2022
- Added texture projection onto opaque geometry using world depth
- Added static offset properties for shader animations
- Added premade animator controllers and expression menus for VRChat Avatar 3.0
- Various bug fixes

# How To Use

Extract the contents of the Zip file into a folder in your Unity project. Drag and drop ShaderSphere.prefab into your Unity scene, or create a game object with a mesh renderer and apply the included material.

VRChat-optimized animators with expressions and parameters for property animations are included with the package. Simply drop the FXLayer, expression and parameter files into their respective slots in the avatar descriptor, or merge them into your existing expressions and animators. The animations assume that the shader object is attached to the root of the avatar.

- **IMPORTANT! Attempting to animate the parameter speed values in-game can result in epileptic levels of color flashing. Please use the static offset properties in the material if you wish to create animations, or use the pre-made animations included in the package.**

# Material Settings

3D Noise Texture: This is where the 3D texture goes to produce the noise effect. Any 3D texture can go here, though any other style of texture has not been tested.

Minimum / Maximum Render Range: The distance (in meters from the shader object's origin to the player's camera) where the screenspace effect will begin to fade out, from fully visible below the minimum distance, to completely invisible past the maximum distance.

Render Space: Changes how the screenspace effect is rendered:

- Object Space: Overlays the texture based on view direction.
              
- View Space: Creates a texture overlay across the camera view and does not change with view direction.
              
- World Projection: Uses camera depth to project the 3D texture through opaque geometry instead of overlaying the effect on the screen. A depth texture for the world is required or the effect will break. If the world does not have a depth texture, one can be created by using a shadow-casting directional light. A low-intensity, masked out light is included in the shader prefab object.

Noise Lerp Speed: Adjusts the speed of the 3D texture's back and forth blending between noise layers.

Noise Scale: Scales the 3D texture.

Hue Shift speed: Adjusts the speed of the texture's hue shift.

Hue Shift Steps: Adds additional hue shift passes over the noise texture.

Saturation Multiplier: Multiplier for the saturation value on the screen.

Screen Saturation: Determines how the saturation is drawn on the screen. Normal: Grabs the saturation values on the screen; Inverted: Inverts the saturation values on the screen; Combined: Inverts the saturation values on the screen and then adds it onto the normal values.

# Saturation Lerp

Saturation Lerp Toggle: Enables a back and forth blending between two saturation values, as a multiplier of the current saturation value on the material.

Saturation Lerp Speed: Adjust the speed of the saturation lerp.
Minimum / Maximum Saturation Multiplier: Takes the current saturation value in the material and blends it between these two values, as a percentage multiplier.

# Rotation and Movement

Orbit Speed: Moves the 3D texture in an orbiting pattern around its center point, determined by the Orbit Vector.

Rotation Speed: Rotates the 3D texture around its axis, determined by the Rotation Angle. The pivot point is determined by the texture's orbit position.

Movement Speed: Moves the 3D texture in a straight line, determined by the Movement Angle

# Static Offsets

Offsets the hue, noise lerp, and texture movements by a static value, for the purpose of shader animations.

# Known Issues
- Noise Rotation moves at very high speeds while using World Projection the longer the Unity scene is open. This is a visual issue within the Unity scene and does not happen in-game.
