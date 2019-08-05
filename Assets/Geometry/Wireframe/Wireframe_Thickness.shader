//== CREDIT ==// 
//This is originated from https://sleepygamersmemo.blogspot.com/2019/02/diffuse-wireframe-with-geometry-shader.html
//== ==//

Shader "Geometry/Diffuse/Wireframe_Thickness"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_Width("Width", Range(0, 1)) = 0.2
		_Thickness("Thickness", Range(0, 1)) = 0.01
	}

	SubShader
	{
		Tags{ "Queue" = "Geometry" "RenderType" = "Opaque" }

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed4 _LightColor0;

			struct vertex_input {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct vertex_output {
				float4 pos : SV_POSITION;
				float3 lightDir : TEXCOORD1;
				float3 normal : TEXCOORD2;
				LIGHTING_COORDS(3, 4)
				float3 vertexLighting : TEXCOORD5;
			};

			vertex_input vert(vertex_input v)
			{
				return v;
			}

			struct vData {
				float3 pos;
				float3 normal;
			};

			vertex_output SetVertex(vData data)
			{
				vertex_input v;
				vertex_output o;

				v.vertex = float4(data.pos, 1);
				v.normal = data.normal;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.lightDir = ObjSpaceLightDir(v.vertex);
				o.normal = v.normal;
				TRANSFER_VERTEX_TO_FRAGMENT(o);

				o.vertexLighting = float3(0.0, 0.0, 0.0);

				#ifdef VERTEXLIGHT_ON

				float3 worldN = mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL);
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

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

			float _Width;
			float _Thickness;

			[maxvertexcount(54)]
			void geo(triangle vertex_input IN[3], inout TriangleStream<vertex_output> triStream)
			{
				#define ADDV(v) triStream.Append(SetVertex(v))
				#define ADDTRI(v1, v2, v3) ADDV(v1); ADDV(v2); ADDV(v3); triStream.RestartStrip()

				float width = lerp(0, 2.0 / 3.0, _Width);
				float thickness = width * _Thickness;
				float3 triNormal = normalize(IN[0].normal + IN[1].normal + IN[2].normal);

				vData v[3][4];

				for (uint i = 0; i < 3; i++)
				{
					vertex_input IN_b = IN[(i + 0) % 3];
					vertex_input IN_1 = IN[(i + 1) % 3];
					vertex_input IN_2 = IN[(i + 2) % 3];

					/* もとの頂点 */
					v[i][0].pos = IN_b.vertex.xyz;
					v[i][0].normal = normalize(IN_b.normal);

					/* もとの位置から横にずらした頂点(側面の表側の頂点) */
					v[i][1].pos = IN_b.vertex.xyz + ((IN_1.vertex.xyz + IN_2.vertex.xyz) * 0.5 - IN_b.vertex.xyz) * width;
					v[i][1].normal = lerp(v[i][0].normal, triNormal, _Width);

					/* 横にずらした頂点の裏(側面の裏側の頂点) */
					v[i][2].pos = v[i][1].pos - v[i][1].normal * thickness;
					v[i][2].normal = -v[i][1].normal;

					/* もとの頂点位置の裏 */
					v[i][3].pos = v[i][0].pos - v[i][0].normal * thickness;
					v[i][3].normal = -v[i][0].normal;
				}

				/* 表面 */
				ADDTRI(v[1][0], v[1][1], v[0][0]);
				ADDTRI(v[0][1], v[0][0], v[1][1]);
				ADDTRI(v[0][0], v[0][1], v[2][0]);
				ADDTRI(v[2][1], v[2][0], v[0][1]);
				ADDTRI(v[2][0], v[2][1], v[1][0]);
				ADDTRI(v[1][1], v[1][0], v[2][1]);

				/* 側面 */
				ADDTRI(v[1][1], v[0][2], v[0][1]);
				ADDTRI(v[0][2], v[1][1], v[1][2]);
				ADDTRI(v[0][1], v[2][2], v[2][1]);
				ADDTRI(v[2][2], v[0][1], v[0][2]);
				ADDTRI(v[2][1], v[1][2], v[1][1]);
				ADDTRI(v[1][2], v[2][1], v[2][2]);

				/* 裏面 */
				ADDTRI(v[1][2], v[1][3], v[0][2]);
				ADDTRI(v[0][3], v[0][2], v[1][3]);
				ADDTRI(v[0][2], v[0][3], v[2][2]);
				ADDTRI(v[2][3], v[2][2], v[0][3]);
				ADDTRI(v[2][2], v[2][3], v[1][2]);
				ADDTRI(v[1][3], v[1][2], v[2][3]);
			}

			half4 frag(vertex_output i) : COLOR
			{
				i.lightDir = normalize(i.lightDir);
				fixed atten = LIGHT_ATTENUATION(i);

				fixed4 col = _Color + fixed4(i.vertexLighting, 1.0);

				fixed diff = saturate(dot(i.normal, i.lightDir));

				fixed4 c;
				c.rgb = UNITY_LIGHTMODEL_AMBIENT.rgb * 2 * col.rgb;
				c.rgb += (col.rgb * _LightColor0.rgb * diff) * (atten * 2);
				c.a = col.a + _LightColor0.a * atten;

				return c;
			}

			ENDCG
		 }

	 Pass
	 {
	  Tags{ "LightMode" = "ForwardAdd" }
	  Blend One One
	  CGPROGRAM
	  #pragma target 4.0
	  #pragma vertex vert
	  #pragma geometry geo
	  #pragma fragment frag
	  #pragma multi_compile_fwdadd

	  #include "UnityCG.cginc"
	  #include "AutoLight.cginc"

	  struct vertex_input {
	   float4 vertex : POSITION;
	   float3 normal : NORMAL;
	  };

	  struct vertex_output {
	   float4 pos : SV_POSITION;
	   float3 lightDir : TEXCOORD2;
	   float3 normal : TEXCOORD1;
	   LIGHTING_COORDS(3, 4)
	  };

	  vertex_input vert(vertex_input v)
	  {
	   return v;
	  }

	  struct vData {
		  float3 pos;
		  float3 normal;
	  };

	  vertex_output SetVertex(vData data)
	  {
	   vertex_input v;
	   vertex_output o;

	   v.vertex = float4(data.pos, 1);
	   v.normal = data.normal;

	   o.pos = UnityObjectToClipPos(v.vertex);

	   o.lightDir = ObjSpaceLightDir(v.vertex);

	   o.normal = v.normal;
	   TRANSFER_VERTEX_TO_FRAGMENT(o);

	   return o;
	  }

	  float _Width;
	  float _Thickness;

	  [maxvertexcount(54)]
	  void geo(triangle vertex_input IN[3], inout TriangleStream<vertex_output> triStream)
	  {
#define ADDV(v) triStream.Append(SetVertex(v))
#define ADDTRI(v1, v2, v3) ADDV(v1); ADDV(v2); ADDV(v3); triStream.RestartStrip()

		  float width = lerp(0, 2.0 / 3.0, _Width);
		  float thickness = width * _Thickness;
		  float3 triNormal = normalize(IN[0].normal + IN[1].normal + IN[2].normal);

		  vData v[3][4];

		  for (uint i = 0; i < 3; i++)
		  {
			  vertex_input IN_b = IN[(i + 0) % 3];
			  vertex_input IN_1 = IN[(i + 1) % 3];
			  vertex_input IN_2 = IN[(i + 2) % 3];

			  /* もとの頂点 */
			  v[i][0].pos = IN_b.vertex.xyz;
			  v[i][0].normal = normalize(IN_b.normal);

			  /* もとの位置から横にずらした頂点(側面の表側の頂点) */
			  v[i][1].pos = IN_b.vertex.xyz + ((IN_1.vertex.xyz + IN_2.vertex.xyz) * 0.5 - IN_b.vertex.xyz) * width;
			  v[i][1].normal = lerp(v[i][0].normal, triNormal, _Width);

			  /* 横にずらした頂点の裏(側面の裏側の頂点) */
			  v[i][2].pos = v[i][1].pos - v[i][1].normal * thickness;
			  v[i][2].normal = -v[i][1].normal;

			  /* もとの頂点位置の裏 */
			  v[i][3].pos = v[i][0].pos - v[i][0].normal * thickness;
			  v[i][3].normal = -v[i][0].normal;
		  }

		  /* 表面 */
		  ADDTRI(v[1][0], v[1][1], v[0][0]);
		  ADDTRI(v[0][1], v[0][0], v[1][1]);
		  ADDTRI(v[0][0], v[0][1], v[2][0]);
		  ADDTRI(v[2][1], v[2][0], v[0][1]);
		  ADDTRI(v[2][0], v[2][1], v[1][0]);
		  ADDTRI(v[1][1], v[1][0], v[2][1]);

		  /* 側面 */
		  ADDTRI(v[1][1], v[0][2], v[0][1]);
		  ADDTRI(v[0][2], v[1][1], v[1][2]);
		  ADDTRI(v[0][1], v[2][2], v[2][1]);
		  ADDTRI(v[2][2], v[0][1], v[0][2]);
		  ADDTRI(v[2][1], v[1][2], v[1][1]);
		  ADDTRI(v[1][2], v[2][1], v[2][2]);

		  /* 裏面 */
		  ADDTRI(v[1][2], v[1][3], v[0][2]);
		  ADDTRI(v[0][3], v[0][2], v[1][3]);
		  ADDTRI(v[0][2], v[0][3], v[2][2]);
		  ADDTRI(v[2][3], v[2][2], v[0][3]);
		  ADDTRI(v[2][2], v[2][3], v[1][2]);
		  ADDTRI(v[1][3], v[1][2], v[2][3]);
	  }

	  sampler2D _MainTex;
	  fixed4 _Color;
	  fixed4 _LightColor0;

		fixed4 frag(vertex_output i) : COLOR
		{
			i.lightDir = normalize(i.lightDir);
			fixed atten = LIGHT_ATTENUATION(i);
			fixed4 col = _Color;
			fixed3 normal = i.normal;
			fixed diff = saturate(dot(normal, i.lightDir));

			fixed4 c;
			c.rgb = (col.rgb * _LightColor0.rgb * diff) * (atten * 2);
			c.a = col.a;

			return c;
		}

	  ENDCG
	 }

	 Pass
	 {
	  Tags{ "LightMode" = "ShadowCaster" }
	  CGPROGRAM
	  #pragma target 4.0
	  #pragma vertex vert
	  #pragma geometry geo
	  #pragma fragment frag
	  #pragma multi_compile_shadowcaster
	  #pragma multi_compile_fwdbase

	  #include "UnityCG.cginc"
	  #include "AutoLight.cginc"
	  #include "UnityLightingCommon.cginc"

	  struct vertex_input {
	   float4 vertex : POSITION;
	   float3 normal : NORMAL;
	  };

	  struct vertex_output {
	   float4 pos : SV_POSITION;
	   float3 normal : TEXCOORD0;
	   fixed4 color : COLOR;
	   SHADOW_COORDS(1)
	  };

	  vertex_input vert(vertex_input v)
	  {
	   return v;
	  }

	  fixed4 _Color;
	  float _Width;
	  float _Thickness;

	  struct vData {
		  float3 pos;
		  float3 normal;
	  };

	  vertex_output SetVertex(vData data)
	  {
	   vertex_output o;

	   o.pos = UnityObjectToClipPos(float4(data.pos, 1));
	   o.normal = data.normal;
	   half3 worldNormal = UnityObjectToWorldNormal(data.normal);
	   half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
	   o.color = nl * _LightColor0 * _Color;
	   TRANSFER_SHADOW(o)
	   return o;
	  }

	  [maxvertexcount(54)]
	  void geo(triangle vertex_input IN[3], inout TriangleStream<vertex_output> triStream)
	  {
#define ADDV(v) triStream.Append(SetVertex(v))
#define ADDTRI(v1, v2, v3) ADDV(v1); ADDV(v2); ADDV(v3); triStream.RestartStrip()

		  float width = lerp(0, 2.0 / 3.0, _Width);
		  float thickness = width * _Thickness;
		  float3 triNormal = normalize(IN[0].normal + IN[1].normal + IN[2].normal);

		  vData v[3][4];

		  for (uint i = 0; i < 3; i++)
		  {
			  vertex_input IN_b = IN[(i + 0) % 3];
			  vertex_input IN_1 = IN[(i + 1) % 3];
			  vertex_input IN_2 = IN[(i + 2) % 3];

			  /* もとの頂点 */
			  v[i][0].pos = IN_b.vertex.xyz;
			  v[i][0].normal = normalize(IN_b.normal);

			  /* もとの位置から横にずらした頂点(側面の表側の頂点) */
			  v[i][1].pos = IN_b.vertex.xyz + ((IN_1.vertex.xyz + IN_2.vertex.xyz) * 0.5 - IN_b.vertex.xyz) * width;
			  v[i][1].normal = lerp(v[i][0].normal, triNormal, _Width);

			  /* 横にずらした頂点の裏(側面の裏側の頂点) */
			  v[i][2].pos = v[i][1].pos - v[i][1].normal * thickness;
			  v[i][2].normal = -v[i][1].normal;

			  /* もとの頂点位置の裏 */
			  v[i][3].pos = v[i][0].pos - v[i][0].normal * thickness;
			  v[i][3].normal = -v[i][0].normal;
		  }

		  /* 表面 */
		  ADDTRI(v[1][0], v[1][1], v[0][0]);
		  ADDTRI(v[0][1], v[0][0], v[1][1]);
		  ADDTRI(v[0][0], v[0][1], v[2][0]);
		  ADDTRI(v[2][1], v[2][0], v[0][1]);
		  ADDTRI(v[2][0], v[2][1], v[1][0]);
		  ADDTRI(v[1][1], v[1][0], v[2][1]);

		  /* 側面 */
		  ADDTRI(v[1][1], v[0][2], v[0][1]);
		  ADDTRI(v[0][2], v[1][1], v[1][2]);
		  ADDTRI(v[0][1], v[2][2], v[2][1]);
		  ADDTRI(v[2][2], v[0][1], v[0][2]);
		  ADDTRI(v[2][1], v[1][2], v[1][1]);
		  ADDTRI(v[1][2], v[2][1], v[2][2]);

		  /* 裏面 */
		  ADDTRI(v[1][2], v[1][3], v[0][2]);
		  ADDTRI(v[0][3], v[0][2], v[1][3]);
		  ADDTRI(v[0][2], v[0][3], v[2][2]);
		  ADDTRI(v[2][3], v[2][2], v[0][3]);
		  ADDTRI(v[2][2], v[2][3], v[1][2]);
		  ADDTRI(v[1][3], v[1][2], v[2][3]);
	  }

	  float4 frag(vertex_output i) : SV_Target
	  {
	   fixed4 col = i.color;
	   SHADOW_CASTER_FRAGMENT(i)
	  }

	  ENDCG
	 }
	}
		Fallback "VertexLit"
}
