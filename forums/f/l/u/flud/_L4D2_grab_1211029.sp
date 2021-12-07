#include <sourcemod>
#include <sdktools>

new g_aim_target[MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "GrabE",
	author = "FluD",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	RegConsoleCmd("+grab", Command_catch, "grab start");
	RegConsoleCmd("-grab", Command_release, "grab stop");
}

public Action:Command_catch(client, args)
{
	g_aim_target[client] = GetClientAimTarget(client, false);

	if (!IsValidEntity (g_aim_target[client]))
	{
		PrintToChat(client, "[SM] Not a valid entity.");
		return Plugin_Handled;
	}

	decl String:m_ModelName[255];
	GetEntPropString(g_aim_target[client], Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));

	PrintToChat(client, "you catch [%s] [%i]",m_ModelName, g_aim_target[client]);
	SetParent(client, g_aim_target[client]);
	return Plugin_Continue;
}

public Action:Command_release(client, args)
{
	RemoveParent(g_aim_target[client]);
}

RemoveParent(entity)
{
	if(IsValidEntity(entity))
	{
		decl Float:origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
		SetVariantString("");
		AcceptEntityInput(entity, "SetParent", -1, -1, 0);

		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
	}
}

bool:SetParent(client, entity)
{
	if(IsValidEntity(entity) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		RemoveParent(entity);
		new String:steamid[20];
		GetClientAuthString(client, steamid, sizeof(steamid));
		DispatchKeyValue(client, "targetname", steamid);
		SetVariantString(steamid);
		AcceptEntityInput(entity, "SetParent", -1, -1, 0);
		return true;
	}
	return false;
}
