

// HashRandom2dVec
vec2 _hash2vec(vec2 co) {
	float _tmp_h = dot(co, vec2(12.9898, 78.233));
	return fract(vec2(sin(_tmp_h), cos(_tmp_h)) * 43758.5453) * 2.0 - 1.0;
}
// TransformUV
vec2 transformUV(vec2 _uv_transform, vec2 _scale_uv_, vec2 _pivot_scale_uv_, vec2 _offset_uv_, float _rotate_uv, vec2 _pivot_rotate_uv_){
	_uv_transform -= _offset_uv_; // offset
	_uv_transform = (_uv_transform - _pivot_scale_uv_) * _scale_uv_ + _pivot_scale_uv_; // zoom
	vec2 _rot_uv_angl = vec2(cos(_rotate_uv), sin(_rotate_uv));
	mat2 _rot_matrix = mat2(vec2(_rot_uv_angl.x, - _rot_uv_angl.y), vec2(_rot_uv_angl.y, _rot_uv_angl.x));
	_uv_transform = (_uv_transform - _pivot_rotate_uv_) * _rot_matrix + _pivot_rotate_uv_; // rotate
	return _uv_transform;
}

vec2 _random_transformUV(vec2 uv, vec2 randomSeed, float scaleMin, float scaleMax, float rotationMin, float rotationMax) {

	vec2 HashRandom2dVec= _hash2vec(randomSeed);

	vec2 SecondHashRandom2dVec= _hash2vec(randomSeed * 16.0);



	vec2 randomScale = vec2(mix(scaleMin, scaleMax, SecondHashRandom2dVec.x));

// Mix:12
	float randomRotation = mix(rotationMin, rotationMax, SecondHashRandom2dVec.y);

	vec2 scalePivot = vec2(0.50000, 0.50000);
	vec2 rotationPivot = vec2(0.50000, 0.50000);

	return transformUV(uv, randomScale, scalePivot, HashRandom2dVec, randomRotation, rotationPivot);
}
