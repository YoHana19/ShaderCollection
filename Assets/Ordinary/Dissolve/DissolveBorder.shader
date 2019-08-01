// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/DissolveBorder" {
	Properties{
		_Color("Main Color", Color) = (.5,.5,.5,1)
		_MainTex("Base (RGB)", 2D) = "white" {}
		_DissolveTex("Desolve (RGB)", 2D) = "white" {}
		_CutOff("Cut off", Range(0.0, 1.0)) = 0.0
		_Width("Width", Float) = 0.01
	}

		SubShader{
			Tags { "RenderType" = "Opaque" "Queue" = "Transparent" }
			Pass {
				Name "BASE"
				Cull Off

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;

				sampler2D _DissolveTex;
				float4 _DissolveTex_ST;

				float4 _Color;
				float _CutOff;
				float _Width;

				struct appdata {
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;
					float3 normal : NORMAL;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float2 texcoord : TEXCOORD0;
					float2 dissolvecoord : TEXCOORD1;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.dissolvecoord = TRANSFORM_TEX(v.texcoord, _DissolveTex);
					UNITY_TRANSFER_FOG(o,o.pos);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = _Color * tex2D(_MainTex, i.texcoord);
					fixed a = Luminance(tex2D(_DissolveTex, i.dissolvecoord).xyz);
					if (_CutOff > a) {
						discard;
					}

					return col;
				}
				ENDCG
			}

			Pass {
				Tags { "LightMode" = "ForwardBase" }

				Name "Add"
				Cull Off
				Blend One One

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;

				sampler2D _DissolveTex;
				float4 _DissolveTex_ST;

				float4 _Color;
				float _CutOff;
				float _Width;

				struct appdata {
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;
					float3 normal : NORMAL;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float2 dissolvecoord : TEXCOORD0;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.dissolvecoord = TRANSFORM_TEX(v.texcoord, _DissolveTex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed a = Luminance(tex2D(_DissolveTex, i.dissolvecoord).xyz);
					fixed b = smoothstep(_CutOff - _Width, _CutOff, a) - smoothstep(_CutOff, _CutOff + _Width, a);
					return fixed4(0.0, 0.0, b, 1.0);
				}
				ENDCG
			}

			Pass {
				Tags { "LightMode" = "ForwardBase" }

				Name "Add"
				Cull Off
				Blend One One

				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;

				sampler2D _DissolveTex;
				float4 _DissolveTex_ST;

				float4 _Color;
				float _CutOff;
				float _Width;

				struct appdata {
					float4 vertex : POSITION;
					float2 texcoord : TEXCOORD0;
					float3 normal : NORMAL;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					float2 dissolvecoord : TEXCOORD0;
				};

				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.dissolvecoord = TRANSFORM_TEX(v.texcoord, _DissolveTex);
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed a = Luminance(tex2D(_DissolveTex, i.dissolvecoord).xyz);
					fixed w = _Width * 1.5;
					fixed b = smoothstep(_CutOff - w, _CutOff, a) - smoothstep(_CutOff, _CutOff + w, a);
					return fixed4(0.0, b, 0.0, 1.0);
				}
				ENDCG
			}
		}

			Fallback "VertexLit"
}
