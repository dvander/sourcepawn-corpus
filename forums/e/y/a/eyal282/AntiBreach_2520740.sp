#include <sourcemod>

#pragma newdecls required

bool g_bNoSpam[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "No spawn near safe room door.",
	author = "Eyal282",
	description = "To prevent a player breaching safe room door with a bug, prevents him from spawning near safe room door. The minimum distance is proportionate to his speed ",
	version = "1.4",
	url = "https://forums.alliedmods.net/showthread.php?p=2520740"
}

ConVar g_hEnabled;

public void OnPluginStart()
{
	// The cvar to enable the plugin. 0 = Disabled. Other values = Enabled.
	g_hEnabled = CreateConVar("l4d2_anti_breach", "1");
}

public void OnClientPutInServer(int client)
{
	g_bNoSpam[client] = false;
}

public Action L4D_OnMaterializeFromGhostPre(int client)
{
	if(!g_hEnabled.BoolValue)
		return Plugin_Continue;

	else if(IsFakeClient(client))
		return Plugin_Continue;

	int count = GetEntityCount();

	for(int entity = MaxClients; entity < count; entity++) // https://forums.alliedmods.net/showpost.php?p=2502446&postcount=2
	{
		if(!IsValidEntity(entity) || !IsValidEdict(entity))
			continue;
	
		char sClassname[64];
		GetEdictClassname(entity, sClassname, sizeof(sClassname));
		
		if(strcmp(sClassname, "prop_door_rotating_checkpoint") != 0) // Found the classname from l4d_loading: https://forums.alliedmods.net/showthread.php?p=836849
			continue;
			
		float fOrigin[3], fVelocity[3], fDoorOrigin[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", fOrigin);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", fDoorOrigin);

		float fSpeed = GetVectorLength(fVelocity);
		float fDist = GetVectorDistance(fOrigin, fDoorOrigin);
		
		// Player has too much speed vs distance from door.
		
		if(fDist < fSpeed / 1.5) // Tested and the 1.5 division will not assist the use of the bug.
		{
			if(!g_bNoSpam[client])
			{
				PrintToChat(client, "You can't spawn near safe room doors.");
				g_bNoSpam[client] = true;
				CreateTimer(2.5, AllowMessageAgain, GetClientUserId(client));
			}
			
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action AllowMessageAgain(Handle Timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsClientInGame(client))
		return Plugin_Continue;
	
	g_bNoSpam[client] = false;
	
	return Plugin_Continue;
}