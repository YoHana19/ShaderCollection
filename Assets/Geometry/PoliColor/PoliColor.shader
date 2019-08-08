Shader "Geometry/Unlit/PoliColor"
{
    Properties
    {
		_Saturation("Saturation", Range(0.0, 1.0)) = 0.8
		_Luminosity("Luminosity", Range(0.0, 1.0)) = 0.5
		_Speed("Speed", Range(0, 3.0)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma geometry geom
			#pragma target 4.0

            #include "UnityCG.cginc"
			#include "../../_Shared/ShaderTools.cginc"

			fixed _Saturation;
			fixed _Luminosity;
			fixed _Speed;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
				float4 color : COLOR;
            };

            appdata vert (appdata v)
            {
                return v;
            }

			[maxvertexcount(3)]
			void geom(triangle appdata input[3], uint pid : SV_PrimitiveID, inout TriangleStream<g2f> stream)
			{
				// Color
				half time = _Time.y * _Speed;
				float hue = sin(pid * 832.37843) + time;
				float4 hsl = fixed4(frac(hue), _Saturation, _Luminosity, 1.0);
				float4 rgb = HSLtoRGB(hsl);

				for (int i = 0; i < 3; i++) {
					g2f o;
					o.vertex = UnityObjectToClipPos(input[i].vertex);
					o.color = rgb;
					stream.Append(o);
				}
				stream.RestartStrip();
			}

            fixed4 frag (g2f i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }
    }
}
