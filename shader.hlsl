/* Notes:
 * - The output of the Vertex Shader(VS) is input to the Pixel Shader (PS),
 *   hence why VSMains's return type is PSInput
 * - SV - System Value - indicates the pipeline uses 
 *   values too, not just the shaders.
 */

/**
 * define a struct for input to the pixel shader
 */
struct PSInput
{
    float4 position : SV_POSITION;
    float3 color : COLOR;
};

/** 
 * Constant Buffer - Anything constant to a draw call (vertex/pixel) can go in here
 */
cbuffer cb0 : register(b0)
{
    uint angle;
}


/**
 * Vertex Shader - Resposible for manipulating a 3D scene
 * during the rendering pipeline before being drawn to a screen.
 * Take the triangle's index as input and return its color and initial pos.
 * Z isn't relevant to position since it's a 2D thing.
 *
 *
 */
PSInput VSMain(unsigned int index : SV_VertexID)
{
    PSInput output; //Create an instance of the struct and use the rest of the function to define output.color/position
    
    static float2 positions[3] =
    {
        float2(-0.43f, -0.25f),
	    float2(0.0f, 0.5f),
	    float2(0.43f, -0.25f)
    };
    
    static float3 colors[3] =
    {
        float3(1.0f, 0.0f, 0.0f),
        float3(0.0f, 1.0f, 0.0f),
        float3(0.0f, 0.0f, 1.0f)
    };
    
    float2 input_pos = positions[index];
    
    //rotation matrix
    float rotation_speed = -0.01f;
    
    float cosTheta = cos(angle * rotation_speed);
    float sinTheta = sin(angle * rotation_speed);
    
    float2 rotated_pos;
    rotated_pos.x = input_pos.x * cosTheta - input_pos.y * sinTheta;
    rotated_pos.y = input_pos.x * sinTheta + input_pos.y * cosTheta;
    
    output.position = float4(rotated_pos.x, rotated_pos.y, 0.0f, 1.0f);
    output.color = colors[index];
    return output;
}

/** 
 * Pixel Shader - Responsible for calcuating what color each pixel
 * should be, taking things like light and translucence into account
 */
float4 PSMain(PSInput input) : SV_TARGET
{
    return float4(input.color.r, input.color.g, input.color.b, 1.0f);
}
