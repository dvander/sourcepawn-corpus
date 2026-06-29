#include <sourcemod>

public Plugin:myinfo = 
{
	name = "No round start collision",
	author = "SmartPlay",
	description = "Removes player collisions on round start.",
	version = "1.0.0.0",
	url = "http://www.mkdclan.info"
};

new g_offsCollisionGroup;
new bool:g_isHooked;
new Handle:ds_nocollision;
new Handle:ds_spawntime;
new Handle:GlobalTimer[MAXPLAYERS+1] = INVALID_HANDLE;

public OnPluginStart()
{
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (g_offsCollisionGroup == -1)
	{
		g_isHooked = false;
		PrintToServer("* FATAL ERROR: Failed to get offset for CBaseEntity::m_CollisionGroup");
	}
	else
	{
		g_isHooked = true;
		HookEvent("round_start", OnRoundStart);
		ds_nocollision = CreateConVar("ds_nocollision", "1", "Removes player collisions on round start.", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
		ds_spawntime = CreateConVar("ds_spawntime", "20", "number in seconds with no collision after round start.");
		HookConVarChange(ds_nocollision, OnConVarChange);
	}
}

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new value = !!StringToInt(newValue);
	if (value == 0)
	{
		if (g_isHooked == true)
		{
			g_isHooked = false;
			UnhookEvent("round_start", OnRoundStart);
		}
	}
	else
	{
		g_isHooked = true;
		HookEvent("round_start", OnRoundStart);
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(IsValidEntity(client) && IsClientConnected(client))
		{
			SetEntData(client, g_offsCollisionGroup, 2, 4, true);
			if (GlobalTimer[client] != INVALID_HANDLE)
				CloseHandle(GlobalTimer[client]);
			GlobalTimer[client] = CreateTimer(GetConVarFloat(ds_spawntime), Blocker, client);
		}
	}	
}

public Action:Blocker(Handle:timer, any:client)
{
	if(IsValidEntity(client) && IsClientConnected(client))
	{
		SetEntData(client, g_offsCollisionGroup, 5, 4, true);		
		GlobalTimer[client] = INVALID_HANDLE;
	}
	return Plugin_Continue;
}