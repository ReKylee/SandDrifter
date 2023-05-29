


vec3 hexagonalGrid(vec2 uv, vec3 sharpness, float hexSize, out vec2 r, out vec2 g, out vec2 b) {
	
	//step one
	uv *= 6.0;
	//step four
	float ost = (1.732 / 2.0);
	float ost_rec = 1.0 / ost;
	float v = uv.y * ost_rec;
	
	float u = uv.x - (0.5 / ost) * uv.y;
	vec2 new_uv = vec2(u, v) / hexSize;
	
	vec2 floored_uv = floor(new_uv);
	vec3 differentiate = vec3(0.0, 1.0, 2.0) + (floored_uv.x - floored_uv.y);
	vec3 five_thirds_differentiate = 1.666667 + 1.0/3.0 * differentiate;
	vec3 rounded_fract = round(fract(five_thirds_differentiate));
	
	//step two
	vec2 hex_mask = fract(new_uv);
	float added = (hex_mask.x + hex_mask.y) - 1.0;
	vec2 flipped_inverted_hex_mask = 1.0 - hex_mask.yx;
	
	vec3 combined = vec3(abs(added), hex_mask.x, hex_mask.y);
	vec3 rounded_fract_mult = rounded_fract * 0.0;
	
	if(added > 0.0) {
		rounded_fract_mult = rounded_fract * 1.0;
		
		combined.y = flipped_inverted_hex_mask.x;
		combined.z = flipped_inverted_hex_mask.y;
	} 
	
	r = floored_uv + rounded_fract_mult.x + rounded_fract.xy;
	g = floored_uv + rounded_fract_mult.y + rounded_fract.zx;
	b = floored_uv + rounded_fract_mult.z + rounded_fract.yz;
	
	
	vec3 hex_grid = vec3(
		dot(rounded_fract.zxy, combined),
		dot(rounded_fract.yzx, combined),
		dot(rounded_fract.xyz, combined));
	
	//step three
	vec3 sharpened = pow(hex_grid, sharpness);
	sharpened = sharpened / dot(sharpened, vec3(1.0, 1.0, 1.0));
	
	
	return sharpened;
}