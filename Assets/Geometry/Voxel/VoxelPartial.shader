Shader "Geometory/VoxelPartial"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		[HDR] _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_Size("Size", Range(0.0, 0.5)) = 0.2
		_Distance("Distance", Range(-1.0, 1.0)) = 0.0
		_Threshold("Threshold", Range(-0.5, 0.5)) = 0.0
		_Width("Width", Range(0.0, 1.0)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Cull Off
			Tags{ "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
			#pragma geometry geom
            #pragma fragment frag
			#pragma target 4.0
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float _Size;
			float _Distance;
			float _Threshold;
			float _Width;
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
				float3 lightDir : TEXCOORD1;
				float3 normal : TEXCOORD2;
				LIGHTING_COORDS(3, 4)
				float3 vertexLighting : TEXCOORD3;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			struct vData
			{
				float3 pos;
				float2 uv;
				float3 normal;
			};

			g2f SetVertex(vData data)
			{
				g2f o;
				o.vertex.xyz = data.pos;
				o.vertex = UnityObjectToClipPos(o.vertex);
				o.uv = data.uv;
				o.normal = data.normal;
				o.lightDir = ObjSpaceLightDir(o.vertex);
				UNITY_TRANSFER_FOG(o, o.vertex);

				TRANSFER_VERTEX_TO_FRAGMENT(o);

				o.vertexLighting = float3(0.0, 0.0, 0.0);

				#ifdef VERTEXLIGHT_ON

				float3 worldN = mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL);
				float4 worldPos = mul(unity_ObjectToWorld, o.vertex);

				for (int index = 0; index < 4; index++)
				{
					float4 lightPosition = float4(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index], 1.0);
					float3 vertexToLightSource = float3(lightPosition.xyz - worldPos.xyz);
					float3 lightDirection = normalize(vertexToLightSource);
					float squaredDistance = dot(vertexToLightSource, vertexToLightSource);
					float attenuation = 1.0 / (1.0 + unity_4LightAtten0[index] * squaredDistance);
					float3 diffuseReflection = attenuation * float3(unity_LightColor[index].rgb) * float3(_Color.rgb) * max(0.0, dot(worldN, lightDirection));
					o.vertexLighting = o.vertexLighting + diffuseReflection * 2;
				}

				#endif

				return o;
			}

			appdata vert(appdata v)
			{
				return v;
			}

			#include "VoxelParcialSupport.cginc"

			fixed4 frag(g2f i) : SV_Target
			{
				i.lightDir = normalize(i.lightDir);
				fixed atten = LIGHT_ATTENUATION(i);

				fixed4 col = tex2D(_MainTex, i.uv) * _Color + fixed4(i.vertexLighting, 1.0);
				fixed diff = saturate(dot(i.normal, i.lightDir));

				fixed4 c;
				c.rgb = UNITY_LIGHTMODEL_AMBIENT.rgb * 2 * col.rgb;
				c.rgb += (col.rgb * _LightColor0.rgb * diff) * (atten * 2);
				c.a = col.a + _LightColor0.a * atten;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, c);
				return c;
			}
			ENDCG
        }

		Pass
		{
			Cull Back
			Tags{ "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.0
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float _Size;
			float _Distance;
			float _Threshold;
			float _Width;
			fixed4 _LightColor0;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float3 lightDir : TEXCOORD1;
				float3 normal : TEXCOORD2;
				float3 localPos : TEXCOORD3;
				LIGHTING_COORDS(3, 4)
				float3 vertexLighting : TEXCOORD4;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{	
				v2f o;
				o.localPos = v.vertex.xyz;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.lightDir = ObjSpaceLightDir(o.vertex);
				UNITY_TRANSFER_FOG(o, o.vertex);

				TRANSFER_VERTEX_TO_FRAGMENT(o);

				o.vertexLighting = float3(0.0, 0.0, 0.0);

				#ifdef VERTEXLIGHT_ON

				float3 worldN = mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL);
				float4 worldPos = mul(unity_ObjectToWorld, o.vertex);

				for (int index = 0; index < 4; index++)
				{
					float4 lightPosition = float4(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index], 1.0);
					float3 vertexToLightSource = float3(lightPosition.xyz - worldPos.xyz);
					float3 lightDirection = normalize(vertexToLightSource);
					float squaredDistance = dot(vertexToLightSource, vertexToLightSource);
					float attenuation = 1.0 / (1.0 + unity_4LightAtten0[index] * squaredDistance);
					float3 diffuseReflection = attenuation * float3(unity_LightColor[index].rgb) * float3(_Color.rgb) * max(0.0, dot(worldN, lightDirection));
					o.vertexLighting = o.vertexLighting + diffuseReflection * 2;
				}

				#endif
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				if (i.localPos.y > _Threshold && i.localPos.y < _Threshold + _Width) {
					discard;
				}
				i.lightDir = normalize(i.lightDir);
				fixed atten = LIGHT_ATTENUATION(i);

				fixed4 col = tex2D(_MainTex, i.uv) * _Color + fixed4(i.vertexLighting, 1.0);
				fixed diff = saturate(dot(i.normal, i.lightDir));

				fixed4 c;
				c.rgb = UNITY_LIGHTMODEL_AMBIENT.rgb * 2 * col.rgb;
				c.rgb += (col.rgb * _LightColor0.rgb * diff) * (atten * 2);
				c.a = col.a + _LightColor0.a * atten;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, c);
				return c;
			}
			ENDCG
		}
    }
}
