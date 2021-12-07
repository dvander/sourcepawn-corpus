#include <sourcemod>
#include <sdktools>

#pragma semicolon 1;

public Plugin myinfo = 
{
	name = "Soldier Tribute Statue Spawner",
	author = "Mr.Skullbeef, Derek D. Howard (ddhoward), Sappykun",
	description = "Spawns a Soldier Tribute statue where you are looking",
	version = "1.1",
	url = "https://skufs.net/"
}

public void OnPluginStart() {
	RegAdminCmd("sm_rickstatue", SpawnRickStatue, ADMFLAG_ROOT, "Spawns a Rick May tribute statue");	
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

public Action SpawnRickStatue(int client, int args) {
	if (client == -1) return Plugin_Handled;
	
	float position[3];
	float angle[3];
	
	GetAimCoords(client, position, angle);
	
	// Rotate the statue to face the player
	GetClientEyeAngles(client, angle);
	angle[0] = 0.0;
	angle[1] += 180.0;
	angle[2] = 0.0;

	int ent = CreateEntityByName("entity_soldier_statue");
	DispatchSpawn(ent);
	TeleportEntity(ent, position, angle, NULL_VECTOR);
	
	ReplyToCommand(client, "Pos: %.3f %.3f %.3f Angle: 0 %.5f 0", position[0], position[1], position[2], angle[1]);
	return Plugin_Handled;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask) {
	return (entity > MaxClients || entity < 1);
}

public void GetAimCoords(int client, float position[3], float angle[3]) {
	float vAngles[3];
	float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace)) {   	 
		TR_GetEndPosition(position, trace);
	}
	trace.Close();
}
