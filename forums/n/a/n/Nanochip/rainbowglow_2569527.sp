#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#pragma newdecls required

int g_iPlayerGlowEntity[MAXPLAYERS + 1];

ConVar g_hRainbowCycleRate;

Handle cookie;
bool Glow[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[TF2] Rainbow Glow",
	author = "Pelipoika",
	description = "",
	version = "1.0",
	url = "http://www.sourcemod.net/plugins.php?author=Pelipoika&search=1"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_rainbowme", Command_Rainbow, ADMFLAG_RESERVATION);
	
	cookie = RegClientCookie("sm_rainbowme_cookie", "", CookieAccess_Private);
	
	HookEvent("player_spawn", OnPlayerSpawn);
	
	g_hRainbowCycleRate = CreateConVar("sm_rainbow_cycle_rate", "1.0", "Constrols the speed of which the rainbow glow changes color");
}

public void OnPluginEnd()
{
	int index = -1;
	while ((index = FindEntityByClassname(index, "tf_glow")) != -1)
	{
		char strName[64];
		GetEntPropString(index, Prop_Data, "m_iName", strName, sizeof(strName));
		if(StrEqual(strName, "RainbowGlow"))
		{
			AcceptEntityInput(index, "Kill");
		}
	}
}

public void OnClientConnected(int client)
{
	Glow[client] = false;
}

public void OnClientCookiesCached(int client)
{
	char info[16];
	GetClientCookie(client, cookie, info, sizeof(info));
	if (StrEqual(info, "true")) Glow[client] = true;
}

public Action OnPlayerSpawn(Event event, char[] strEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!CheckCommandAccess(client, "sm_rainbowme", ADMFLAG_RESERVATION) && Glow[client])
	{
		Glow[client] = false;
	}
	if (Glow[client])
	{
		int iGlow = TF2_CreateGlow(client);
		if(IsValidEntity(iGlow))
		{
			g_iPlayerGlowEntity[client] = EntIndexToEntRef(iGlow);
			SDKHook(client, SDKHook_PreThink, OnPlayerThink);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (Glow[client])
	{
		int iGlow = EntRefToEntIndex(g_iPlayerGlowEntity[client]);
		if(iGlow != INVALID_ENT_REFERENCE)
		{
			AcceptEntityInput(iGlow, "Kill");
			g_iPlayerGlowEntity[client] = INVALID_ENT_REFERENCE;
			SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
		}
		Glow[client] = false;
	}
}

public Action Command_Rainbow(int client, int argc)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if(!Glow[client])
		{	
			int iGlow = TF2_CreateGlow(client);
			if(IsValidEntity(iGlow))
			{
				g_iPlayerGlowEntity[client] = EntIndexToEntRef(iGlow);
				SDKHook(client, SDKHook_PreThink, OnPlayerThink);
				Glow[client] = true;
				SetClientCookie(client, cookie, "true");
				ReplyToCommand(client, "[SM] You are now glowing!");
			}
		}
		else
		{
			int iGlow = EntRefToEntIndex(g_iPlayerGlowEntity[client]);
			if(iGlow != INVALID_ENT_REFERENCE)
			{
				AcceptEntityInput(iGlow, "Kill");
				g_iPlayerGlowEntity[client] = INVALID_ENT_REFERENCE;
				SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
				Glow[client] = false;
				SetClientCookie(client, cookie, "false");
				ReplyToCommand(client, "[SM] You are no longer glowing.")
			}
		}
	}

	return Plugin_Handled;
}

public Action OnPlayerThink(int client)
{
	int iGlow = EntRefToEntIndex(g_iPlayerGlowEntity[client]);
	if(iGlow != INVALID_ENT_REFERENCE)
	{
		float flRate = g_hRainbowCycleRate.FloatValue;
		
		int color[4];
		color[0] = RoundToNearest(Cosine((GetGameTime() * flRate) + client + 0) * 127.5 + 127.5);
		color[1] = RoundToNearest(Cosine((GetGameTime() * flRate) + client + 2) * 127.5 + 127.5);
		color[2] = RoundToNearest(Cosine((GetGameTime() * flRate) + client + 4) * 127.5 + 127.5);
		color[3] = 255;
		
		SetVariantColor(color);
		AcceptEntityInput(iGlow, "SetGlowColor");
	}
}

stock int TF2_CreateGlow(int iEnt)
{
	char oldEntName[64];
	GetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName, sizeof(oldEntName));

	char strName[126], strClass[64];
	GetEntityClassname(iEnt, strClass, sizeof(strClass));
	Format(strName, sizeof(strName), "%s%i", strClass, iEnt);
	DispatchKeyValue(iEnt, "targetname", strName);
	
	int ent = CreateEntityByName("tf_glow");
	DispatchKeyValue(ent, "targetname", "RainbowGlow");
	DispatchKeyValue(ent, "target", strName);
	DispatchKeyValue(ent, "Mode", "0");
	DispatchSpawn(ent);
	
	AcceptEntityInput(ent, "Enable");
	
	//Change name back to old name because we don't need it anymore.
	SetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName);

	return ent;
}