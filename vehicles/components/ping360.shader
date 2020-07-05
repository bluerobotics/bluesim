shader_type canvas_item;

uniform sampler2D my_array;

int get_array_value(ivec2 coord)
{
    // retrieve r component on the desired array position
    float texture_value = texelFetch(my_array, coord, 0).r;
    // the resulting value is in srgb space, so convert it back to linear space
    texture_value *= 255.;
    return int(texture_value);	
}

void fragment() {
    //ALBEDO = vec3(float(get_array_value(ivec2(vec2(100.0, 360.0) * UV))));
    vec2 sizeOverRadius = vec2(2.0, 2.0);
    float sampleOffset = 1.0;
    float polarFactor = 1.0;

    //Move position to the center
    vec2 relPos = UV - vec2(0.5 ,0.5);
    relPos.y = -relPos.y;
    //Adjust for screen ratio
    relPos *= sizeOverRadius;

    //Normalised polar coordinates.
    //y: radius from center
    //x: angle
    vec2 polar;

    polar.y = sqrt(relPos.x * relPos.x + relPos.y * relPos.y);
	
    //Any radius over 1 would go beyond the source texture size, this simply outputs black for those fragments


    polar.x = atan(relPos.y, relPos.x);

    //Fix glsl origin with src data
    polar.x += 3.1415/2.0;

    //Normalise from angle to 0-1 range
    polar.x /= 3.1415*2.0;
    polar.x = mod(polar.x, 1.0);

	
    //The xOffset fixes lines disappearing towards the center of the coordinate system
    //This happens because there's only a few pixels trying to display the whole width of the source image
    //so they 'miss' the lines. To fix this, we sample at the transformed position
    //and a bit to the left and right of it to catch anything we might miss.
    //Using 1 / radius gives us minimal offset far out from the circle,
    //and a wide offset for pixels close to the center
    float xOffset = 0.0;
    if(polar.y != 0.0){
        xOffset = 1.0 / polar.y;
    }

    //Adjusts for texture resolution
    xOffset *= sampleOffset;

    //This inverts the radius variable depending on the polarFactor
    polar.y = polar.y * polarFactor + (1.0 - polar.y) * (1.0 - polarFactor);

    //Sample at positions with a slight offset
    vec4 one = texelFetch(my_array,   ivec2 (int(polar.y*75.0),   int((1.0 - polar.x  - xOffset)*360.0) ), 0);
    vec4 two = texelFetch(my_array,   ivec2 (int(polar.y*75.0),   int((1.0 - polar.x)*360.0) ),            0);
    vec4 three = texelFetch(my_array, ivec2 (int(polar.y*75.0),   int((1.0 - polar.x + xOffset)*360.0) ),  0);
    COLOR.rb = vec2(0.0,0.0);
    COLOR.g = max(((one.r + two.r + three.r) / 3.0), pow(1.-polar.y,6));
	COLOR.a = 1.0 - smoothstep(0.9, 1.0 ,polar.y);
}