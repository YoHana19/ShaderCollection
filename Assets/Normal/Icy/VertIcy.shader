Shader "Unlit/VertIcy"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Threshold("Threshold", Range(-0.5,0.5)) = 0.0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100
        
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                half3 worldNormal : TEXCOORD1;
                float3 localPos : TEXCOORD2;
            };
            
            fixed4 _Color;
            half _Threshold;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.localPos = v.vertex.xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                if ( i.localPos.y < _Threshold ) {
                    discard; 
                }
                fixed4 col = _Color;
                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float alpha = 1 - (abs(dot(worldViewDir, i.worldNormal)));
                col.a = alpha;
                return col;
            }
            ENDCG
        }
    }
}
