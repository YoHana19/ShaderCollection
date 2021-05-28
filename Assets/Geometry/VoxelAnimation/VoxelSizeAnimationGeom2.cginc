#ifndef VoxelSizeAnimationGeom2_INCLUDED
#define VoxelSizeAnimationGeom2_INCLUDED

#define PI 3.141592

vData SetVData(float3 center, float3 posVec, float dist, float2 uv)
{
	vData v;
	v.pos = center + posVec * dist * _Size;
	v.uv = TRANSFORM_TEX(uv, _MainTex);

	return v;
}

[maxvertexcount(24)]
void geom(triangle appdata input[3], uint pid : SV_PrimitiveID, inout TriangleStream<g2f> triStream)
{
	#define ADDV(v, n, e) v.normal = n; v.edge = e; triStream.Append(SetVertex(v))

	uint seed = pid * 877;
	if (Random(seed) > _Density) return;

	float3 center = (input[0].vertex + input[1].vertex + input[2].vertex).xyz / 3;

	float dist0 = distance(input[0].vertex.xyz, center);
	float dist1 = distance(input[1].vertex.xyz, center);
	float dist2 = distance(input[2].vertex.xyz, center);
	float dist = (dist0 + dist1 + dist2) / 3;

	float3 vec1 = (input[1].vertex - input[0].vertex).xyz;
	float3 vec2 = (input[2].vertex - input[0].vertex).xyz;
	float3 nor = normalize(cross(vec1, vec2));

	float2 uv = (input[0].uv + input[1].uv + input[2].uv) / 3;

	
	float time = _Time.y * _Speed;
	float randX = abs(sin(2 * Random2(input[0].uv) * PI + time));
	float randY = abs(sin(2 * Random2(input[1].uv) * PI + time));
	float randZ = abs(sin(2 * Random2(input[2].uv) * PI + time));

	float3 leftFront = float3(-randX, randY, -randZ);
	float3 leftBack = float3(-randX, randY, randZ);
	float3 rightFront = float3(randX, randY, -randZ);
	float3 rightBack = float3(randX, randY, randZ);

	vData v[4][2];

	center += nor * _Distance;

	v[0][0] = SetVData(center, leftFront, dist, uv);
	v[1][0] = SetVData(center, leftBack, dist, uv);
	v[2][0] = SetVData(center, rightFront, dist, uv);
	v[3][0] = SetVData(center, rightBack, dist, uv);
	v[0][1] = SetVData(center, leftFront * float3(1.0, -1.0, 1.0), dist, uv);
	v[1][1] = SetVData(center, leftBack * float3(1.0, -1.0, 1.0), dist, uv);
	v[2][1] = SetVData(center, rightFront * float3(1.0, -1.0, 1.0), dist, uv);
	v[3][1] = SetVData(center, rightBack * float3(1.0, -1.0, 1.0), dist, uv);

	// 上
	ADDV(v[2][0], float3(0, 1, 0), float2(0, 0));
	ADDV(v[0][0], float3(0, 1, 0), float2(1, 0));
	ADDV(v[3][0], float3(0, 1, 0), float2(0, 1));
	ADDV(v[1][0], float3(0, 1, 0), float2(1, 1));
	triStream.RestartStrip();
	// 右
	ADDV(v[2][1], float3(1, 0, 0), float2(0, 0));
	ADDV(v[2][0], float3(1, 0, 0), float2(1, 0));
	ADDV(v[3][1], float3(1, 0, 0), float2(0, 1));
	ADDV(v[3][0], float3(1, 0, 0), float2(1, 1));
	triStream.RestartStrip();
	// 左
	ADDV(v[0][0], float3(-1, 0, 0), float2(0, 0));
	ADDV(v[0][1], float3(-1, 0, 0), float2(1, 0));
	ADDV(v[1][0], float3(-1, 0, 0), float2(0, 1));
	ADDV(v[1][1], float3(-1, 0, 0), float2(1, 1));
	triStream.RestartStrip();
	// 奥
	ADDV(v[1][1], float3(0, 0, 1), float2(0, 0));
	ADDV(v[3][1], float3(0, 0, 1), float2(1, 0));
	ADDV(v[1][0], float3(0, 0, 1), float2(0, 1));
	ADDV(v[3][0], float3(0, 0, 1), float2(1, 1));
	triStream.RestartStrip();
	// 手前
	ADDV(v[2][1], float3(0, 0, -1), float2(0, 0));
	ADDV(v[0][1], float3(0, 0, -1), float2(1, 0));
	ADDV(v[2][0], float3(0, 0, -1), float2(0, 1));
	ADDV(v[0][0], float3(0, 0, -1), float2(1, 1));
	triStream.RestartStrip();
	// 下
	ADDV(v[0][1], float3(0, -1, 0), float2(0, 0));
	ADDV(v[2][1], float3(0, -1, 0), float2(1, 0));
	ADDV(v[1][1], float3(0, -1, 0), float2(0, 1));
	ADDV(v[3][1], float3(0, -1, 0), float2(1, 1));
	triStream.RestartStrip();	
}
#endif