{{GLSL_VERSION}}
out vec4 FragColor;

uniform sampler3D Density;

uniform vec3 LightPosition = vec3(1.0, 1.0, 2.0);
uniform vec3 LightIntensity = vec3(10.0);
uniform float Absorption = 10.0;
uniform mat4 Modelview;
uniform float FocalLength;
uniform vec2 WindowSize;
uniform vec3 RayOrigin;
uniform vec3 Ambient = vec3(0.15, 0.15, 0.20);
const int ViewSamples = 128;


const float maxDist = sqrt(2.0);
const int numSamples = 128;
const float StepSize = maxDist/float(numSamples);
const int numLightSamples = 32;
const float lscale = maxDist / float(numLightSamples);
const float densityFactor = 5;

const bool Jitter = false;
{{in}} vec3 frag_vert;
float GetDensity(vec3 pos)
{
    return texture(Density, pos).x;
}

struct Ray {
    vec3 Origin;
    vec3 Dir;
};

struct AABB {
    vec3 Min;
    vec3 Max;
};

bool IntersectBox(Ray r, AABB aabb, out float t0, out float t1)
{
    vec3 invR = 1.0 / r.Dir;
    vec3 tbot = invR * (aabb.Min-r.Origin);
    vec3 ttop = invR * (aabb.Max-r.Origin);
    vec3 tmin = min(ttop, tbot);
    vec3 tmax = max(ttop, tbot);
    vec2 t = max(tmin.xx, tmin.yz);
    t0 = max(t.x, t.y);
    t = min(tmax.xx, tmax.yz);
    t1 = min(t.x, t.y);
    return t0 <= t1;
}


void main()
{

    FragColor.rgb = frag_vert;
    FragColor.a = 1;
}
