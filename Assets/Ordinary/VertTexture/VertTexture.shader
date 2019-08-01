Shader "Custom/VertexTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Threshold("Threshold", Range(-0.55,0.55))= 0.0
    }
    SubShader
    {
    
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 localPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float4 diff  : COLOR0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Threshold;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.localPos = v.vertex.xyz;
                half3 worldNormal = UnityObjectToWorldNormal(v.normal);
                half nl = max(0, dot(worldNormal, _WorldSpaceLightPos0.xyz));
                o.diff = nl * _LightColor0;
                o.diff.rgb += ShadeSH9(half4(worldNormal,1));
                
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                if ( i.localPos.y < _Threshold ) {
                    discard; 
                }
                
                fixed4 col = tex2D(_MainTex, i.uv);
                col *= i.diff;
                
                return col;
            }             
            ENDCG
        }
    }
}