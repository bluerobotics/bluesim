shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color;
uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;


void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0],MODEL_MATRIX[1],MODEL_MATRIX[2],MODEL_MATRIX[3]);
	//MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(1.0, 0.0, 0.0, 0.0),vec4(0.0, 1.0/length(WORLD_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0),vec4(0.0, 0.0, 0.0 ,1.0));
}

const int MAX_ITER = 5;
// perf increase for god ray, eliminates Y
float causticX(float x, float power, float gtime)
{
    float p = mod(x*TAU, TAU)-250.0;
    float time = gtime * .5+23.0;

	float i = p;
	float c = 1.0;
	float inten = .005;

	for (int n = 0; n < MAX_ITER/2; n++) 
	{
		float t = time * (1.0 - (3.5 / float(n+1)));
		i = p + cos(t - i) + sin(t + i);
		c += 1.0/abs(p / (sin(i+t)/inten));
	}
	c /= float(MAX_ITER);
	c = 1.17-pow(c, power);
    
    return c;
}

float GodRays(vec2 uv, float iTime)
{
    float light = 0.0;

    //alight += pow(causticX(sin(uv.x), 0.3,iTime*0.7),9.0)*0.4; 
    light += pow(causticX(cos(uv.x), 0.3,iTime*1.3),4.0)*0.1;  
    light-=pow((1.0-uv.y)*0.3,3.0);
    light=clamp(light,0.0,1.0);
	light*= smoothstep(1.2, 0.0, uv.y);
	light*= smoothstep(1.0, 0.0, uv.x);
	light*= smoothstep(0.0, 1.0, uv.x);
    
    return light;
}

float distance_fade(in vec3 vertex, in float distance_min, in float distance_max) {
	return clamp(smoothstep(distance_min, distance_max, -vertex.z), 0.0, 1.0);
}
void fragment() {
	float gr = GodRays(UV, TIME*1.0);
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	albedo_tex *= COLOR;
	EMISSION = vec3(1.0,1.0,1.0);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	ALPHA = 100.0* gr * distance_fade(VERTEX, 2, 4) * COLOR.a;
	
}
