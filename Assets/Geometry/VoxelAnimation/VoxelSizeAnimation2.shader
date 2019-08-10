Shader "Geometry/Unlit/VoxelSizeAnimation2"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		[HDR] _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		[HDR] _EmissionColor("Emission Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_Size("Size", Range(0.0, 0.5)) = 0.2
		_Distance("Distance", Range(-1.0, 1.0)) = 0.0
		_Density("Density", Range(0.0, 1.0)) = 0.1
		_Speed("Speed", Range(0.0, 10.0)) = 1.0
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		Cull Off
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma target 4.0
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "../../_Shared/ShaderTools.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float3 _EmissionColor;
			float _Size;
			float _Distance;
			float _Density;
			float _Speed;
			fixed4 _LightColor0;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float2 edge : TEXCOORD2;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			struct vData
			{
				float3 pos;
				float2 uv;
				float3 normal;
				float2 edge;
			};

			g2f SetVertex(vData data)
			{
				g2f o;
				o.vertex.xyz = data.pos;
				o.vertex = UnityObjectToClipPos(o.vertex);
				o.uv = data.uv;
				o.normal = data.normal;
				o.edge = data.edge;
				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}

			appdata vert(appdata v)
			{
				return v;
			}

			#include "VoxelSizeAnimationGeom2.cginc"

			fixed4 frag(g2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				float2 bcc = i.edge;
				float2 fw = fwidth(bcc);
				float2 edge2 = min(smoothstep(fw / 2, fw, bcc),
					smoothstep(fw / 2, fw, 1 - bcc));
				float edge = 1 - min(edge2.x, edge2.y);

				col.xyz += _EmissionColor * edge;

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, c);
				return col;
			}
			ENDCG
		}
	}
}
