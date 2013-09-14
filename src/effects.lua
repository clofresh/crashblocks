effect = love.graphics.newPixelEffect [[
extern number radius;
extern vec2 imageSize;
extern vec2 direction;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 pc)
{
   color = vec4(0);
   vec2 st;
   vec2 pixdir = direction / imageSize;
   for (float i = -radius; i <= radius; i++) {
      st.xy = i * pixdir;
      color += Texel(tex, tc + st);
   }
   return color / (2.0 * radius + 1.0);
}
]]
