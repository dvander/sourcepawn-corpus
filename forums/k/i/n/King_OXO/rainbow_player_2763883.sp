#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int g_iLight[MAXPLAYERS+1];

ConVar g_hRainbowTime;

public Plugin myinfo =
{
	name = "[L4D2] Rainbow Flashlight",
	author = "King",
	description = "Set Rainbow To flashlight",
	version = "1.1.0",
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
    g_hRainbowTime = CreateConVar("rainbow_time", "3.0", "time for aura and body change");
	
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_end", Event_RE);

    RegAdminCmd("sm_arco", Command_Rainbow, ADMFLAG_ROOT, "make rainbow light_dynamic");
    RegAdminCmd("sm_arcoff", Command_RainbowOff, ADMFLAG_ROOT, "kill rainbow light_dynamic");
	
	AutoExecConfig(true, "rainbow_light");
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	RemoveNeon(GetClientOfUserId(event.GetInt("userid")));
}

public Action Event_RE(Event event, const char[] name, bool dontBroadcast)
{
	RemoveNeon(GetClientOfUserId(event.GetInt("userid")));
}

public void OnClientDisconnect(int iClient)
{
	g_iLight[iClient] = 0;
}

public Action Command_Rainbow(int client, int args)
{
    SetClientNeon(client);
}

public Action Command_RainbowOff(int client, int args)
{
    RemoveNeon(client);
}

int SetClientNeon(int iClient)
{
	RemoveNeon(iClient);

	g_iLight[iClient] = CreateEntityByName("light_dynamic");
	DispatchKeyValue(g_iLight[iClient], "brightness", "2");
	float fOrigin[3];
	GetClientAbsOrigin(iClient, fOrigin);
	DispatchKeyValue(g_iLight[iClient], "spotlight_radius", "32.0");
	DispatchKeyValue(g_iLight[iClient], "distance", "255.0");
	DispatchKeyValue(g_iLight[iClient], "style", "0");
	SetEntPropEnt(g_iLight[iClient], Prop_Send, "m_hOwnerEntity", iClient);
	SDKHook(iClient, SDKHook_PreThinkPost, OnRainbowPlayer);
	if(DispatchSpawn(g_iLight[iClient]))
	{
		AcceptEntityInput(g_iLight[iClient], "TurnOn");
		TeleportEntity(g_iLight[iClient], fOrigin, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("!activator");
		AcceptEntityInput(g_iLight[iClient], "SetParent", iClient, g_iLight[iClient], 0);

		SDKHook(g_iLight[iClient], SDKHook_SetTransmit, OnTransmit);
		
		return;
	}
	
	g_iLight[iClient] = 0;
}

void RemoveNeon(int iClient)
{
	if(g_iLight[iClient] && IsValidEdict(g_iLight[iClient]))
	{
		AcceptEntityInput(g_iLight[iClient], "TurnOff"); 
		AcceptEntityInput(g_iLight[iClient], "Kill");
		SetEntProp(iClient, Prop_Send, "m_glowColorOverride", 0); 
		SetEntProp(iClient, Prop_Send, "m_iGlowType", 0);
		SetEntProp(iClient, Prop_Send, "m_nGlowRange", 0);
		SetEntProp(iClient, Prop_Send, "m_nGlowRangeMin", 0);
		SetEntityRenderColor(iClient, 255, 255, 255, 255);
		
		SDKUnhook(iClient, SDKHook_PreThinkPost, OnRainbowPlayer);
	}

	g_iLight[iClient] = 0;
}

public Action OnTransmit(int iEntity, int iClient)
{
	if (g_iLight[iClient] == iEntity)
	{
		return Plugin_Continue;
	}

	static int iOwner, iTeam;

	if ((iOwner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity")) > 0 &&
		(iTeam = GetClientTeam(iClient)) > 1
		&& GetClientTeam(iOwner) != iTeam)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action OnRainbowPlayer(int iClient)
{
	if (!(0 < iClient <= MaxClients && IsClientInGame(iClient) && IsPlayerAlive(iClient)))
	{
		SDKUnhook(iClient, SDKHook_PreThinkPost, OnRainbowPlayer);

		return Plugin_Continue;
	}
	
	float flRainbow = g_hRainbowTime.FloatValue;

	int color[3];
	color[0] = RoundToNearest((Cosine((GetGameTime() * flRainbow) + iClient + 0) * 80) + 80);
	color[1] = RoundToNearest((Cosine((GetGameTime() * flRainbow) + iClient + 2) * 80) + 80);
	color[2] = RoundToNearest((Cosine((GetGameTime() * flRainbow) + iClient + 4) * 80) + 80);
	
	//Light Color
	char sBuffer[16];
	FormatEx(sBuffer, sizeof(sBuffer), "%i %i %i %i", GetRandomColor(color[2]), GetRandomColor(color[1]), GetRandomColor(color[0]), 255);
	DispatchKeyValue(g_iLight[iClient], "_light", sBuffer);
	
	//GLow Color
	SetEntProp(iClient, Prop_Send, "m_glowColorOverride", color[2] + (color[1] * 256) + (color[0] * 65536));
	SetEntProp(iClient, Prop_Send, "m_iGlowType", 3);
	SetEntProp(iClient, Prop_Send, "m_nGlowRange", 99999);
	SetEntProp(iClient, Prop_Send, "m_nGlowRangeMin", 0);
	
	//Player Color
	SetEntityRenderColor(iClient, color[2], color[1], color[0], 255);

	return Plugin_Continue;
}

stock int GetRandomColor(int color)
{
	return (color == -1 || color < 0 || color > 255) ? GetRandomInt(0, 255) : color;
}