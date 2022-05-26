//
//  Shaders.metal
//  metalLearning
//
//  Created by 李凯翔 on 2022/3/4.
//

#include <metal_stdlib>
using namespace metal;

struct Uniforms{
    float4x4 modelMatrix;
    float4x4 projectionMatrix;
};

struct VertexIn{
    packed_float3 position;
    packed_float4 color;
    packed_float2 texCoord;
};

struct VertexOut{
    float4 position [[position]];
    float4 color;
    float2 texCoord;
};

vertex VertexOut basic_vertex(
    const device VertexIn* vertex_array [[buffer(0)]],
    unsigned int vid [[vertex_id]]){
    VertexIn VertexIn = vertex_array[vid];
    VertexOut VertexOut;
    VertexOut.position = float4(VertexIn.position,1);
    VertexOut.color = VertexIn.color;
    VertexOut.texCoord = VertexIn.texCoord;
    
    
    return VertexOut;
}

vertex VertexOut texture_vertex(
    const device VertexIn* vertex_array [[buffer(0)]],
    const device Uniforms& uniforms     [[buffer(1)]],
    unsigned int vid [[vertex_id]]){
    
    float4x4 mv_Matrix = uniforms.modelMatrix;
    float4x4 proj_Matrix = uniforms.projectionMatrix;
    VertexIn VertexIn = vertex_array[vid];
    
    VertexOut VertexOut;
    VertexOut.position = proj_Matrix * mv_Matrix * float4(VertexIn.position,1);
    VertexOut.color = VertexIn.color;
    VertexOut.texCoord = VertexIn.texCoord;
    
    return VertexOut;
}

fragment float4 basic_fragment(VertexOut interpolated [[stage_in]],
                              texture2d<float> frontFace [[texture(0)]],
                               texture2d<float> backFace [[texture(1)]],
                               texture3d<float> image3d [[texture(2)]],
                              sampler sampler2D [[sampler(0)]])
{
//    sampler samplerFor2D = sampler(filter::linear);
    float3 In = frontFace.sample(sampler2D, interpolated.texCoord).xyz;
    float3 Out = backFace.sample(sampler2D, interpolated.texCoord).xyz;
    if ( In[0] == Out[0] && In[1] == Out[1] && In[2] == Out[2]){
            discard_fragment();
    }
    
    float3 ray = In - Out;
    float ray_length = length(ray);
    float step = 200;
    float ray_step = ray_length/step;
//    float3 ray_step_vec = ray/step;
    float3 ray_step_vec = float3(ray.x/step,ray.y/step,ray.z/(step));
    
    float3 ray_start = In;
//    float3 ray_end = Out;
    float3 currentPosi = ray_start;

    sampler simpleSimpler = sampler(filter::linear,address::clamp_to_edge);
    float maxIntensity = 0;

    while(ray_length > 0){
        float greyScale = image3d.sample(simpleSimpler,currentPosi).x;
        if(greyScale > maxIntensity){
            maxIntensity = greyScale;
        }
        ray_length -= ray_step;
        currentPosi -= ray_step_vec;
    }

    return float4(maxIntensity,maxIntensity,maxIntensity,1.0);
    
}

fragment float4 basic_fragment_sharpen(VertexOut interpolated [[stage_in]],
                              texture2d<float> frontFace [[texture(0)]],
                               texture2d<float> backFace [[texture(1)]],
                               texture3d<float> image3d [[texture(2)]],
                              sampler sampler2D [[sampler(0)]])
{
    float3 In = frontFace.sample(sampler2D, interpolated.texCoord).xyz;
    float3 Out = backFace.sample(sampler2D, interpolated.texCoord).xyz;
    if ( In[0] == Out[0] && In[1] == Out[1] && In[2] == Out[2]){
            discard_fragment();
    }
    
    float3 ray = In - Out;
    float ray_length = length(ray);
    float step = 200;
    float ray_step = ray_length/step;
    float3 ray_step_vec = float3(ray.x/step,ray.y/step,ray.z/(step));
    
    float3 ray_start = In;
//    float3 ray_end = Out;
    float3 currentPosi = ray_start;

    sampler simpleSimpler = sampler(mag_filter::linear,min_filter::linear);
    float maxIntensity = 0;

    while(ray_length > 0){
        float greyScale = image3d.sample(simpleSimpler,currentPosi).x;
//        greyScale = greyScale/255.0;
        if (greyScale <= 0.3){
            greyScale = greyScale*2;
        }else{
            greyScale = greyScale*6;
        }
        if(greyScale > maxIntensity){
            maxIntensity = greyScale;
        }
        ray_length -= ray_step;
        currentPosi -= ray_step_vec;
    }

    return float4(maxIntensity,maxIntensity,maxIntensity,1.0);
    
}

fragment float4 texture_fragment(VertexOut interpolated [[stage_in]])
{
    return interpolated.color;
}
