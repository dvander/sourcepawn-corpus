#include <sdktools>

public void OnClientPutInServer(int client)
{
	if(IsClientSourceTV(client))
	{
		char map[64];
		GetCurrentMap(map, sizeof(map));
		Format(map, sizeof(map), "[MAP] %s", map);
		SetClientName(client, map);
	}
}