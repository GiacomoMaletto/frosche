local initial_x_shader = love.graphics.newShader([[
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
        float min1 = -4.0;
        float max1 = 6.0;
        float min2 = -4.0;
        float max2 = 6.0;

        float phi1 = 0.0;
        float phi2 = 0.0;
        float I1 = mix(min1, max1, texture_coords[0]);
        float I2 = mix(min2, max2, texture_coords[1]);

		return vec4(phi1, phi2, I1, I2);
	}
]])

local initial_v_shader = love.graphics.newShader([[
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
        vec4 v = normalize(vec4(1.0, 1.0, 1.0, 1.0));

		return v;
	}
]])

local x_shader = love.graphics.newShader([[
    float f1(float x, float y){
        return sin(x)*pow(cos(x)+cos(y)+4.0, -2.0);
    }

    float f2(float x, float y){
        return sin(y)*pow(cos(x)+cos(y)+4.0, -2.0);
    }

    #define PI 3.1415926538

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
        float e = 0.6;

        vec4 x = Texel(texture, texture_coords);
        float phi1 = x[0];
        float phi2 = x[1];
        float I1 = x[2];
        float I2 = x[3];

        float phi1p = phi1 + I1;
        float phi2p = phi2 + I2;
        float I1p = I1 + e * f1(phi1+I1, phi2+I2);
        float I2p = I2 + e * f2(phi1+I1, phi2+I2);

		return vec4(phi1p, phi2p, I1p, I2p);
	}
]])

local v_shader = love.graphics.newShader([[
	uniform Image x_image;

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
        float e = 0.6;

        vec4 x = Texel(x_image, texture_coords);
        float phi1 = x[0];
        float phi2 = x[1];
        float I1 = x[2];
        float I2 = x[3];

        float s1 = sin(phi1+I1);
        float s2 = sin(phi2+I2);
        float c1 = cos(phi1+I1);
        float c2 = cos(phi2+I2);
        float d = c1+c2+4.0;
        float d2 = d*d;
        float d3 = d*d*d;

        mat4 J;
        J[0] = vec4(1.0, 0.0, 1.0, 0.0);
        J[1] = vec4(0.0, 1.0, 0.0, 1.0);
        J[2] = vec4(2.0*e*s1*s1/d3 + e*c1/d2, 2.0*e*s1*s2/d3, 2.0*e*s1*s1/d3 + e*c1/d2 + 1.0, 2.0*e*s1*s2/d3);
        J[3] = vec4(2.0*e*s1*s2/d3, 2.0*e*s2*s2/d3 + e*c2/d2, 2.0*e*s1*s2/d3, 2.0*e*s2*s2/d3 + e*c2/d2 + 1.0);
        J = transpose(J);

        vec4 v = Texel(texture, texture_coords);

        //return (normalize(J*v));
	    return (J*v);
	}
]])

local mv_shader = love.graphics.newShader([[
	uniform Image v_image;

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
        vec4 v = Texel(v_image, texture_coords);
        float nv = log(length(v));
        float mv = Texel(texture, texture_coords)[0];

		return vec4(max(mv,nv), 0.0, 0.0, 1.0);
	}
]])

local display_shader = love.graphics.newShader([[
    const float infinity = 1. / 0.;
    float NaN = 0.0/0.0;
    const float minf = -1.0/0.0;

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
        float x = texture_coords[0];
        float y = 1.0 - texture_coords[1];
        float mv = Texel(texture, vec2(x,y))[0];

        float c = (10.0 - mv)/(10.0 - 1.5);
		return vec4(c, c, c, 1.0);
	}
]])

local sw, sh = love.graphics.getDimensions()

love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBlendMode("replace", "premultiplied")

local nw, nh = sw, sh

local white = love.graphics.newCanvas(nw, nh, {format="rgba32f"})
love.graphics.setCanvas(white)
love.graphics.clear(1, 1, 1)
love.graphics.setCanvas()

local current = 1

local x = {}
x[1] = love.graphics.newCanvas(nw, nh, {format="rgba32f"})
x[2] = love.graphics.newCanvas(nw, nh, {format="rgba32f"})

love.graphics.setCanvas(x[2])
love.graphics.setShader(initial_x_shader)
love.graphics.draw(white)
love.graphics.setShader()
love.graphics.setCanvas()

local v = {}
v[1] = love.graphics.newCanvas(nw, nh, {format="rgba32f"})
v[2] = love.graphics.newCanvas(nw, nh, {format="rgba32f"})

love.graphics.setCanvas(v[2])
love.graphics.setShader(initial_v_shader)
love.graphics.draw(white)
love.graphics.setShader()
love.graphics.setCanvas()

local mv = {}
mv[1] = love.graphics.newCanvas(nw, nh, {format="r32f"})
mv[2] = love.graphics.newCanvas(nw, nh, {format="r32f"})

function love.update(dt)
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
end

function love.draw()
    love.graphics.setShader(x_shader)
    love.graphics.setCanvas(x[current])
    love.graphics.draw(x[3-current])

    love.graphics.setShader(v_shader)
    love.graphics.setCanvas(v[current])
    v_shader:send("x_image", x[3-current])
    love.graphics.draw(v[3-current])

    love.graphics.setShader(mv_shader)
    love.graphics.setCanvas(mv[current])
    mv_shader:send("v_image", v[3-current])
    love.graphics.draw(mv[3-current])

    love.graphics.setShader(display_shader)
    love.graphics.setCanvas()
    love.graphics.draw(mv[current])

    love.graphics.setShader()

    current = 3-current
end