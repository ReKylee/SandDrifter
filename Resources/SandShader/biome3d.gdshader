shader_type spatial;
render_mode diffuse_lambert;

const vec2 TEXEL_SIZE = 1.0 / vec2(512.0);

uniform vec2 uv_offset;

group_uniforms Heightmaps;
uniform sampler2D _perlin2dNoiseFractal: filter_nearest_mipmap;
uniform sampler2D _simplex3dNoise: filter_nearest_mipmap;
uniform sampler2D _cellular2dNoise : filter_nearest_mipmap;

group_uniforms Dune;
uniform float Height_Dune = 50;
uniform vec3 _TerrainColor : source_color;
uniform float _SandStrength = 0.1;
uniform vec3 _ShadowColor : source_color;
uniform float _TerrainRimPower = 5.992;
uniform float _TerrainRimStrength = 0.168;
uniform vec3 _TerrainRimColor : source_color;

group_uniforms Details;
uniform float Height_Detail = 0.01;
uniform float _OceanSpecularPower = 4.1;
uniform float _OceanSpecularStrength = 0.155;
uniform vec3 _OceanSpecularColor : source_color;
uniform float _GlitterThreshold = 0.2;
uniform vec3 _GlitterColor : source_color;
uniform float _SteepnessSharpnessPower = 1.0;
uniform float _AlignmentSharpnessPower = 1.0;

group_uniforms NormalMaps;
uniform sampler2D _SandTex : hint_normal;
uniform sampler2D _GlitterTex : filter_nearest_mipmap;
uniform sampler2D _ShallowHorizontalTex : filter_nearest_mipmap;
uniform sampler2D _ShallowVerticalTex: filter_nearest_mipmap;
uniform sampler2D _SteepHorizontalTex: filter_nearest_mipmap;
uniform sampler2D _SteepVerticalTex: filter_nearest_mipmap;

vec3 TransformMult(in mat4 mat, in vec3 vec) {
	return (mat * vec4(vec, 1.0)).xyz;
}

float overlay(float a, float b) {
	if(a < 0.5) {
		return 2.0 * a * b;
	} else {
		return 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
	}
}

float CalculateHeight(vec2 uv) {
	
	float SimplexNoise = textureLod(_simplex3dNoise, uv, 0).r;
	
	vec2 amount = smoothstep(0,1,sin(uv*PI)*.1);
	vec2 simplexed_uv = mix(uv, vec2(SimplexNoise,SimplexNoise), amount);
	float DunesWorleyNoise = textureLod(_cellular2dNoise, simplexed_uv, 0).r * Height_Dune;
	
	float DetailPerlinNoise = textureLod(_perlin2dNoiseFractal, simplexed_uv , 0).r;
	float DetailSimplexNoise = textureLod(_simplex3dNoise, simplexed_uv, 0).r;

	float overlayed_details = overlay(DetailPerlinNoise, DetailSimplexNoise) * Height_Detail;
	
	float overlayed_height = overlay(DunesWorleyNoise, overlayed_details) ;
	
	return overlayed_height;

}



vec3 calc_normal(vec2 uv) { 
    const vec3 off = vec3(-1,0,1);

	vec2 e = vec2(0.01, 0.0);

    float left = CalculateHeight(uv + TEXEL_SIZE * off.xy);
    float right = CalculateHeight(uv + TEXEL_SIZE * off.zy);
    float top = CalculateHeight(uv + TEXEL_SIZE * off.yx);
    float down = CalculateHeight(uv + TEXEL_SIZE * off.yz);

    return normalize(vec3(left-right, 2.0, down-top));
}

vec3 nlerp(vec3 n1, vec3 n2, float t)
{
    return normalize(mix(n1, n2, t));
}

vec3 UnpackNormal(vec3 rgb) {
	vec3 n = rgb.xzy * 2.0 - 1.0; 
	n.z *= -1.0; 
	return n; 
}

vec3 SandSteepness(vec2 uv, vec3 N_WORLD, vec3 UP_WORLD, vec3 Z_WORLD) { 

	// Calculates "steepness"
	// => 0: steep (90 degrees surface)
	//  => 1: shallow (flat surface)
	float steepness = clamp(dot(N_WORLD, UP_WORLD), 0.0, 1.0);
	
	// [0,1]->[-1,+1]
	vec3 shallow_horizontal = UnpackNormal(texture(_ShallowHorizontalTex, uv).rgb);
	vec3 steep_horizontal   = UnpackNormal(texture(_SteepHorizontalTex, uv).rgb);
	
	// Steepness to blending
	steepness = pow(steepness, _SteepnessSharpnessPower);
	
	// Calculates "alignment"
	float alignment = clamp(dot(N_WORLD, Z_WORLD), 0.0, 1.0);
	alignment = pow(alignment, _AlignmentSharpnessPower);

	vec3 shallow_vertical = UnpackNormal(texture(_ShallowVerticalTex, uv).rgb);
	vec3 steep_vertical   = UnpackNormal(texture(_SteepVerticalTex, uv).rgb);
	
	// Steepness normal
	vec3 shallow = nlerp(shallow_vertical, shallow_horizontal, alignment);
	vec3 steep = nlerp(steep_vertical, steep_horizontal, alignment);
	
	// Steepness normal
	vec3 S = nlerp(steep, shallow, steepness);
	return S;
}



void vertex() {
	
	const vec3 UP_WORLD = TransformMult(INV_VIEW_MATRIX, vec3(0, 1, 0));
	const vec3 Z_WORLD = TransformMult(INV_VIEW_MATRIX, vec3(0, 0, 1));
	
	vec2 offsetUVs = UV + uv_offset;
	
	vec3 N = calc_normal(offsetUVs);
	
	// Random direction
	vec3 R = UnpackNormal(normalize(texture(_SandTex, offsetUVs).rgb * 2.0 - 1.0));
	
	vec3 S = SandSteepness(offsetUVs, TransformMult(INV_VIEW_MATRIX, N), UP_WORLD, Z_WORLD);
	
	S= nlerp(S, R, _SandStrength);
	
	VERTEX.y += CalculateHeight(offsetUVs);
	NORMAL = N + S;

}



vec3 DiffuseColor(vec3 N, vec3 L)
{
	 N.y *= 0.3;
    float NdotL = clamp(4.0 * dot(N, L), 0.0, 1.0);
	
	vec3 color = mix(_ShadowColor, _TerrainColor, NdotL);
    return color;
}

vec3 RimLighting(vec3 N, vec3 V)
{
    float rim = 1.0 - clamp(dot(N, V), 0.0, 1.0);
    rim = clamp(pow(rim, _TerrainRimPower) * _TerrainRimStrength, 0.0, 1.0);
    rim = max(rim, 0); // Never negative
    return rim * _TerrainRimColor;
}
vec3 OceanSpecular (vec3 N, vec3 L, vec3 V)
{
    // Blinn-Phong
    vec3 H = normalize(V + L); // Half direction
    float NdotH = max(0, dot(N, H));	
    float specular = pow(NdotH, _OceanSpecularPower) * _OceanSpecularStrength;
    return specular * _OceanSpecularColor;
}

vec3 GlitterSpecular (vec2 uv, vec3 N, vec3 L, vec3 V)
{
	

    vec3 G = normalize(texture(_GlitterTex, uv * 70.0).rgb * 2.0 - 1.0); // [0,1]->[-1,+1]
    // Light that reflects on the glitter and hits the eye
    vec3 R = reflect(L, G);
    float RdotV = max(0, dot(R, V));
    
    // Only the strong ones (= small RdotV)
    if (RdotV > _GlitterThreshold)
        return vec3(0.0);
    
    return (1.0 - RdotV) * _GlitterColor;
}

void light() {
	vec2 uv = UV + uv_offset;
	
	//Here Light and View needs to be in view space
	vec3 diffuseColor = DiffuseColor    (NORMAL, LIGHT);
	vec3 rimColor     = RimLighting     (NORMAL, VIEW);
	vec3 oceanColor   = OceanSpecular   (NORMAL, LIGHT, VIEW);
	vec3 glitterColor = GlitterSpecular (uv, NORMAL, LIGHT, VIEW);
	
    vec3 specularColor = clamp(max(rimColor, oceanColor), 0.0, 1.0);
	DIFFUSE_LIGHT += diffuseColor * ATTENUATION * LIGHT_COLOR * ALBEDO;
	SPECULAR_LIGHT += (specularColor + glitterColor)  * ATTENUATION * LIGHT_COLOR;
    
	
	
}




void fragment() {
	ALBEDO = _TerrainColor;
}
