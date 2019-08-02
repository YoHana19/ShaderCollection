//== CREDIT ==//
// This shader is made by hecomi => https://github.com/hecomi/HoloLensPlayground/tree/master/Assets/Holo_NearClip_Effect/Shaders
// The original file name is "DestructionAdditiveGS.shader"
//== ==//

Shader "Geometory/StandardCollapse"
{
	Properties
	{
		[KeywordEnum(Property, Destructor)]
		_Method("DestructionMethod", Float) = 0
		_TintColor("Tint Color", Color) = (0.5, 0.5, 0.5, 0.5)
		_MainTex("Particle Texture", 2D) = "white" {}
		_InvFade("Soft Particles Factor", Range(0.01, 3.0)) = 1.0
		_Destruction("Destruction Factor", Range(0.0, 1.0)) = 0.0
		_PositionFactor("Position Factor", Range(0.0, 1.0)) = 0.2
		_RotationFactor("Rotation Factor", Range(0.0, 1.0)) = 1.0
		_ScaleFactor("Scale Factor", Range(0.0, 1.0)) = 1.0
		_AlphaFactor("Alpha Factor", Range(0.0, 1.0)) = 1.0
		_StartDistance("Start Distance", Float) = 0.6
		_EndDistance("End Distance", Float) = 0.3
		_DestructorPos("Destructor Position", Vector) = (0.0, 0.0, 0.0, 0.0)
	}

	CGINCLUDE

	#include "UnityCG.cginc"

	#define PI 3.1415926535

	sampler2D _MainTex;
	fixed4 _MainTex_ST;
	fixed4 _TintColor;
	sampler2D_float _CameraDepthTexture;
	fixed _InvFade;
	fixed _Destruction;
	fixed _PositionFactor;
	fixed _RotationFactor;
	fixed _ScaleFactor;
	fixed _AlphaFactor;
	fixed _StartDistance;
	fixed _EndDistance;
	fixed4 _DestructorPos;

	struct appdata_t
	{
		float4 vertex : POSITION;
		fixed4 color : COLOR;
		float2 texcoord : TEXCOORD0;
		UNITY_VERTEX_INPUT_INSTANCE_ID // GPUインスタンシング用のIDを発行する
	};

	struct g2f
	{
		float4 vertex : SV_POSITION;
		fixed4 color : COLOR;
		float2 texcoord : TEXCOORD0;
		UNITY_FOG_COORDS(1)
#ifdef SOFTPARTICLES_ON
			float4 projPos : TEXCOORD2;
#endif
		UNITY_VERTEX_OUTPUT_STEREO // シングルパスステレオレンダリングを使うときに必要
	};

	// inline => コンパイル時に呼び出し元のコードに関数内部のコードが直書きされる。処理のオーバヘッドをなくす。短い処理の関数に有用
	inline float rand(float2 seed)
	{
		return frac(sin(dot(seed.xy, float2(12.9898, 78.233))) * 43758.5453); // frac => 小数部を返す、dot => 内積
	}

	float3 rotate(float3 p, float3 rotation)
	{
		float3 a = normalize(rotation);
		float angle = length(rotation);
		if (abs(angle) < 0.001) return p;
		float s = sin(angle);
		float c = cos(angle);
		float r = 1.0 - c;
		float3x3 m = float3x3(
			a.x * a.x * r + c,
			a.y * a.x * r + a.z * s,
			a.z * a.x * r - a.y * s,
			a.x * a.y * r - a.z * s,
			a.y * a.y * r + c,
			a.z * a.y * r + a.x * s,
			a.x * a.z * r + a.y * s,
			a.y * a.z * r - a.x * s,
			a.z * a.z * r + c
			);
		return mul(m, p); // mul => 行列乗算
	}

	appdata_t vert(appdata_t v)
	{
		return v;
	}

	// max vertex count 3が3頂点のoutputであることを伝えている
	// triangle appdata_t input[3]が、「三角形」で3頂点のinputが必要であることを伝えている
	//「ストリーム出力オブジェクト」は出力されるオブジェクトの種類に応じて指定するものが変わる（PointStream, LineStream, TriangleStream) 
	[maxvertexcount(3)] 
	void geom(triangle appdata_t input[3], inout TriangleStream<g2f> stream)
	{
		float3 center = (input[0].vertex + input[1].vertex + input[2].vertex).xyz / 3; // ポリゴンの中心座標を計算

		float3 vec1 = input[1].vertex - input[0].vertex;
		float3 vec2 = input[2].vertex - input[0].vertex;
		float3 normal = normalize(cross(vec1, vec2)); // ポリゴンの法線を計算（標準化済）

#ifdef _METHOD_PROPERTY
		fixed destruction = _Destruction;
#else
		float4 worldPos = mul(unity_ObjectToWorld, float4(center, 1.0));
		// float3 dist = length(_WorldSpaceCameraPos - worldPos); // Destructorがカメラの時は使用できる。_WorldSpaceCameraPosは組み込み変数
		float3 dist = length(_DestructorPos - worldPos);
		fixed destruction = clamp((_StartDistance - dist) / (_StartDistance - _EndDistance), 0.0, 1.0);
#endif

		fixed r = 2 * (rand(center.xy) - 0.5); // 上で定義した関数を使って乱数を生成。乱数0～1を-1～1に変換
		fixed3 r3 = fixed3(r, r, r);

		[unroll]
		for (int i = 0; i < 3; ++i)
		{
			appdata_t v = input[i];

			g2f o;
			UNITY_SETUP_INSTANCE_ID(v); // 発行したGPUインスタンシングのIDを適用する
			UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); // シングルパスステレオレンダリングを使うときに出力を初期化

			// center位置を起点にスケールを変化（_ScaleFactorが小さい方が、ポリゴンは大きくなる）
			v.vertex.xyz = (v.vertex.xyz - center) * (1.0 - destruction * _ScaleFactor) + center;

			// center位置を起点に、乱数を用いて回転を変化
			v.vertex.xyz = rotate(v.vertex.xyz - center, r3 * destruction * _RotationFactor) + center;

			// 乱数を用いて法線方向に位置を変化
			v.vertex.xyz += normal * destruction * _PositionFactor * r3;

			// 修正した頂点位置を射影変換しレンダリング用に変換
			o.vertex = UnityObjectToClipPos(v.vertex);
#ifdef SOFTPARTICLES_ON
			o.projPos = ComputeScreenPos(o.vertex);
			COMPUTE_EYEDEPTH(o.projPos.z);
#endif

			o.color = v.color;

			// 透明度を変化（_AlphaFactorが小さい方が、透明になる）

			o.color.a *= 1.0 - destruction * _AlphaFactor;
			o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
			UNITY_TRANSFER_FOG(o, o.vertex);

			stream.Append(o);
		}
		stream.RestartStrip();
	}

	fixed4 frag(g2f i) : SV_Target
	{
	#ifdef SOFTPARTICLES_ON
		float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
		float partZ = i.projPos.z;
		float fade = saturate(_InvFade * (sceneZ - partZ));
		i.color.a *= fade;
	#endif

		fixed4 col = 2.0f * i.color * _TintColor * tex2D(_MainTex, i.texcoord);
		UNITY_APPLY_FOG_COLOR(i.fogCoord, col, fixed4(0, 0, 0, 0));
		return col;
	}

	ENDCG

	SubShader
	{

		Tags
		{
			"RenderType" = "Transparent"
			"Queue" = "Transparent"
			"IgnoreProjector" = "True" // Projector（Unityの組み込みアセット）を使用しても影響されない
			"PreviewType" = "Plane" // マテリアルのプレビュー。デフォルトはSphere
		}

		Blend SrcAlpha OneMinusSrcAlpha // Blend A B => (デプスバッファに書き込まれている色) * B + (これから描画しようとしている色) * A（アルファ値を効かせるには必要）
		ColorMask RGB
		Cull Off // Cull Back => 裏側を描画しない（デフォルト）、Front => 表側を描画しない（反転したときに用いる）、Off（両側描画）
		Lighting Off
		ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma target 4.0
			#pragma multi_compile_instancing // GPUインスタンシングの使用を選択可能にする
			#pragma multi_compile_particles
			#pragma multi_compile_fog
			#pragma multi_compile _METHOD_PROPERTY _METHOD_DESTRUCTOR
			ENDCG
		}
	}
}