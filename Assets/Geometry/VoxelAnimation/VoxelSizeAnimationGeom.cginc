#ifndef VoxelSizeAnimationGeom_INCLUDED
#define VoxelSizeAnimationGeom_INCLUDED

#define PI 3.141592

vData SetVData(float3 center, float3 posVec, float dist, float2 uv)
{
	vData v;
	v.pos = center + posVec * dist * _Size;
	v.uv = TRANSFORM_TEX(uv, _MainTex);

	return v;
}

[maxvertexcount(36)]
void geom(triangle appdata input[3], uint pid : SV_PrimitiveID, inout TriangleStream<g2f> triStream)
{
	#define ADDV(v, n) v.normal = n; triStream.Append(SetVertex(v))
	#define ADDTRI(v1, v2, v3, n) ADDV(v1, n); ADDV(v2, n); ADDV(v3, n); triStream.RestartStrip()

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
	float3 rightFront = float3(randX, randY, randZ);
	float3 rightBack = float3(randX, randY, -randZ);

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
	ADDTRI(v[0][0], v[1][0], v[3][0], float3(0, 1, 0));
	ADDTRI(v[2][0], v[1][0], v[3][0], float3(0, 1, 0));
	// 右
	ADDTRI(v[3][0], v[2][0], v[3][1], float3(1, 0, 0));
	ADDTRI(v[2][0], v[2][1], v[3][1], float3(1, 0, 0));
	// 左
	ADDTRI(v[0][0], v[1][0], v[0][1], float3(-1, 0, 0));
	ADDTRI(v[1][0], v[0][1], v[1][1], float3(-1, 0, 0));
	// 手前
	ADDTRI(v[0][0], v[3][0], v[0][1], float3(0, 0, 1));
	ADDTRI(v[3][0], v[0][1], v[3][1], float3(0, 0, 1));
	// 奥
	ADDTRI(v[1][0], v[2][0], v[1][1], float3(0, 0, -1));
	ADDTRI(v[2][0], v[1][1], v[2][1], float3(0, 0, -1));
	// 下
	ADDTRI(v[0][1], v[1][1], v[3][1], float3(0, -1, 0));
	ADDTRI(v[2][1], v[1][1], v[3][1], float3(0, -1, 0));
}
#endif