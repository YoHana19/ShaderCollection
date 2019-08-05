Shader "Geometory/Unlit/Voxel"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_Size("Size", Range(0.0, 0.5)) = 0.2
		_Distance("Distance", Range(-1.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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

            struct appdata
            {
                float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
            };

            struct g2f
            {
				float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float _Size;
			float _Distance;

			g2f SetVertex(float3 center, float3 posVec, float dist, float2 uv)
			{
				g2f o;
				o.vertex.xyz = center + posVec * dist * _Size;
				o.vertex = UnityObjectToClipPos(o.vertex);
				o.uv = TRANSFORM_TEX(uv, _MainTex);
				UNITY_TRANSFER_FOG(o, o.vertex);
				return o;
			}

			appdata vert (appdata v)
            {
                return v;
            }

			[maxvertexcount(36)]
			void geom(triangle appdata input[3], inout TriangleStream<g2f> triStream)
			{
				#define ADDV(v) triStream.Append(v)
				#define ADDTRI(v1, v2, v3) ADDV(v1); ADDV(v2); ADDV(v3); triStream.RestartStrip()

				float3 center = (input[0].vertex + input[1].vertex + input[2].vertex).xyz / 3;
				float dist0 = distance(input[0].vertex.xyz, center);
				float dist1 = distance(input[1].vertex.xyz, center);
				float dist2 = distance(input[2].vertex.xyz, center);
				float dist = (dist0 + dist1 + dist2) / 3;

				float3 vec1 = (input[1].vertex - input[0].vertex).xyz;
				float3 vec2 = (input[2].vertex - input[0].vertex).xyz;
				float3 normal = normalize(cross(vec1, vec2));

				float2 uv = (input[0].uv + input[1].uv + input[2].uv) / 3;

				float3 leftFront = float3(-1, 1, -1);
				float3 leftBack = float3(-1, 1, 1);
				float3 rightFront = float3(1, 1, 1);
				float3 rightBack = float3(1, 1, -1);

				g2f v[4][2];

				center += normal * _Distance;

				v[0][0] = SetVertex(center, leftFront, dist, uv);
				v[1][0] = SetVertex(center, leftBack, dist, uv);
				v[2][0] = SetVertex(center, rightFront, dist, uv);
				v[3][0] = SetVertex(center, rightBack, dist, uv);
				v[0][1] = SetVertex(center, leftFront * float3(1.0, -1.0, 1.0), dist, uv);
				v[1][1] = SetVertex(center, leftBack * float3(1.0, -1.0, 1.0), dist, uv);
				v[2][1] = SetVertex(center, rightFront * float3(1.0, -1.0, 1.0), dist, uv);
				v[3][1] = SetVertex(center, rightBack * float3(1.0, -1.0, 1.0), dist, uv);

				// 上
				ADDTRI(v[0][0], v[1][0], v[3][0]);
				ADDTRI(v[2][0], v[1][0], v[3][0]);
				// 右
				ADDTRI(v[3][0], v[2][0], v[3][1]);
				ADDTRI(v[2][0], v[2][1], v[3][1]);
				// 左
				ADDTRI(v[0][0], v[1][0], v[0][1]);
				ADDTRI(v[1][0], v[0][1], v[1][1]);
				// 手前
				ADDTRI(v[0][0], v[3][0], v[0][1]);
				ADDTRI(v[3][0], v[0][1], v[3][1]);
				// 奥
				ADDTRI(v[1][0], v[2][0], v[1][1]);
				ADDTRI(v[2][0], v[1][1], v[2][1]);
				// 下
				ADDTRI(v[0][1], v[1][1], v[3][1]);
				ADDTRI(v[2][1], v[1][1], v[3][1]);

			}

            fixed4 frag (g2f i) : SV_Target
            {  
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
