shader_type canvas_item;

const highp vec2 flipMapSizeInv = vec2(0.25,0.5);
const highp vec2 flipOffset = vec2(-1,-1);

uniform highp vec2 viewportSize = vec2(256,240);
uniform highp vec2 inverseTileTextureSize = vec2(0.0078125,0.0078125);
uniform highp vec2 inverseTileSize = vec2(0.0625,0.0625);

uniform highp sampler2D tileset;
uniform highp sampler2D tilemap;
uniform highp sampler2D flipMap;

uniform highp vec2 inverseSpriteTextureSize = vec2(0.0232558139535,0.0294117647059);
uniform highp vec2 tileSize = vec2(16,16);

void fragment()
{
	highp vec2 pixelCoord = (UV * viewportSize);
	highp vec2 texCoord = pixelCoord * inverseSpriteTextureSize * inverseTileSize;
	highp vec4 tile = texture(tilemap, texCoord);
	highp vec2 spriteOffset = floor(tile.xy * 256.0) * tileSize;
	
	highp vec2 spriteCoord = mod(pixelCoord, tileSize);
	
	if(tile.b != 0.0)
	{
		highp float flip_id = tile.b*256.0;
		spriteCoord = spriteCoord*(texture(flipMap,vec2(flip_id,1.0)*flipMapSizeInv).rg*256.0 + flipOffset) + tileSize*(texture(flipMap,vec2(flip_id,0.0)*flipMapSizeInv).rg*256.0);
	}
	COLOR = texture(tileset, (spriteOffset + spriteCoord) * inverseTileTextureSize);
	COLOR.a = tile.a*COLOR.a;
}