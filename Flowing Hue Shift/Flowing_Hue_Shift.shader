// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Blippy/Flowing Hue Shift"
{
	Properties
	{
		[NoScaleOffset]_3DNoiseTexture("3D Noise Texture", 3D) = "white" {}
		_MinimumRenderRange("Minimum Render Range", Float) = 30
		_MaximumRenderRange("Maximum Render Range", Float) = 35
		[IntRange][Enum(Object Space,0,Screen Space,1)]_RenderSpace("Render Space", Range( 0 , 1)) = 0
		_NoiseLerpSpeed("Noise Lerp Speed", Range( 0 , 2)) = 1
		_NoiseScale("Noise Scale", Range( 0 , 1)) = 1
		_HueShiftSpeed("Hue Shift Speed", Range( 0 , 1)) = 1
		_Saturation("Saturation", Range( 0 , 10)) = 1
		[ToggleUI]_InvertSaturation("Invert Saturation", Range( 0 , 1)) = 0
		[Header(Saturation Lerp)][Toggle][ToggleUI]_SaturationLerpToggle("Saturation Lerp Toggle", Range( 0 , 1)) = 0
		_SaturationLerpSpeed("Saturation Lerp Speed", Range( 0 , 5)) = 1
		_MultiplierValue1("Multiplier Value 1", Float) = 0
		_MultiplierValue2("Multiplier Value 2", Float) = 0
		[Header(Noise Rotation)]_RotationVector("Rotation Vector", Vector) = (0,0,0,0)
		_RotationSpeed("Rotation Speed", Range( 0 , 2)) = 0.025
		[Toggle][ToggleUI]_SwizzleRotation("Swizzle Rotation", Range( 0 , 1)) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Overlay"  "Queue" = "Overlay-2" "IgnoreProjector" = "True" "ForceNoShadowCasting" = "True" "IsEmissive" = "true"  }
		Cull Front
		ZWrite Off
		ZTest Always
		GrabPass{ "_HueShiftGrab" }
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 5.0
		#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
		#else
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
		#endif
		#include "./MirrorCull.cginc"
		#pragma surface surf Unlit keepalpha noshadow exclude_path:deferred noambient novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd vertex:vertexDataFunc 
		struct Input
		{
			float3 worldPos;
			float4 screenPos;
		};

		uniform half _MaximumRenderRange;
		uniform sampler3D _3DNoiseTexture;
		uniform half _SwizzleRotation;
		uniform half3 _RotationVector;
		uniform half _RotationSpeed;
		uniform half _RenderSpace;
		uniform half _NoiseScale;
		uniform half _NoiseLerpSpeed;
		ASE_DECLARE_SCREENSPACE_TEXTURE( _HueShiftGrab )
		uniform half _HueShiftSpeed;
		uniform half _SaturationLerpToggle;
		uniform half _InvertSaturation;
		uniform half _Saturation;
		uniform half _MultiplierValue1;
		uniform half _MultiplierValue2;
		uniform half _SaturationLerpSpeed;
		uniform half _MinimumRenderRange;


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


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			half4 transform1006 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
			half temp_output_424_0 = distance( transform1006 , half4( _WorldSpaceCameraPos , 0.0 ) );
			half3 _Vector2 = half3(0,0,0);
			half3 ifLocalVar986 = 0;
			if( temp_output_424_0 <= _MaximumRenderRange )
				ifLocalVar986 = _Vector2;
			else
				ifLocalVar986 = half3(9999,9999,9999);
			v.vertex.xyz += ifLocalVar986;
			v.vertex.w = 1;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			half mulTime1135 = _Time.y * _RotationSpeed;
			float3 ase_worldPos = i.worldPos;
			half3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half3 worldToObjDir1358 = normalize( mul( unity_WorldToObject, float4( ase_worldViewDir, 0 ) ).xyz );
			half3 worldToViewDir1365 = normalize( mul( UNITY_MATRIX_V, float4( ase_worldViewDir, 0 ) ).xyz );
			half3 temp_output_1363_0 = ( _RenderSpace == 0.0 ? worldToObjDir1358 : worldToViewDir1365 );
			half3 rotatedValue1460 = RotateAroundAxis( float3( 0,0,0 ), temp_output_1363_0, normalize( ( _RotationVector + float3( 0.001,0.001,0.001 ) ) ), mulTime1135 );
			half3 temp_output_1501_0 = ( ( half3(1,0,0) + half3(0,1,0) ) + _RotationVector );
			half3 lerpResult1433 = lerp( temp_output_1501_0 , ( 1.0 - temp_output_1501_0 ) , cos( sin( mulTime1135 ) ));
			half3 rotatedValue926 = RotateAroundAxis( lerpResult1433, temp_output_1363_0, normalize( lerpResult1433 ), mulTime1135 );
			half NoiseScale561 = (0.0 + (_NoiseScale - 0.0) * (0.5 - 0.0) / (1.0 - 0.0));
			half4 tex3DNode852 = tex3D( _3DNoiseTexture, (( _SwizzleRotation == 0.0 ? rotatedValue1460 : rotatedValue926 )*NoiseScale561 + 0.0) );
			half LerpSpeed618 = ( _Time.y * _NoiseLerpSpeed );
			half4 lerpResult966 = lerp( tex3DNode852 , (tex3DNode852).gbra , (-2.0 + (sin( LerpSpeed618 ) - -1.0) * (2.0 - -2.0) / (1.0 - -1.0)));
			half4 smoothstepResult1329 = smoothstep( float4( 0,0,0,1 ) , float4( 1,1,1,1 ) , lerpResult966);
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			half4 screenColor21 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_HueShiftGrab,ase_grabScreenPos.xy/ase_grabScreenPos.w);
			half4 localMirrorCheck1017 = ( screenColor21 );
			{
			UNITY_BRANCH
			if (IsInMirror()) discard;
			}
			half3 hsvTorgb11 = RGBToHSV( localMirrorCheck1017.rgb );
			half ScreenHue649 = hsvTorgb11.x;
			half4 HueShiftNoise658 = ( smoothstepResult1329 + ScreenHue649 );
			half temp_output_257_0 = ( hsvTorgb11.y * _Saturation );
			half Saturation753 = ( _InvertSaturation == 1.0 ? ( 1.0 - temp_output_257_0 ) : temp_output_257_0 );
			half mulTime722 = _Time.y * _SaturationLerpSpeed;
			half lerpResult721 = lerp( _MultiplierValue1 , _MultiplierValue2 , (0.0 + (sin( mulTime722 ) - -1.0) * (1.0 - 0.0) / (1.0 - -1.0)));
			half3 hsvTorgb14 = HSVToRGB( half3(( HueShiftNoise658 + ScreenHue649 + ( _Time.y * _HueShiftSpeed ) ).x,( _SaturationLerpToggle == 1.0 ? ( Saturation753 * lerpResult721 ) : Saturation753 ),hsvTorgb11.z) );
			half ScreenAlpha1525 = screenColor21.a;
			half4 appendResult1526 = (half4(hsvTorgb14.x , hsvTorgb14.y , hsvTorgb14.z , ScreenAlpha1525));
			half4 transform1006 = mul(unity_ObjectToWorld,float4( 0,0,0,1 ));
			half temp_output_424_0 = distance( transform1006 , half4( _WorldSpaceCameraPos , 0.0 ) );
			half smoothstepResult425 = smoothstep( _MinimumRenderRange , _MaximumRenderRange , temp_output_424_0);
			half4 lerpResult428 = lerp( appendResult1526 , localMirrorCheck1017 , smoothstepResult425);
			o.Emission = lerpResult428.rgb;
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18900
0;0;1920;1028;3724.259;5540.634;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;621;-3072,-5600;Inherit;False;2012.751;1013.398;;9;1363;1358;1521;1365;1081;1520;1364;1538;1539;Noise Mask;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;1538;-2960,-5552;Inherit;False;1684.119;595.8174;Rotate and pivot noise texture;28;1481;1522;1034;938;1507;926;1530;1460;1433;1513;1510;1479;1478;1498;1448;1476;1432;1185;1477;1184;1501;1437;1519;1135;1514;1436;1183;1515;;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector3Node;1515;-2912,-5328;Inherit;False;Constant;_Vector1;Vector 1;19;0;Create;True;0;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;1436;-2912,-5184;Inherit;False;Property;_RotationVector;Rotation Vector;15;1;[Header];Create;True;1;Noise Rotation;0;0;False;0;False;0,0,0;-1,-1,2;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;1183;-2912,-5040;Inherit;False;Property;_RotationSpeed;Rotation Speed;16;0;Create;True;0;0;0;False;0;False;0.025;0.04;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1364;-2496,-4704;Inherit;False;Property;_RenderSpace;Render Space;3;2;[IntRange];[Enum];Create;True;0;2;Object Space;0;Screen Space;1;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;1514;-2912,-5472;Inherit;False;Constant;_Vector0;Vector 0;19;0;Create;True;0;0;0;False;0;False;1,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WireNode;1519;-2606,-5250;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;1081;-2912,-4848;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;1437;-2720,-5392;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;1520;-2260,-4762;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;1135;-2640,-5040;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;1358;-2720,-4912;Inherit;False;World;Object;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformDirectionNode;1365;-2720,-4768;Inherit;False;World;View;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WireNode;1521;-2467,-4760;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;1184;-2448,-5040;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;700;-1040,-5728;Inherit;False;682.917;707.2006;;11;567;561;1055;538;618;946;944;524;945;477;943;Values;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1501;-2592,-5392;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CosOpNode;1185;-2336,-5040;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;1432;-2432,-5328;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Compare;1363;-2464,-4912;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;1476;-2477.1,-5109.099;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1477;-2464,-5080;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;538;-1024,-5216;Inherit;False;Property;_NoiseScale;Noise Scale;6;0;Create;True;0;0;0;False;0;False;1;0.075;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1478;-2211.9,-5163.3;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;1055;-752,-5216;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1498;-2432,-5248;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0.001,0.001,0.001;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;1448;-2080,-5488;Inherit;False;Property;_SwizzleRotation;Swizzle Rotation;17;2;[Toggle];[ToggleUI];Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1479;-2209,-5111;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1513;-2208,-5008;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;1433;-2272,-5392;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;1510;-2190,-5001;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;561;-576,-5216;Inherit;False;NoiseScale;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;1460;-2080,-5248;Inherit;False;True;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RotateAboutAxisNode;926;-2080,-5408;Inherit;False;True;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;1530;-1760,-5392;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;1507;-1728,-5376;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;938;-1728,-5232;Inherit;False;561;NoiseScale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;944;-1024,-5440;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;1034;-1536,-5376;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;524;-1024,-5296;Inherit;False;Property;_NoiseLerpSpeed;Noise Lerp Speed;5;0;Create;True;0;0;0;False;0;False;1;0.4;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;447;-2560,-4576;Inherit;False;1501.845;382.5596;Grabs the image on the screen;12;1525;753;778;1372;779;257;776;649;258;11;1313;21;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;1313;-2352,-4512;Inherit;False;288;134;Culls shader object from mirrors;1;1017;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ScreenColorNode;21;-2544,-4464;Inherit;False;Global;_HueShiftGrab;HueShiftGrab;2;0;Create;True;0;0;0;False;0;False;Object;-1;True;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;1522;-1376,-5088;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;946;-752,-5344;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1481;-2113,-5010;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;1539;-2192,-4944;Inherit;False;1109.6;331.6001;Take 3D Texture and lerp swizzled color channels;16;1320;1373;1531;852;658;1379;1331;1296;1534;1329;966;1532;1297;1328;980;968;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CustomExpressionNode;1017;-2272,-4464;Inherit;False;UNITY_BRANCH$if (IsInMirror()) discard@;7;False;0;MirrorCheck;False;False;0;1;0;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;618;-608,-5344;Inherit;False;LerpSpeed;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;11;-1968,-4528;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;852;-2144,-4896;Inherit;True;Property;_3DNoiseTexture;3D Noise Texture;0;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;852;3620ad8b22b29ea4a9471ffa9b087878;3620ad8b22b29ea4a9471ffa9b087878;True;0;False;white;LockedToTexture3D;False;Object;-1;Auto;Texture3D;8;0;SAMPLER3D;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;968;-2160,-4704;Inherit;False;618;LerpSpeed;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1373;-1856,-4896;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;649;-1712,-4512;Inherit;False;ScreenHue;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;980;-1968,-4704;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;1328;-1792,-4784;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;-2;False;4;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;1320;-1792,-4864;Inherit;False;FLOAT4;1;2;0;3;1;0;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;1297;-1600,-4704;Inherit;False;649;ScreenHue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1531;-1648,-4896;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;1317;-1040,-4624;Inherit;False;1015.639;432.166;Lerp Saturation between two values;15;1315;1314;758;755;1322;721;730;725;754;722;1316;723;1528;1535;1536;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;723;-1024,-4496;Inherit;False;Property;_SaturationLerpSpeed;Saturation Lerp Speed;11;0;Create;True;0;0;0;False;0;False;1;0;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1532;-1408,-4720;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;966;-1600,-4896;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;258;-2016,-4384;Inherit;False;Property;_Saturation;Saturation;8;0;Create;True;0;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;1329;-1440,-4896;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,1;False;2;FLOAT4;1,1,1,1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;257;-1712,-4432;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1315;-789,-4404;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;776;-2016,-4304;Inherit;False;Property;_InvertSaturation;Invert Saturation;9;1;[ToggleUI];Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1534;-1290,-4744;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1296;-1248,-4896;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WireNode;1316;-1008,-4400;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;779;-1568,-4320;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1372;-1574.4,-4364.294;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1331;-1152,-4752;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleTimeNode;722;-992,-4352;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;778;-1424,-4512;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1379;-1344,-4752;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;753;-1264,-4512;Inherit;False;Saturation;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;725;-832,-4352;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;454;-1040,-5008;Inherit;False;798.7675;367.9827;Blend additional hue shift with mask;6;1284;660;1224;71;70;72;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;1536;-752,-4432;Inherit;False;Property;_MultiplierValue2;Multiplier Value 2;13;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;70;-1024,-4864;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TFHCRemapNode;730;-704,-4352;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1535;-752,-4496;Inherit;False;Property;_MultiplierValue1;Multiplier Value 1;12;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;658;-1312,-4704;Inherit;False;HueShiftNoise;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;754;-736,-4576;Inherit;False;753;Saturation;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;448;-640,-4096;Inherit;False;1216.051;384.0244;Smooth distance fade between player camera and shader object in world space;7;428;425;424;421;1006;1360;1361;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;72;-1024,-4720;Inherit;False;Property;_HueShiftSpeed;Hue Shift Speed;7;0;Create;True;0;0;0;False;0;False;1;0.085;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ObjectToWorldTransfNode;1006;-528,-4048;Inherit;False;1;0;FLOAT4;0,0,0,1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceCameraPos;421;-592,-3872;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;721;-480,-4400;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;5;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1224;-800,-4864;Inherit;False;649;ScreenHue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;71;-752,-4784;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1528;-435,-4467;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;660;-1024,-4960;Inherit;False;658;HueShiftNoise;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WireNode;713;-1632,-4192;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;424;-304,-4016;Inherit;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1284;-512,-4944;Inherit;False;3;3;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WireNode;1322;-489,-4493;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;755;-320,-4448;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;758;-480,-4576;Inherit;False;Property;_SaturationLerpToggle;Saturation Lerp Toggle;10;3;[Header];[Toggle];[ToggleUI];Create;True;1;Saturation Lerp;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;401;-54.5,-4191.201;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1304;-34.81644,-4810.623;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;988;2,-3696;Inherit;False;575;369;Move shader object away when outside max render range;4;986;985;1042;984;;1,1,1,1;0;0
Node;AmplifyShaderEditor.Compare;1314;-176,-4576;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1525;-2336,-4368;Inherit;False;ScreenAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;987;-95.8831,-3702.274;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1527;16,-4320;Inherit;False;1525;ScreenAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;984;96,-3472;Inherit;False;Constant;_Vector2;Vector 2;15;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WireNode;1368;-1978.786,-4191.492;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.HSVToRGBNode;14;16,-4576;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;985;16,-3616;Inherit;False;Constant;_Vector3;Vector 3;15;0;Create;True;0;0;0;False;0;False;9999,9999,9999;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;1361;-80,-3872;Inherit;False;Property;_MaximumRenderRange;Maximum Render Range;2;0;Create;True;0;0;0;False;0;False;35;35;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;1042;298.5563,-3640.187;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1360;-81.8443,-3945.786;Inherit;False;Property;_MinimumRenderRange;Minimum Render Range;1;0;Create;True;0;0;0;False;0;False;30;30;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;425;192,-4016;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;1526;288,-4480;Inherit;False;COLOR;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ConditionalIfNode;986;352,-3616;Inherit;False;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;1369;249.6143,-4151.542;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TimeNode;943;-1024,-5584;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;945;-752,-5584;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;567;-624,-5584;Inherit;False;NoiseSpeed;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;428;416,-4048;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;1529;612.2402,-3672.908;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;477;-1024,-5664;Inherit;False;Property;_NoiseSpeedMultiplier;Noise Speed Multiplier;4;0;Create;True;0;0;0;False;0;False;1;0.1;-10;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;441;656,-4096;Half;False;True;-1;7;ASEMaterialInspector;0;0;Unlit;Blippy/Flowing Hue Shift;False;False;False;False;True;True;True;True;True;True;True;True;False;False;True;True;False;False;False;False;False;Front;2;False;-1;7;False;-1;False;0;False;-1;0;False;-1;False;4;Custom;0.5;True;False;-2;True;Overlay;;Overlay;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;0;5;False;-1;10;False;-1;0;2;False;1212;0;False;1213;0;False;-1;1;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;14;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;1;Include;./MirrorCull.cginc;False;71a928ffb0de3b442ab7e52a33f42d54;Custom;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;1519;0;1436;0
WireConnection;1437;0;1514;0
WireConnection;1437;1;1515;0
WireConnection;1520;0;1364;0
WireConnection;1135;0;1183;0
WireConnection;1358;0;1081;0
WireConnection;1365;0;1081;0
WireConnection;1521;0;1520;0
WireConnection;1184;0;1135;0
WireConnection;1501;0;1437;0
WireConnection;1501;1;1519;0
WireConnection;1185;0;1184;0
WireConnection;1432;0;1501;0
WireConnection;1363;0;1521;0
WireConnection;1363;2;1358;0
WireConnection;1363;3;1365;0
WireConnection;1476;0;1135;0
WireConnection;1477;0;1135;0
WireConnection;1478;0;1476;0
WireConnection;1055;0;538;0
WireConnection;1498;0;1436;0
WireConnection;1479;0;1477;0
WireConnection;1513;0;1363;0
WireConnection;1433;0;1501;0
WireConnection;1433;1;1432;0
WireConnection;1433;2;1185;0
WireConnection;1510;0;1363;0
WireConnection;561;0;1055;0
WireConnection;1460;0;1498;0
WireConnection;1460;1;1479;0
WireConnection;1460;3;1510;0
WireConnection;926;0;1433;0
WireConnection;926;1;1478;0
WireConnection;926;2;1433;0
WireConnection;926;3;1513;0
WireConnection;1530;0;1448;0
WireConnection;1507;0;1530;0
WireConnection;1507;2;1460;0
WireConnection;1507;3;926;0
WireConnection;1034;0;1507;0
WireConnection;1034;1;938;0
WireConnection;1522;0;1034;0
WireConnection;946;0;944;2
WireConnection;946;1;524;0
WireConnection;1481;0;1522;0
WireConnection;1017;0;21;0
WireConnection;618;0;946;0
WireConnection;11;0;1017;0
WireConnection;852;1;1481;0
WireConnection;1373;0;852;0
WireConnection;649;0;11;1
WireConnection;980;0;968;0
WireConnection;1328;0;980;0
WireConnection;1320;0;852;0
WireConnection;1531;0;1373;0
WireConnection;1532;0;1297;0
WireConnection;966;0;1531;0
WireConnection;966;1;1320;0
WireConnection;966;2;1328;0
WireConnection;1329;0;966;0
WireConnection;257;0;11;2
WireConnection;257;1;258;0
WireConnection;1315;0;723;0
WireConnection;1534;0;1532;0
WireConnection;1296;0;1329;0
WireConnection;1296;1;1534;0
WireConnection;1316;0;1315;0
WireConnection;779;0;257;0
WireConnection;1372;0;776;0
WireConnection;1331;0;1296;0
WireConnection;722;0;1316;0
WireConnection;778;0;1372;0
WireConnection;778;2;779;0
WireConnection;778;3;257;0
WireConnection;1379;0;1331;0
WireConnection;753;0;778;0
WireConnection;725;0;722;0
WireConnection;730;0;725;0
WireConnection;658;0;1379;0
WireConnection;721;0;1535;0
WireConnection;721;1;1536;0
WireConnection;721;2;730;0
WireConnection;71;0;70;2
WireConnection;71;1;72;0
WireConnection;1528;0;754;0
WireConnection;713;0;11;3
WireConnection;424;0;1006;0
WireConnection;424;1;421;0
WireConnection;1284;0;660;0
WireConnection;1284;1;1224;0
WireConnection;1284;2;71;0
WireConnection;1322;0;754;0
WireConnection;755;0;1528;0
WireConnection;755;1;721;0
WireConnection;401;0;713;0
WireConnection;1304;0;1284;0
WireConnection;1314;0;758;0
WireConnection;1314;2;755;0
WireConnection;1314;3;1322;0
WireConnection;1525;0;21;4
WireConnection;987;0;424;0
WireConnection;1368;0;1017;0
WireConnection;14;0;1304;0
WireConnection;14;1;1314;0
WireConnection;14;2;401;0
WireConnection;1042;0;987;0
WireConnection;425;0;424;0
WireConnection;425;1;1360;0
WireConnection;425;2;1361;0
WireConnection;1526;0;14;1
WireConnection;1526;1;14;2
WireConnection;1526;2;14;3
WireConnection;1526;3;1527;0
WireConnection;986;0;1042;0
WireConnection;986;1;1361;0
WireConnection;986;2;985;0
WireConnection;986;3;984;0
WireConnection;986;4;984;0
WireConnection;1369;0;1368;0
WireConnection;945;0;477;0
WireConnection;945;1;943;1
WireConnection;567;0;945;0
WireConnection;428;0;1526;0
WireConnection;428;1;1369;0
WireConnection;428;2;425;0
WireConnection;1529;0;986;0
WireConnection;441;2;428;0
WireConnection;441;11;1529;0
ASEEND*/
//CHKSM=6F87FDF7277F39EFA9ECA56E5D59317D36AFABF7