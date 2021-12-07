#include <sourcemod>
#include <sdktools>

#pragma semicolon 1;

public Plugin myinfo =
{
	name = "Soldier Tribute Statue Spawner",
	author = "Mr.Skullbeef",
	description = "Spawns a Soldier Tribute statue",
	version = "1.0",
	url = "https://skufs.net/"
}

public void OnMapStart()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/rick_statue.txt");
	KeyValues kv = new KeyValues("RickStatue");

	if (kv.ImportFromFile(path))
	{
		char currentMap[128];
		GetCurrentMap(currentMap, sizeof(currentMap));
		if (!kv.JumpToKey(currentMap))
		{
			delete kv;
			LogError("Error in %s: File not found, corrupt or in the wrong format", path);
			return;
		}
		
		float origin[3];
		origin[0] = kv.GetFloat("x_origin");
		origin[1] = kv.GetFloat("y_origin");
		origin[2] = kv.GetFloat("z_origin");
		float angle[3];
		angle[0] = kv.GetFloat("x_angle");
		angle[1] = kv.GetFloat("y_angle");
		angle[2] = kv.GetFloat("z_angle");

		int ent = CreateEntityByName("entity_soldier_statue");
		DispatchSpawn(ent);
		TeleportEntity(ent, origin, angle, NULL_VECTOR);
	}
	else
	{
		LogError("Error in %s: File not found, corrupt or in the wrong format", path);
	}

	delete kv;
}
