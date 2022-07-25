// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SkyeMayBe/Flowing Hue Shift"
{
	Properties
	{
		[HDR][Gamma][NoScaleOffset]_3DTexture("3D Texture", 3D) = "white" {}
		[Header(Rendering)]_MinimumRenderRangeMeters("Minimum Render Range (Meters)", Float) = 30
		_MaximumRenderRangeMeters("Maximum Render Range (Meters)", Float) = 35
		[IntRange][Enum(World Space,0,View Space,1)]_RenderSpace("Render Space", Range( 0 , 1)) = 0
		_NoiseLerpSpeed("Noise Lerp Speed", Range( 0 , 1)) = 1
		_NoiseScale("Noise Scale", Range( 0 , 1)) = 1
		_HueShiftSpeed("Hue Shift Speed", Range( -1 , 1)) = 0.25
		_SaturationMultiplier("Saturation Multiplier", Range( 0 , 10)) = 1
		[IntRange][Enum(Standard,0,Inverted,1,Combined,2)]_ScreenSaturation("Screen Saturation", Range( 0 , 1)) = 0
		[Toggle][ToggleUI]_SaturationLerpToggle("Saturation Lerp Toggle", Range( 0 , 1)) = 0
		_SaturationLerpSpeed("Saturation Lerp Speed", Range( 0 , 5)) = 5
		_MinSaturationMultiplier("Min Saturation Multiplier", Float) = 0
		_MaxSaturationMultiplier("Max Saturation Multiplier", Float) = 0
		[HideInInspector]_LerpOffset("Lerp Offset", Range( -1 , 1)) = 0
		[Header(Rotation and Movement)]_OrbitSpeed("Orbit Speed", Range( 0 , 1)) = 0.5
		_OrbitVector("Orbit Vector", Vector) = (1,-1,1,0)
		_RotationSpeed("Rotation Speed", Range( 0 , 1)) = 0.5695542
		_RotationAngle("Rotation Angle", Vector) = (0,0,0,0)
		_OffsetSpeed("Offset Speed", Range( 0 , 1)) = 1
		_OffsetAngle("Offset Angle", Vector) = (0,0,0,0)
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Overlay"  "Queue" = "Overlay-2" "IgnoreProjector" = "True" "ForceNoShadowCasting" = "True" "IsEmissive" = "true"  "VRCFallback"="Hidden" }
		Cull Front
		ZWrite Off
		ZTest Always
		GrabPass{ "_HueShiftGrab" }
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
		#else
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
		#endif
		#include "./MirrorCull.cginc"
		#pragma surface surf Unlit keepalpha noshadow noambient novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd 
		struct Input
		{
			float3 worldPos;
			float4 screenPos;
		};

		uniform half _LerpOffset;
		uniform half _NoiseLerpSpeed;
		uniform sampler3D _3DTexture;
		uniform half3 _RotationAngle;
		uniform half _RotationSpeed;
		uniform half3 _OrbitVector;
		uniform half _OrbitSpeed;
		uniform half _RenderSpace;
		uniform half _NoiseScale;
		uniform half3 _OffsetAngle;
		uniform half _OffsetSpeed;
		ASE_DECLARE_SCREENSPACE_TEXTURE( _HueShiftGrab )
		uniform half _HueShiftSpeed;
		uniform half _SaturationLerpToggle;
		uniform half _ScreenSaturation;
		uniform half _SaturationMultiplier;
		uniform half _MinSaturationMultiplier;
		uniform half _MaxSaturationMultiplier;
		uniform half _SaturationLerpSpeed;
		uniform half _MinimumRenderRangeMeters;
		uniform half _MaximumRenderRangeMeters;


		half3 HSVToRGB( half3 c )
		{
			half4 K = half4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
			half3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
			return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
		}


		float3 RotateAroundAxis( float3 center, float3 original, float3 u, float angle )
		{
			original -= center;
			float C = cos( angle );
			float S = sin( angle );
			float t = 1 - C;
			float m00 = t * u.x * u.x + C;
			float m01 = t * u.x * u.y - S * u.z;
			float m02 = t * u.x * u.z + S * u.y;
			float m10 = t * u.x * u.y + S * u.z;
			float m11 = t * u.y * u.y + C;
			float m12 = t * u.y * u.z - S * u.x;
			float m20 = t * u.x * u.z - S * u.y;
			float m21 = t * u.y * u.z + S * u.x;
			float m22 = t * u.z * u.z + C;
			float3x3 finalMatrix = float3x3( m00, m01, m02, m10, m11, m12, m20, m21, m22 );
			return mul( finalMatrix, original ) + center;
		}


		half3 RGBToHSV(half3 c)
		{
			half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
			half4 p = lerp( half4( c.bg, K.wz ), half4( c.gb, K.xy ), step( c.b, c.g ) );
			half4 q = lerp( half4( p.xyw, c.r ), half4( c.r, p.yzx ), step( p.x, c.r ) );
			half d = q.x - min( q.w, q.y );
			half e = 1.0e-10;
			return half3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}

		inline float4 ASE_ComputeGrabScreenPos( float4 pos )
		{
			#if UNITY_UV_STARTS_AT_TOP
			float scale = -1.0;
			#else
			float scale = 1.0;
			#endif
			float4 o = pos;
			o.y = pos.w * 0.5f;
			o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
			return o;
		}


		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			half mulTime1766 = _Time.y * _NoiseLerpSpeed;
			half LerpSpeed618 = ( _LerpOffset + mulTime1766 );
			half temp_output_2393_0 = (sin( LerpSpeed618 )*0.75 + 1.2);
			half4 appendResult2033 = (half4(( temp_output_2393_0 + 1.1 ) , ( temp_output_2393_0 + -0.4 ) , ( temp_output_2393_0 + 0.3 ) , 0.0));
			half mulTime1135 = _Time.y * _RotationSpeed;
			half RotationSpeed1761 = mulTime1135;
			half mulTime2290 = _Time.y * _OrbitSpeed;
			half OrbitSpeed2291 = mulTime2290;
			half3 appendResult2262 = (half3(sin( ( _OrbitVector.x + OrbitSpeed2291 ) ) , sin( ( _OrbitVector.y + OrbitSpeed2291 ) ) , cos( ( _OrbitVector.z + OrbitSpeed2291 ) )));
			float3 ase_worldPos = i.worldPos;
			half3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half3 worldToViewDir1365 = normalize( mul( UNITY_MATRIX_V, float4( ase_worldViewDir, 0 ) ).xyz );
			half3 ShaderPosition1749 = ( _RenderSpace == 0.0 ? ase_worldViewDir : worldToViewDir1365 );
			half3 rotatedValue926 = RotateAroundAxis( appendResult2262, ( (float3( -0.5,-0.5,-0.5 ) + (appendResult2262 - float3( -1,-1,-1 )) * (float3( 0.5,0.5,0.5 ) - float3( -0.5,-0.5,-0.5 )) / (float3( 1,1,1 ) - float3( -1,-1,-1 ))) + ShaderPosition1749 ), normalize( ( _RotationAngle + RotationSpeed1761 ) ), RotationSpeed1761 );
			half NoiseScale561 = (0.0 + (_NoiseScale - 0.0) * (1.0 - 0.0) / (1.0 - 0.0));
			half mulTime1735 = _Time.y * (0.0 + (_OffsetSpeed - 0.0) * (0.05 - 0.0) / (1.0 - 0.0));
			half OffsetSpeed1770 = mulTime1735;
			half3 temp_cast_0 = (OffsetSpeed1770).xxx;
			half3 NoiseOffset2426 = ( ( _OffsetAngle > float3( 0,0,0 ) ? ( _OffsetAngle + OffsetSpeed1770 ) : float3( 0,0,0 ) ) + ( _OffsetAngle < float3( 0,0,0 ) ? ( _OffsetAngle - temp_cast_0 ) : float3( 0,0,0 ) ) );
			half3 UVScaleOffset2077 = (rotatedValue926*NoiseScale561 + NoiseOffset2426);
			half4 tex3DNode852 = tex3D( _3DTexture, UVScaleOffset2077 );
			half3 break2399 = (tex3DNode852).rgb;
			half4 temp_cast_1 = (break2399.x).xxxx;
			half4 temp_cast_2 = (break2399.y).xxxx;
			half4 temp_cast_3 = (break2399.z).xxxx;
			half4 layeredBlendVar2026 = appendResult2033;
			half4 layeredBlend2026 = ( lerp( lerp( lerp( lerp( tex3DNode852 , temp_cast_1 , layeredBlendVar2026.x ) , temp_cast_2 , layeredBlendVar2026.y ) , temp_cast_3 , layeredBlendVar2026.z ) , float4( 0,0,0,0 ) , layeredBlendVar2026.w ) );
			half4 smoothstepResult1935 = smoothstep( float4( 0,0,0,0 ) , float4( 1,1,1,1 ) , layeredBlend2026);
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			half4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
			half4 screenColor21 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_HueShiftGrab,ase_grabScreenPosNorm.xy);
			half4 localMirrorCheck1017 = ( screenColor21 );
			{
			if (isInMirror()) discard;
			if (isVRHandCameraPreview()) discard;
			}
			half3 hsvTorgb11 = RGBToHSV( localMirrorCheck1017.rgb );
			half Hue649 = hsvTorgb11.x;
			half4 HueShiftNoise658 = ( smoothstepResult1935 + Hue649 );
			half mulTime1807 = _Time.y * _HueShiftSpeed;
			half HueShiftSpeed2092 = ( mulTime1807 + 0.0 );
			half Saturation2327 = hsvTorgb11.y;
			half temp_output_257_0 = ( Saturation2327 * _SaturationMultiplier );
			half temp_output_779_0 = ( 1.0 - temp_output_257_0 );
			half clampResult2325 = clamp( ( temp_output_779_0 + temp_output_257_0 ) , Saturation2327 , temp_output_257_0 );
			half ScreenSaturation753 = ( _ScreenSaturation == 0.0 ? temp_output_257_0 : ( _ScreenSaturation == 1.0 ? temp_output_779_0 : ( temp_output_779_0 < temp_output_257_0 ? clampResult2325 : temp_output_779_0 ) ) );
			half mulTime722 = _Time.y * _SaturationLerpSpeed;
			half lerpResult721 = lerp( _MinSaturationMultiplier , _MaxSaturationMultiplier , (0.0 + (sin( mulTime722 ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)));
			half Value2198 = hsvTorgb11.z;
			half3 hsvTorgb14 = HSVToRGB( half3(( HueShiftNoise658 + Hue649 + HueShiftSpeed2092 ).r,( _SaturationLerpToggle == 1.0 ? ( ScreenSaturation753 * lerpResult721 ) : ScreenSaturation753 ),Value2198) );
			half ScreenAlpha1525 = screenColor21.a;
			half4 appendResult1526 = (half4(hsvTorgb14.x , hsvTorgb14.y , hsvTorgb14.z , ScreenAlpha1525));
			half4 ScreenRGB2423 = localMirrorCheck1017;
			half4 transform1006 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
			half smoothstepResult425 = smoothstep( _MinimumRenderRangeMeters , _MaximumRenderRangeMeters , distance( transform1006 , half4( _WorldSpaceCameraPos , 0.0 ) ));
			half4 lerpResult428 = lerp( appendResult1526 , ScreenRGB2423 , smoothstepResult425);
			o.Emission = lerpResult428.rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
}
/*ASEBEGIN
Version=18935
1913;36;1920;917;3388.793;5111.116;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;700;-1024,-6192;Inherit;False;958.8169;865.7006;;27;2092;2093;2094;1807;72;618;746;561;752;1766;1768;1767;538;524;1770;1772;1761;1771;1135;1183;1735;1738;1736;2289;2290;2291;2429;Values;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;1736;-728.2001,-5491.999;Inherit;False;Property;_OffsetSpeed;Offset Speed;19;0;Create;True;0;0;0;False;0;False;1;0.05;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;1738;-456.2,-5587.999;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;0.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;2289;-992,-6064;Inherit;False;Property;_OrbitSpeed;Orbit Speed;15;1;[Header];Create;True;1;Rotation and Movement;0;0;False;0;False;0.5;0.05;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;1735;-280.2,-5587.999;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;2085;-3952,-5616;Inherit;False;862;352;Grab position of 3D texture based off player camera;7;1520;1364;1749;1363;1521;1365;1081;Camera Render Space;1,1,1,1;0;0
Node;AmplifyShaderEditor.WireNode;1771;-136.2,-5523.999;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;621;-3072,-5616;Inherit;False;2002.104;1160.032;;2;2084;1538;Noise Mask;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleTimeNode;2290;-704,-6064;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;447;-4848,-5248;Inherit;False;1763.47;795.948;;17;1525;2198;753;778;2340;649;1372;2341;2342;776;2327;11;21;1313;2219;2345;2423;Screen Grab Pass;1,1,1,1;0;0
Node;AmplifyShaderEditor.WireNode;1772;-296.2,-5523.999;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;2219;-4816,-5136;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;1364;-3472,-5360;Inherit;False;Property;_RenderSpace;Render Space;3;2;[IntRange];[Enum];Create;True;0;2;World Space;0;View Space;1;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;2291;-528,-6064;Inherit;False;OrbitSpeed;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;1538;-3056,-5568;Inherit;False;1965.518;531.4253;Rotate and pivot noise texture;24;2077;1034;938;926;1776;1498;1436;2255;2256;2257;2259;2260;2262;2265;2280;2281;2292;2294;2295;2306;2311;2418;2419;2427;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ScreenColorNode;21;-4576,-5136;Inherit;False;Global;_HueShiftGrab;HueShiftGrab;2;0;Create;True;0;0;0;False;0;False;Object;-1;True;False;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;1313;-4368,-5184;Inherit;False;288;134;Culls shader object from mirrors;1;1017;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;1081;-3920,-5520;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;1770;-280.2,-5491.999;Inherit;False;OffsetSpeed;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;2292;-3024,-5360;Inherit;False;2291;OrbitSpeed;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1183;-728.2001,-5411.999;Inherit;False;Property;_RotationSpeed;Rotation Speed;17;0;Create;True;0;0;0;False;0;False;0.5695542;0.05;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;2255;-3024,-5520;Inherit;False;Property;_OrbitVector;Orbit Vector;16;0;Create;True;0;0;0;False;0;False;1,-1,1;1,-1,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WireNode;1520;-3232,-5408;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;1739;-2096,-6064;Inherit;False;1025.105;432.27;;9;2060;2056;2057;2059;2062;2058;1734;1782;2426;3D Texture Offset;1,1,1,1;0;0
Node;AmplifyShaderEditor.WireNode;1521;-3488,-5424;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;1365;-3712,-5424;Inherit;False;World;View;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;1734;-2048,-6000;Inherit;False;Property;_OffsetAngle;Offset Angle;20;0;Create;True;0;0;0;False;0;False;0,0,0;1,1,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CustomExpressionNode;1017;-4288,-5136;Inherit;False;if (isInMirror()) discard@$if (isVRHandCameraPreview()) discard@$;7;Create;0;MirrorCheck;False;False;0;;False;1;0;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleTimeNode;1135;-456.2,-5411.999;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;2260;-2816,-5424;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;2257;-2816,-5520;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1782;-2064,-5856;Inherit;False;1770;OffsetSpeed;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;2256;-2816,-5328;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;524;-1000.2,-5491.999;Inherit;False;Property;_NoiseLerpSpeed;Noise Lerp Speed;4;0;Create;True;0;0;0;False;0;False;1;0.125;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;2259;-2624,-5520;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2062;-1824,-5808;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;1363;-3456,-5568;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1761;-280.2,-5411.999;Inherit;False;RotationSpeed;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;2059;-1792,-5744;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RGBToHSVNode;11;-3984,-5200;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;2058;-1792,-5904;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SinOpNode;2281;-2624,-5424;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;2280;-2624,-5328;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1767;-776.2001,-5523.999;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;2345;-4560,-4880;Inherit;False;1398.733;399.8701;Takes saturation from grab pass and inverts and/or combines the values;18;2321;2332;2325;2324;2343;779;257;2328;258;2335;2410;2411;2412;2413;2414;2420;2338;2339;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;1776;-2688,-5120;Inherit;False;1761;RotationSpeed;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;2262;-2464,-5456;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;2056;-1632,-6000;Inherit;False;2;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;2057;-1632,-5824;Inherit;False;4;4;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;538;-984.2001,-5955.999;Inherit;False;Property;_NoiseScale;Noise Scale;5;0;Create;True;0;0;0;False;0;False;1;0.2;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1749;-3312,-5568;Inherit;False;ShaderPosition;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;2327;-3712,-5120;Inherit;False;Saturation;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;1436;-2672,-5264;Inherit;False;Property;_RotationAngle;Rotation Angle;18;0;Create;True;0;0;0;False;0;False;0,0,0;-1,1,-1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;258;-4528,-4688;Inherit;False;Property;_SaturationMultiplier;Saturation Multiplier;7;0;Create;True;0;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;2429;-528,-5952;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;2306;-2272,-5456;Inherit;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;-1,-1,-1;False;2;FLOAT3;1,1,1;False;3;FLOAT3;-0.5,-0.5,-0.5;False;4;FLOAT3;0.5,0.5,0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;2060;-1392,-5888;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;2419;-2336,-5216;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;2328;-4432,-4608;Inherit;False;2327;Saturation;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1768;-925.2001,-5521.999;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1498;-2464,-5216;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0.001;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;2265;-2272,-5280;Inherit;False;1749;ShaderPosition;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;2418;-1984,-5200;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;752;-984.2001,-5667.999;Inherit;False;Property;_LerpOffset;Lerp Offset;13;1;[HideInInspector];Create;True;0;0;0;False;0;False;0;1;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;561;-352,-5952;Inherit;False;NoiseScale;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2311;-2016,-5216;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;2294;-2032,-5136;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;1766;-904.2001,-5587.999;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;2426;-1264,-5888;Inherit;False;NoiseOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;2295;-2064,-5456;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;257;-4256,-4688;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;779;-4096,-4784;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;746;-712.2001,-5667.999;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;938;-1792,-5312;Inherit;False;561;NoiseScale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;926;-1904,-5456;Inherit;False;True;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;2427;-1792,-5232;Inherit;False;2426;NoiseOffset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;618;-584.2001,-5667.999;Inherit;False;LerpSpeed;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;1034;-1552,-5376;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;2;FLOAT3;33,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;2332;-4096,-4720;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2343;-4112,-4624;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;2084;-3056,-4992;Inherit;False;1970.4;504.7998;Smooth blend between RGB layers;17;2026;2066;1297;2033;968;658;1296;1935;2393;2397;2399;852;2082;2407;2432;2430;2431;3D Texture;1,1,1,1;0;0
Node;AmplifyShaderEditor.WireNode;2414;-3824,-4576;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;2324;-3952,-4688;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2411;-3856,-4720;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2410;-3664,-4720;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2413;-3648,-4752;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;776;-4048,-5056;Inherit;False;Property;_ScreenSaturation;Screen Saturation;8;2;[IntRange];[Enum];Create;True;0;3;Standard;0;Inverted;1;Combined;2;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;968;-2976,-4848;Inherit;False;618;LerpSpeed;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;2077;-1328,-5376;Inherit;False;UVScaleOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode;2325;-3776,-4688;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2412;-3840,-4592;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;2082;-2960,-4688;Inherit;False;2077;UVScaleOffset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;2321;-3616,-4688;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;2397;-2800,-4848;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2420;-3776,-4816;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;2335;-3424,-4816;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;1;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;852;-2768,-4688;Inherit;True;Property;_3DTexture;3D Texture;0;3;[HDR];[Gamma];[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;a22ab5845c8ef7e48be8dc67aeab4eda;a22ab5845c8ef7e48be8dc67aeab4eda;True;0;False;white;LockedToTexture3D;False;Object;-1;Auto;Texture3D;8;0;SAMPLER3D;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;1317;-1024,-4928;Inherit;False;1014.639;447.166;Lerp Saturation between two values;16;1314;758;1322;755;1323;721;1536;1528;730;1535;725;754;722;1316;1315;723;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;2393;-2672,-4848;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.75;False;2;FLOAT;1.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;2431;-2288,-4752;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.3;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2342;-3728,-4992;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;723;-1008,-4800;Inherit;False;Property;_SaturationLerpSpeed;Saturation Lerp Speed;10;0;Create;True;0;0;0;False;0;False;5;0.5;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2341;-3280,-4960;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;2432;-2288,-4944;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;2066;-2288,-4608;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;2430;-2288,-4848;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-0.4;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2338;-4128,-4832;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2407;-2016,-4656;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;1315;-784,-4704;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;2033;-2096,-4864;Inherit;False;COLOR;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;2340;-3440,-5008;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;2399;-2080,-4608;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.WireNode;2339;-3520,-4848;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1372;-3520,-4992;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;72;-984.2001,-5859.999;Inherit;False;Property;_HueShiftSpeed;Hue Shift Speed;6;0;Create;True;0;0;0;False;0;False;0.25;0.08;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1316;-992,-4704;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LayeredBlendNode;2026;-1920,-4752;Inherit;True;6;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Compare;778;-3424,-5184;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;649;-3712,-5184;Inherit;False;Hue;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;1935;-1609,-4755;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,1;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;2094;-984.2001,-5779.999;Inherit;False;Constant;_HueShiftOffset;Hue Shift Offset;21;1;[HideInInspector];Create;True;0;0;0;False;0;False;0;0;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1297;-1616,-4640;Inherit;False;649;Hue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;753;-3280,-5184;Inherit;False;ScreenSaturation;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;722;-976,-4656;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;1807;-712.2001,-5859.999;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;725;-816,-4656;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1296;-1408,-4752;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;2093;-536.2001,-5779.999;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;754;-704,-4880;Inherit;False;753;ScreenSaturation;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1535;-736,-4800;Inherit;False;Property;_MinSaturationMultiplier;Min Saturation Multiplier;11;0;Create;True;0;0;0;False;0;False;0;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1536;-736,-4736;Inherit;False;Property;_MaxSaturationMultiplier;Max Saturation Multiplier;12;0;Create;True;0;0;0;False;0;False;0;1.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1528;-480,-4752;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;658;-1280,-4752;Inherit;False;HueShiftNoise;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;454;-1024,-5312;Inherit;False;655.7675;366.9827;Blend additional hue shift on top of 3D texture;4;1284;1224;660;2095;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;2092;-408.2,-5779.999;Inherit;False;HueShiftSpeed;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;730;-672,-4656;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;2095;-1008,-5104;Inherit;False;2092;HueShiftSpeed;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1323;-336,-4736;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;660;-1008,-5264;Inherit;False;658;HueShiftNoise;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;721;-464,-4704;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;5;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1224;-992,-5184;Inherit;False;649;Hue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;758;-464,-4880;Inherit;False;Property;_SaturationLerpToggle;Saturation Lerp Toggle;9;2;[Toggle];[ToggleUI];Create;True;1;Saturation Lerp;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;755;-304,-4704;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;448;-1024,-4464;Inherit;False;1216.051;384.0244;Smooth distance fade between camera and shader object in world space;7;425;424;421;1006;1360;1361;2424;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1284;-608,-5232;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;1322;-464,-4784;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;2198;-3712,-5056;Inherit;False;Value;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;2176;112.1316,-5129.765;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1525;-4320,-5040;Inherit;False;ScreenAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;1314;-176,-4880;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;2200;0,-4800;Inherit;False;2198;Value;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;421;-976,-4240;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;1006;-928,-4416;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;2423;-4048,-4976;Inherit;False;ScreenRGB;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DistanceOpNode;424;-688,-4320;Inherit;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;14;176,-4896;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;1527;224,-4624;Inherit;False;1525;ScreenAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1360;-464,-4256;Inherit;False;Property;_MinimumRenderRangeMeters;Minimum Render Range (Meters);1;1;[Header];Create;True;1;Rendering;0;0;False;0;False;30;30;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1361;-464,-4176;Inherit;False;Property;_MaximumRenderRangeMeters;Maximum Render Range (Meters);2;0;Create;True;0;0;0;False;0;False;35;35;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;1526;448,-4896;Inherit;False;COLOR;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;2424;-96,-4400;Inherit;False;2423;ScreenRGB;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;425;-96,-4320;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;720;768,-4512;Inherit;False;514.6558;484.1365;;1;441;Made by SkyeMayBe, with help from Stokyll and Mal'oo;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;428;608,-4416;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;441;928,-4464;Half;False;True;-1;2;;0;0;Unlit;SkyeMayBe/Flowing Hue Shift;False;False;False;False;True;True;True;True;True;True;True;True;False;False;True;True;False;False;False;False;False;Front;2;False;-1;7;False;-1;False;0;False;-1;0;False;-1;False;4;Custom;0.5;True;False;-2;True;Overlay;;Overlay;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;0;5;False;-1;10;False;-1;0;2;False;1212;0;False;1213;0;False;-1;1;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;14;-1;-1;-1;1;VRCFallback=Hidden;False;0;0;False;-1;-1;0;False;-1;1;Include;./MirrorCull.cginc;False;71a928ffb0de3b442ab7e52a33f42d54;Custom;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;1738;0;1736;0
WireConnection;1735;0;1738;0
WireConnection;1771;0;1735;0
WireConnection;2290;0;2289;0
WireConnection;1772;0;1771;0
WireConnection;2291;0;2290;0
WireConnection;21;0;2219;0
WireConnection;1770;0;1772;0
WireConnection;1520;0;1364;0
WireConnection;1521;0;1520;0
WireConnection;1365;0;1081;0
WireConnection;1017;0;21;0
WireConnection;1135;0;1183;0
WireConnection;2260;0;2255;2
WireConnection;2260;1;2292;0
WireConnection;2257;0;2255;1
WireConnection;2257;1;2292;0
WireConnection;2256;0;2255;3
WireConnection;2256;1;2292;0
WireConnection;2259;0;2257;0
WireConnection;2062;0;1734;0
WireConnection;1363;0;1521;0
WireConnection;1363;2;1081;0
WireConnection;1363;3;1365;0
WireConnection;1761;0;1135;0
WireConnection;2059;0;1734;0
WireConnection;2059;1;1782;0
WireConnection;11;0;1017;0
WireConnection;2058;0;1734;0
WireConnection;2058;1;1782;0
WireConnection;2281;0;2260;0
WireConnection;2280;0;2256;0
WireConnection;1767;0;524;0
WireConnection;2262;0;2259;0
WireConnection;2262;1;2281;0
WireConnection;2262;2;2280;0
WireConnection;2056;0;1734;0
WireConnection;2056;2;2058;0
WireConnection;2057;0;2062;0
WireConnection;2057;2;2059;0
WireConnection;1749;0;1363;0
WireConnection;2327;0;11;2
WireConnection;2429;0;538;0
WireConnection;2306;0;2262;0
WireConnection;2060;0;2056;0
WireConnection;2060;1;2057;0
WireConnection;2419;0;2262;0
WireConnection;1768;0;1767;0
WireConnection;1498;0;1436;0
WireConnection;1498;1;1776;0
WireConnection;2418;0;2419;0
WireConnection;561;0;2429;0
WireConnection;2311;0;1498;0
WireConnection;2294;0;1776;0
WireConnection;1766;0;1768;0
WireConnection;2426;0;2060;0
WireConnection;2295;0;2306;0
WireConnection;2295;1;2265;0
WireConnection;257;0;2328;0
WireConnection;257;1;258;0
WireConnection;779;0;257;0
WireConnection;746;0;752;0
WireConnection;746;1;1766;0
WireConnection;926;0;2311;0
WireConnection;926;1;2294;0
WireConnection;926;2;2418;0
WireConnection;926;3;2295;0
WireConnection;618;0;746;0
WireConnection;1034;0;926;0
WireConnection;1034;1;938;0
WireConnection;1034;2;2427;0
WireConnection;2332;0;257;0
WireConnection;2343;0;257;0
WireConnection;2414;0;2328;0
WireConnection;2324;0;779;0
WireConnection;2324;1;257;0
WireConnection;2411;0;779;0
WireConnection;2410;0;2332;0
WireConnection;2413;0;779;0
WireConnection;2077;0;1034;0
WireConnection;2325;0;2324;0
WireConnection;2325;1;2414;0
WireConnection;2325;2;2343;0
WireConnection;2412;0;2411;0
WireConnection;2321;0;2413;0
WireConnection;2321;1;2410;0
WireConnection;2321;2;2325;0
WireConnection;2321;3;2412;0
WireConnection;2397;0;968;0
WireConnection;2420;0;776;0
WireConnection;2335;0;2420;0
WireConnection;2335;2;779;0
WireConnection;2335;3;2321;0
WireConnection;852;1;2082;0
WireConnection;2393;0;2397;0
WireConnection;2431;0;2393;0
WireConnection;2342;0;776;0
WireConnection;2341;0;2335;0
WireConnection;2432;0;2393;0
WireConnection;2066;0;852;0
WireConnection;2430;0;2393;0
WireConnection;2338;0;257;0
WireConnection;2407;0;852;0
WireConnection;1315;0;723;0
WireConnection;2033;0;2432;0
WireConnection;2033;1;2430;0
WireConnection;2033;2;2431;0
WireConnection;2340;0;2341;0
WireConnection;2399;0;2066;0
WireConnection;2339;0;2338;0
WireConnection;1372;0;2342;0
WireConnection;1316;0;1315;0
WireConnection;2026;0;2033;0
WireConnection;2026;1;2407;0
WireConnection;2026;2;2399;0
WireConnection;2026;3;2399;1
WireConnection;2026;4;2399;2
WireConnection;778;0;1372;0
WireConnection;778;2;2339;0
WireConnection;778;3;2340;0
WireConnection;649;0;11;1
WireConnection;1935;0;2026;0
WireConnection;753;0;778;0
WireConnection;722;0;1316;0
WireConnection;1807;0;72;0
WireConnection;725;0;722;0
WireConnection;1296;0;1935;0
WireConnection;1296;1;1297;0
WireConnection;2093;0;1807;0
WireConnection;2093;1;2094;0
WireConnection;1528;0;754;0
WireConnection;658;0;1296;0
WireConnection;2092;0;2093;0
WireConnection;730;0;725;0
WireConnection;1323;0;1528;0
WireConnection;721;0;1535;0
WireConnection;721;1;1536;0
WireConnection;721;2;730;0
WireConnection;755;0;1323;0
WireConnection;755;1;721;0
WireConnection;1284;0;660;0
WireConnection;1284;1;1224;0
WireConnection;1284;2;2095;0
WireConnection;1322;0;754;0
WireConnection;2198;0;11;3
WireConnection;2176;0;1284;0
WireConnection;1525;0;21;4
WireConnection;1314;0;758;0
WireConnection;1314;2;755;0
WireConnection;1314;3;1322;0
WireConnection;2423;0;1017;0
WireConnection;424;0;1006;0
WireConnection;424;1;421;0
WireConnection;14;0;2176;0
WireConnection;14;1;1314;0
WireConnection;14;2;2200;0
WireConnection;1526;0;14;1
WireConnection;1526;1;14;2
WireConnection;1526;2;14;3
WireConnection;1526;3;1527;0
WireConnection;425;0;424;0
WireConnection;425;1;1360;0
WireConnection;425;2;1361;0
WireConnection;428;0;1526;0
WireConnection;428;1;2424;0
WireConnection;428;2;425;0
WireConnection;441;2;428;0
ASEEND*/
//CHKSM=087E19AE1598992B16E1350841D2947926494E29