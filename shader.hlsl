/* Notes:
 * - The output of the Vertex Shader(VS) is input to the Pixel Shader (PS),
 *   hence why VSMains's return type is PSInput
 * - SV - System Value - indicates the pipeline uses 
 *   values too, not just the shaders.
 */




/* Vertex Shader - Resposible for manipulating a 3D scene
 * during the rendering pipeline before being drawn to a screen
 */

/* Pixel Shader - Responsible for calcuating what color each pixel
 * should be, taking things like light and translucence into account
 */
float4 PSMain(/*PSInput input*/) : SV_TARGET
{
    return float4( /*input.color.r, input.color.g, input.color.b*/, 1.0f);
}
