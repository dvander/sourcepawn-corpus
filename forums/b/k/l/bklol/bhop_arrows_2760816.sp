#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "boomix"
#define PLUGIN_VERSION "1.02"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#pragma newdecls required

#define ARROW_MODEL "models/props/de_nuke/hr_nuke/signs/sign_arrow_001.mdl"
#define FSOLID_NOT_SOLID 0x0004 

Handle g_hHide;
bool g_bHide[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Bhop arrows",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	RegConsoleCmd("sm_arrows", Command_Arrows);
	
	g_hHide = RegClientCookie("Hide Arrows", "Hide info_teleport_destination arrows", CookieAccess_Public);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, g_hHide, sValue, sizeof(sValue));
	
	if(sValue[0])
	{
		g_bHide[client] = !!StringToInt(sValue);
	}
}

public Action Command_Arrows(int client, int args)
{
	g_bHide[client] = !g_bHide[client];
	char sValue[8];
	IntToString(g_bHide[client], sValue, sizeof(sValue));
	SetClientCookie(client, g_hHide, sValue);
	PrintToChat(client, " \x04[Arrows]\x01 You have %s arrows!", g_bHide[client] ? "\x07disabled\x01":"\x05enabled\x01");
	return Plugin_Handled;
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	//Check if arrows are spawned yet
	int entity;
	char targetname[120];
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
    {
    	GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
    	if (StrEqual(targetname, "Arrow"))
    		return Plugin_Continue;
    }
	
	//Spawn arrows
	while ((entity = FindEntityByClassname(entity, "info_teleport_destination")) != -1)
    {

		float pos[3], ang2[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", ang2);

		int prop = CreateEntityByName("prop_dynamic");
		if(prop > MaxClients)
		{
			DispatchKeyValue(prop, "model", ARROW_MODEL);
			DispatchKeyValue(prop, "targetname", "Arrow");
			DispatchKeyValue(prop, "Solid", "0");
			DispatchKeyValueFloat(prop, "modelscale", 3.0); 
			DispatchSpawn(prop);

			SetEntProp(prop, Prop_Send, "m_bShouldGlow", true, true);
			SetEntProp(prop, Prop_Send, "m_nGlowStyle", 2);
			SetEntPropFloat(prop, Prop_Send, "m_flGlowMaxDist", 10000000.0);
			
			SetEntProp(prop, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);
			
			float ang[3];
			ang[1] = ang2[1];
			ang[2] = ang2[2] + 90.0;
			ang[0] -= 90.0;
			
			//Get ground
			float ang3[3];
			ang3[0] = 90.0;
			
			float fGround[3];
			TR_TraceRayFilter(pos, ang3, MASK_PLAYERSOLID, RayType_Infinite, TraceRayNoPlayers, prop);
			if (TR_DidHit())
			{
				TR_GetEndPosition(fGround);
				TeleportEntity(prop, fGround, ang, NULL_VECTOR);
			}
			
			SDKHook(prop, SDKHook_SetTransmit, SetTransmit);
		}
    }
    
	return Plugin_Continue;
}

public Action SetTransmit(int entity, int client)
{
	if(g_bHide[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnMapStart()
{
	PrecacheModel(ARROW_MODEL);
}

public bool TraceRayNoPlayers(int entity, int mask, any data)
{
	if(entity == data || (entity >= 1 && entity <= MaxClients && !g_bHide[entity]))
	{
    	return false;
	}
	return true;
} 