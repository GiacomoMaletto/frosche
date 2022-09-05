local das = love.graphics.newShader([[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
        vec4 c = Texel(texture, texture_coords);
		return vec4(c[2], c[3], c[0], 1.0);
	}
]])

love.graphics.setShader(das)
love.graphics.setCanvas()
love.graphics.draw(x[current])