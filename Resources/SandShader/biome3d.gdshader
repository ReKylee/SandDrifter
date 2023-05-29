shader_type spatial;

uniform float Height_Dune = 2;
uniform float Height_Detail = 0.10000000149012;
uniform float _SandStrength = 0.1;
uniform float _TerrainRimPower = 0.1;
uniform float _TerrainRimStrength = 0.1;
uniform float _OceanSpecularPower = 0.1;
uniform float _OceanSpecularStrength = 0.1;
uniform float _GlitterThreshold = 0.5;
uniform float _SteepnessSharpnessPower = 1.0;
uniform float _AlignmentSharpnessPower = 1.0;
uniform vec3 _TerrainColor : source_color;
uniform vec3 _ShadowColor : source_color;
uniform vec3 _TerrainRimColor : source_color;
uniform vec3 _OceanSpecularColor : source_color;
uniform vec3 _GlitterColor : source_color;
uniform sampler2D _ShallowHorizontalTex;
uniform sampler2D _ShallowVerticalTex;
uniform sampler2D _SteepHorizontalTex;
uniform sampler2D _SteepVerticalTex;

// FractalPerlinNoise2D
float _perlin2dNoiseFuncFractal(vec2 P) {
	vec4 Pi = floor(vec4(P, P)) + vec4(0.0, 0.0, 1.0, 1.0);
	vec4 Pf = fract(vec4(P, P)) - vec4(0.0, 0.0, 1.0, 1.0);
	
	Pi = Pi - floor(Pi * (1.0 / 289.0)) * 289.0;
	vec4 ix = Pi.xzxz;
	vec4 iy = Pi.yyww;
	vec4 fx = Pf.xzxz;
	vec4 fy = Pf.yyww;
	
	vec4 i = (((((((ix*34.0)+1.0)*ix)-floor((((ix*34.0)+1.0)*ix)*(1.0/289.0))*289.0 + iy)*34.0)+1.0)*
		((((ix*34.0)+1.0)*ix)-floor((((ix*34.0)+1.0)*ix)*(1.0/289.0))*289.0 + iy))-
		floor((((((((ix*34.0)+1.0)*ix)-floor((((ix*34.0)+1.0)*ix)*(1.0/289.0))*289.0 + iy)*34.0)+1.0)*
		((((ix*34.0)+1.0)*ix)-floor((((ix*34.0)+1.0)*ix)*(1.0/289.0))*289.0 + iy))*(1.0/289.0))*289.0;
	
	vec4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0 ;
	vec4 gy = abs(gx) - 0.5 ;
	vec4 tx = floor(gx + 0.5);
	gx = gx - tx;
	
	vec2 g00 = vec2(gx.x,gy.x);
	vec2 g10 = vec2(gx.y,gy.y);
	vec2 g01 = vec2(gx.z,gy.z);
	vec2 g11 = vec2(gx.w,gy.w);
	
	vec4 norm = 1.79284291400159 - 0.85373472095314 * vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
	g00 *= norm.x;
	g01 *= norm.y;
	g10 *= norm.z;
	g11 *= norm.w;
	
	float n00 = dot(g00, vec2(fx.x, fy.x));
	float n10 = dot(g10, vec2(fx.y, fy.y));
	float n01 = dot(g01, vec2(fx.z, fy.z));
	float n11 = dot(g11, vec2(fx.w, fy.w));
	
	vec2 fade_xy = Pf.xy * Pf.xy * Pf.xy * (Pf.xy * (Pf.xy * 6.0 - 15.0) + 10.0);
	vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
	float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
	return 2.3 * n_xy;
}
// SimplexNoise3D
vec4 _permute_simplex3_noise(vec4 x) {
	return ((x * 34.0) + 1.0) * x - floor(((x * 34.0) + 1.0) * x * (1.0 / 289.0)) * 289.0;
}
float _simplex3dNoiseFunc(vec3 v) { 
	vec2 C = vec2(1.0/6.0, 1.0/3.0) ;
	vec4 D = vec4(0.0, 0.5, 1.0, 2.0);
	
	vec3 i  = floor(v + dot(v, vec3(C.y)));
	vec3 x0 = v - i + dot(i, vec3(C.x)) ;
	
	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min( g.xyz, l.zxy );
	vec3 i2 = max( g.xyz, l.zxy );
	
	vec3 x1 = x0 - i1 + vec3(C.x);
	vec3 x2 = x0 - i2 + vec3(C.y);
	vec3 x3 = x0 - D.yyy;
	
	i = i - floor(i * (1.0 / 289.0)) * 289.0;
	vec4 p = _permute_simplex3_noise(_permute_simplex3_noise(_permute_simplex3_noise(
	 		i.z + vec4(0.0, i1.z, i2.z, 1.0))
		+   i.y + vec4(0.0, i1.y, i2.y, 1.0))
		+   i.x + vec4(0.0, i1.x, i2.x, 1.0));
	
	float n_ = 0.142857142857;
	vec3  ns = n_ * D.wyz - D.xzx;
	
	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);
	
	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_ );
	
	vec4 x = x_ *ns.x + vec4(ns.y);
	vec4 y = y_ *ns.x + vec4(ns.y);
	vec4 h = 1.0 - abs(x) - abs(y);
	
	vec4 b0 = vec4( x.xy, y.xy );
	vec4 b1 = vec4( x.zw, y.zw );
	
	vec4 s0 = floor(b0)*2.0 + 1.0;
	vec4 s1 = floor(b1)*2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));
	
	vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
	vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;
	
	vec3 p0 = vec3(a0.xy,h.x);
	vec3 p1 = vec3(a0.zw,h.y);
	vec3 p2 = vec3(a1.xy,h.z);
	vec3 p3 = vec3(a1.zw,h.w);
	
	vec4 norm = 2.79284291400159 - 0.85373472095314 * vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;
	
	vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), vec4(0.0));
	m = m * m;
	return 22.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3) ) );
}
// WorleyNoise2D
vec2 _cellular2dNoiseFunc(vec2 P, float _jitter_w2d) {
	float K = 0.142857142857; // 1/7
	float Ko = 0.428571428571; // 3/7
	
	vec2 Pi = floor(P) - floor(floor(P) * (1.0 / 289.0)) * 289.0;
	vec2 Pf = fract(P);
	vec3 oi = vec3(-1.0, 0.0, 1.0);
	vec3 of = vec3(-0.5, 0.5, 1.5);
	vec3 px = (34.0*(Pi.x+oi)+1.0)*(Pi.x+oi)-floor((34.0*(Pi.x+oi)+1.0)*(Pi.x+oi)*(1.0/289.0))* 289.0;
	vec3 p = (34.0*(px.x+Pi.y+ oi)+1.0)*(px.x+Pi.y+ oi)-floor((34.0*(px.x+Pi.y+oi)+1.0)*(px.x+Pi.y+ oi)*(1.0/289.0))*289.0;
	vec3 ox = fract(p*K) - Ko;
	vec3 oy = (floor(p*K) - floor(floor(p*K) * (1.0 / 7.0)) * 7.0) * K - Ko;
	vec3 dx = Pf.x + 0.5 + _jitter_w2d*ox;
	vec3 dy = Pf.y - of + _jitter_w2d*oy;
	vec3 d1 = dx * dx + dy * dy;
	p = (34.0*(px.y+Pi.y+oi)+1.0)*(px.y+Pi.y+oi)-floor((34.0*(px.y+Pi.y+oi)+1.0)*(px.y+Pi.y+oi)*(1.0/289.0))*289.0;
	ox = fract(p*K) - Ko;
	oy = (floor(p*K) - floor(floor(p*K) * (1.0 / 7.0)) * 7.0) * K - Ko;
	dx = Pf.x - 0.5 + _jitter_w2d*ox;
	dy = Pf.y - of + _jitter_w2d*oy;
	vec3 d2 = dx * dx + dy * dy;
	p = (34.0*(px.z+Pi.y+oi)+1.0)*(px.z+Pi.y+oi)-floor((34.0*(px.z+Pi.y+oi)+1.0)*(px.z+Pi.y+oi)*(1.0/289.0))*289.0;
	ox = fract(p*K) - Ko;
	oy = (floor(p*K) - floor(floor(p*K) * (1.0 / 7.0)) * 7.0) * K - Ko;
	dx = Pf.x - 1.5 + _jitter_w2d*ox;
	dy = Pf.y - of + _jitter_w2d*oy;
	vec3 d3 = dx * dx + dy * dy;
	vec3 d1a = min(d1, d2);
	d2 = max(d1, d2);
	d2 = min(d2, d3);
	d1 = min(d1a, d2);
	d2 = max(d1a, d2);
	d1.xy = (d1.x < d1.y) ? d1.xy : d1.yx;
	d1.xz = (d1.x < d1.z) ? d1.xz : d1.zx;
	d1.yz = min(d1.yz, d2.yz);
	d1.y = min(d1.y, d1.z);
	d1.y = min(d1.y, d2.x);
	return sqrt(d1.xy);
}

float CalculateHeight(vec2 uv) {
	float SimplexNoise = _simplex3dNoiseFunc(vec3(uv, 0.0) * 5.0);
	vec2 simplexed_uv = mix(uv, vec2(SimplexNoise, SimplexNoise), .1);
	
	vec2 DunesWorleyNoise = _cellular2dNoiseFunc(simplexed_uv * 5.0, 1.0) * Height_Dune;
	
	vec2 DetailWorleyNoise = _cellular2dNoiseFunc(simplexed_uv * vec2(1.0, 0.05) * 500.0, 1);
	float DetailSimplexNoise = _simplex3dNoiseFunc(vec3(simplexed_uv, 0.0) * 5.0);
	
	
	

		float overlayed_details;
		if (DetailWorleyNoise.x < 0.5) {
			overlayed_details = 2.0 * DetailWorleyNoise.x * DetailSimplexNoise;
		} else {
			overlayed_details = 1.0 - 2.0 * (1.0 - DetailSimplexNoise) * (1.0 - DetailWorleyNoise.x);
		}
		overlayed_details *= Height_Detail;

		float overlayed_height;
		if (DunesWorleyNoise.x < 0.5) {
			overlayed_height = 2.0 * DunesWorleyNoise.x * overlayed_details;
		} else {
			overlayed_height = 1.0 - 2.0 * (1.0 - overlayed_details) * (1.0 - DunesWorleyNoise.x);
		}
		
		return overlayed_height;
		
		
}

vec3 calc_normal(vec2 uv) { 
    const vec3 off = vec3(-1,0,1);
    vec2 texelSize = 1.0 / vec2(5.0); 

    float left = CalculateHeight(uv + texelSize * off.xy);
    float right = CalculateHeight(uv + texelSize * off.zy);
    float top = CalculateHeight(uv + texelSize * off.yx);
    float down = CalculateHeight(uv + texelSize * off.yz);

    return normalize(vec3(left-right, 2.0, down-top));
}

vec3 nlerp(vec3 n1, vec3 n2, float t)
{
    return normalize(mix(n1, n2, t));
}

void vertex() {
	
	VERTEX.y += CalculateHeight(UV);
	
	vec3 N = calc_normal(UV);
	vec3 S = vec3(_simplex3dNoiseFunc(UV.xyy));
	NORMAL = nlerp(N, S, _SandStrength);
	COLOR.rgb = VERTEX.yyy * 0.05;
	
	
	//o.Albedo = _SandColor;
//    o.Alpha = 1;
//    float3 N = float3(0, 0, 1);
//    N = RipplesNormal(N);
//    N = SandNormal   (N);
//    o.Normal = N;

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
	
    // Random glitter direction
	vec3 RGD = vec3(_simplex3dNoiseFunc(uv.xyy));
    vec3 G = normalize(RGD * 2.0 - 1.0); // [0,1]->[-1,+1]
    // Light that reflects on the glitter and hits the eye
    vec3 R = reflect(L, G);
    float RdotV = max(0, dot(R, V));
    
    // Only the strong ones (= small RdotV)
    if (RdotV > _GlitterThreshold)
        return vec3(0.0);
    
    return (1.0 - RdotV) * _GlitterColor;
}
void light() {
	  // Lighting properties
    vec3 diffuseColor = DiffuseColor    (NORMAL, LIGHT);
    vec3 rimColor     = RimLighting     (NORMAL, VIEW);
    vec3 oceanColor   = OceanSpecular   (NORMAL, LIGHT, VIEW);
    vec3 glitterColor = GlitterSpecular (UV, NORMAL, LIGHT, VIEW);
	
    vec3 specularColor = clamp(max(rimColor, oceanColor), 0.0, 1.0);;
	DIFFUSE_LIGHT = diffuseColor * ATTENUATION;
	SPECULAR_LIGHT = specularColor + glitterColor;
    
	
	
}
vec3 UnpackNormal(vec4 rgba) {
	vec3 n = rgba.xzy * 2.0 - vec3(1.0);
	n.z *= -1.0;
	return n;
}



void fragment() {
	// Calculates normal in world space
	vec3 N_WORLD = NORMAL.x * TANGENT + NORMAL.y * BINORMAL + NORMAL.z * NORMAL;
	vec3 UP_WORLD = vec3(0, 1, 0);

	// Calculates "steepness"
	// => 0: steep (90 degrees surface)
	//  => 1: shallow (flat surface)
	float steepness = clamp(dot(N_WORLD, UP_WORLD), 0.0, 1.0);
	
	// [0,1]->[-1,+1]
	vec3 shallow_horizontal = UnpackNormal(texture(_ShallowHorizontalTex, UV));
	vec3 steep_horizontal   = UnpackNormal(texture(_SteepHorizontalTex, UV));
	
	
	
	// Steepness to blending
	steepness = pow(steepness, _SteepnessSharpnessPower);
	
	// Calculates normal in world space
	vec3 Z_WORLD = vec3(0, 0, 1);

	// Calculates "alignment"
	float alignment = clamp(dot(N_WORLD, Z_WORLD), 0.0, 1.0);
	alignment = pow(alignment, _AlignmentSharpnessPower);
	// [0,1]->[-1,+1]
	vec3 shallow_vertical = UnpackNormal(texture(_ShallowVerticalTex, UV));
	vec3 steep_vertical   = UnpackNormal(texture(_SteepVerticalTex, UV));
	
	// Steepness normal
	vec3 shallow = nlerp(shallow_vertical, shallow_horizontal, alignment);
	vec3 steep = nlerp(steep_vertical, steep_horizontal, alignment);
	
	// Steepness normal
	vec3 S = nlerp(steep, shallow, steepness);
	
	NORMAL += S;
	
}
