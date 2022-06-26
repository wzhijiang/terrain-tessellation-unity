using System;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class TessTerrain : MonoBehaviour
{
    public Texture2D heightmap;

    private void Start()
    {
        Mesh mesh = SetupMesh(20, heightmap.width, heightmap.height);

        var meshFilter = GetComponent<MeshFilter>();
        meshFilter.mesh = mesh;
    }

    Mesh SetupMesh(int rez, int width, int height)
    {
        if (rez < 1)
        {
            throw new ArgumentException("rez should be greater than or equal to 1");
        }

        List<Vector3> vertices = new List<Vector3>();
        List<Vector2> uvs = new List<Vector2>();
        for (int i = 0; i <= rez; i++)
        {
            for (int j = 0; j <= rez; j++)
            {
                Vector3 vertex = new Vector3();
                vertex.x = -width / 2.0f + width * i / (float)rez;
                vertex.y = 0.0f;
                vertex.z = -height / 2.0f + height * j / (float)rez;
                vertices.Add(vertex);

                Vector2 uv = new Vector2();
                uv.x = i / (float)rez;
                uv.y = j / (float)rez;
                uvs.Add(uv);
            }
        }

        int numHVerts = rez + 1;
        List<int> indices = new List<int>();
        for (int i = 0; i < rez; i++)
        {
            for (int j = 0; j < rez; j++)
            {
                // (i,j+1)    (i+1,j+1)  
                //   +----------+        ^ z
                //   |          |        |
                //   |          |        o--> x
                //   +----------+
                // (i,j)     (i+1,j)

                // Winding order: CW
                indices.Add(i * numHVerts + j);
                indices.Add(i * numHVerts + (j + 1));
                indices.Add((i + 1) * numHVerts + (j + 1));
                indices.Add((i + 1) * numHVerts + j);
                //indices.Add(i * numHVerts + j);
                //indices.Add((i + 1) * numHVerts + (j + 1)); 
            }
        }

        Mesh mesh = new Mesh();
        mesh.vertices = vertices.ToArray();
        mesh.uv = uvs.ToArray();
        mesh.SetIndices(indices.ToArray(), MeshTopology.Quads, 0);
        return mesh;
    }
}
