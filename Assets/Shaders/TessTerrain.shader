// https://catlikecoding.com/unity/tutorials/advanced-rendering/tessellation/
Shader "Custom/TessTerrain"
{
    Properties
    {
        _HeightMap ("Height Map", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }  
        LOD 100

        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex tessvert
            #pragma fragment frag
            #pragma hull hs // hull or tessellation control shader
            #pragma domain ds // domain or tessellation evaluation shader
            #pragma target 4.6

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct VertexData
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            struct TessellationFactors
            {
                float edge[4] : SV_TessFactor;
                float inside[2] : SV_InsideTessFactor;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float height : TEXCOORD0;
            };

            Texture2D _HeightMap;
            SamplerState sampler_HeightMap;
            float4 _HeightMap_ST;

            VertexData tessvert (appdata v)
            {
                VertexData o;
                o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _HeightMap);
                return o;
            }

            TessellationFactors hsconst(InputPatch<VertexData, 4> patch)
            {
                const int MIN_TESS_LEVEL = 4;
                const int MAX_TESS_LEVEL = 64;
                const float MIN_DISTANCE = 20;
                const float MAX_DISTANCE = 800;

                float3 eyeSpacePos00 = UnityObjectToViewPos(patch[0].vertex);
                float3 eyeSpacePos01 = UnityObjectToViewPos(patch[1].vertex);
                float3 eyeSpacePos11 = UnityObjectToViewPos(patch[2].vertex);
                float3 eyeSpacePos10 = UnityObjectToViewPos(patch[3].vertex);

                float distance00 = saturate((abs(eyeSpacePos00.z) - MIN_DISTANCE) / (MAX_DISTANCE - MIN_DISTANCE));
                float distance01 = saturate((abs(eyeSpacePos01.z) - MIN_DISTANCE) / (MAX_DISTANCE - MIN_DISTANCE));
                float distance11 = saturate((abs(eyeSpacePos11.z) - MIN_DISTANCE) / (MAX_DISTANCE - MIN_DISTANCE));
                float distance10 = saturate((abs(eyeSpacePos10.z) - MIN_DISTANCE) / (MAX_DISTANCE - MIN_DISTANCE));

                float tessLevel0 = lerp(MAX_TESS_LEVEL, MIN_TESS_LEVEL, min(distance00, distance01));
                float tessLevel1 = lerp(MAX_TESS_LEVEL, MIN_TESS_LEVEL, min(distance00, distance10));
                float tessLevel2 = lerp(MAX_TESS_LEVEL, MIN_TESS_LEVEL, min(distance10, distance00));
                float tessLevel3 = lerp(MAX_TESS_LEVEL, MIN_TESS_LEVEL, min(distance11, distance00));

                TessellationFactors f;
                f.edge[0] = tessLevel0;
                f.edge[1] = tessLevel1;  
                f.edge[2] = tessLevel2;
                f.edge[3] = tessLevel3;
                f.inside[0] = max(tessLevel1, tessLevel3);
                f.inside[1] = max(tessLevel0, tessLevel2);
                return f;
            }

            // Hull program
            // param: patch is a collection of mesh vertices
            [UNITY_domain("quad")]
            [UNITY_partitioning("fractional_odd")]
            [UNITY_outputtopology("triangle_ccw")]
            [UNITY_patchconstantfunc("hsconst")]
            [UNITY_outputcontrolpoints(4)]
            VertexData hs (InputPatch<VertexData, 4> patch, uint id : SV_OutputControlPointID)
            {
                return patch[id];
            }

            [UNITY_domain("quad")]
            v2f ds (TessellationFactors factors, OutputPatch<VertexData, 4> patch,
                    float2 tessCoord : SV_DomainLocation)
            {
                float u = tessCoord.x;
                float v = tessCoord.y;

                float2 t00 = patch[0].uv;
                float2 t01 = patch[1].uv;
                float2 t11 = patch[2].uv;
                float2 t10 = patch[3].uv;

                float2 texCoord = t00 + (t10 - t00) * u + (t01 - t00) * v;

                float height = _HeightMap.SampleLevel(sampler_HeightMap, texCoord, 0).y * 64.0 - 16.0;

                float4 p00 = patch[0].vertex;
                float4 p01 = patch[1].vertex;
                float4 p11 = patch[2].vertex;
                float4 p10 = patch[3].vertex;

                float4 uVec = p10 - p00;
                float4 vVec = p01 - p00;
                float4 normal = normalize(float4(cross(vVec.xyz, uVec.xyz), 0));

                float4 p = p00 + uVec * u + vVec * v;
                p += normal * height;

                v2f o;
                o.vertex = UnityObjectToClipPos(p);
                o.height = height;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float h = (i.height + 16) / 64.0;
                fixed4 col = fixed4(h, h, h, 1.0);
                return col;
            }
            ENDHLSL
        }
    }
}
