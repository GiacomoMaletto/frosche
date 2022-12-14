local initial_x_shader = love.graphics.newShader([[
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
        float min1 = -4.0;
        float max1 = 6.0;
        float min2 = -4.0;
        float max2 = 6.0;
        
        //float min1 = 1.4;
        //float max1 = 2.8;
        //float min2 = 0.4;
        //float max2 = 1.8;

        float phi1 = 0.0;
        float phi2 = 0.0;
        float I1 = mix(min1, max1, texture_coords[0]);
        float I2 = mix(min2, max2, texture_coords[1]);

		return vec4(phi1, phi2, I1, I2);
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

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
        float e = -0.6;

        vec4 x = Texel(texture, texture_coords);
        float phi1 = x[0];
        float phi2 = x[1];
        float I1 = x[2];
        float I2 = x[3];

        float phi1p = mod(phi1 + I1, 2.0*PI);
        float phi2p = mod(phi2 + I2, 2.0*PI);
        float I1p = I1 + e * f1(phi1+I1, phi2+I2);
        float I2p = I2 + e * f2(phi1+I1, phi2+I2);

		return vec4(phi1p, phi2p, I1p, I2p);
	}
]])

local mv_shader = love.graphics.newShader([[
    uniform float seed;
    uniform Image x_image;

	float rand(vec2 n, float s){
		return fract(sin(dot(n + s, vec2(12.9898, 4.1414))) * 43758.5453);
	}

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords){
        float e = -0.6;

        vec4 x = Texel(x_image, texture_coords);
        float phi1 = x[0];
        float phi2 = x[1];
        float I1 = x[2];
        float I2 = x[3];

        vec4 v;
        v[0] = rand(texture_coords, seed);
        v[1] = rand(texture_coords, seed+0.58448844);
        v[2] = rand(texture_coords, seed+0.38406795);
        v[3] = rand(texture_coords, seed+0.78849948);
        v = normalize(v);

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

        float nv = log(length(J*v));
        float mv = Texel(texture, texture_coords)[0];
		return vec4(max(mv,nv), 0.0, 0.0, 0.0);
	}
]])

local display_shader = love.graphics.newShader([[
    uniform float a;
    uniform float b;

	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
	{
        float x = texture_coords[0];
        float y = 1.0 - texture_coords[1];
        float mv = Texel(texture, vec2(x,y))[0];

        float c = a*mv-b;
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

local mv = {}
mv[1] = love.graphics.newCanvas(nw, nh, {format="r32f"})
mv[2] = love.graphics.newCanvas(nw, nh, {format="r32f"})

local a = 1
local b = 1
function love.update(dt)
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
    mv_shader:send("seed", love.math.random())
    
    if love.keyboard.isDown("left") then a = a - .1*dt end
    if love.keyboard.isDown("right") then a = a + .1*dt end
    if love.keyboard.isDown("up") then b = b - .1*dt end
    if love.keyboard.isDown("down") then b = b + .1*dt end
    display_shader:send("a", a)
    display_shader:send("b", b)
    print(a, b)
end

function love.draw()
    love.graphics.setShader(x_shader)
    love.graphics.setCanvas(x[current])
    love.graphics.draw(x[3-current])

    love.graphics.setShader(mv_shader)
    love.graphics.setCanvas(mv[current])
    mv_shader:send("x_image", x[3-current])
    love.graphics.draw(mv[3-current])

    love.graphics.setShader(display_shader)
    love.graphics.setCanvas()
    love.graphics.draw(mv[current])

    current = 3-current
end