#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <geoip>

#define PLUGIN_NAME 	"Country Clan Tags"
#define PLUGIN_VERSION 	"1.2.0"

#define SIZEOF_BOTTAG 	4

new Handle:g_hTagMethod = INVALID_HANDLE;
new Handle:g_hTagLen = INVALID_HANDLE;
new Handle:g_hBotTags = INVALID_HANDLE;
new Handle:g_aryBotTags = INVALID_HANDLE;
new String:g_sCountryTag[MAXPLAYERS+1][6];
new bool:g_bLateLoad = false;
new g_iTagMethod, g_iTagLen;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony",
	description = "Assigns clan tags based on the player's country",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_countrytags_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hTagMethod = CreateConVar("sm_countrytags", "1", "Determines plugin functionality. (0 = Disabled, 1 = Tag all players, 2 = Tag tagless players)", FCVAR_NONE, true, 0.0, true, 2.0);
	g_hTagLen = CreateConVar("sm_countrytags_length", "3", "Country code length. (2 = CA,US,etc. 3 = CAN,USA,etc.)", FCVAR_NONE, true, 2.0, true, 3.0);
	g_hBotTags = CreateConVar("sm_countrytags_bots", "CAN,USA", "Tags to assign bots. Separate tags by commas.", FCVAR_NONE);
	
	g_iTagMethod = GetConVarInt(g_hTagMethod);
	g_iTagLen = GetConVarInt(g_hTagLen);
	
	g_aryBotTags = CreateArray(SIZEOF_BOTTAG);
	PushArrayString(g_aryBotTags, "CAN");
	PushArrayString(g_aryBotTags, "USA");
	
	HookConVarChange(g_hTagMethod, OnConVarChange);
	HookConVarChange(g_hTagLen, OnConVarChange);
	HookConVarChange(g_hBotTags, OnConVarChange);
	
	AutoExecConfig();
	
	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i))
			{
				OnClientConnected(i);
				OnClientSettingsChanged(i);
			}
		}
	}
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == g_hTagMethod)
	{
		g_iTagMethod = StringToInt(newValue);
	}
	else if (hCvar == g_hTagLen)
	{
		g_iTagLen = StringToInt(newValue);
	}
	else if (hCvar == g_hBotTags)
	{
		ClearArray(g_aryBotTags);
		ExplodeString_adt(newValue, ",", g_aryBotTags, SIZEOF_BOTTAG);
	}
}

public OnClientConnected(client)
{
	/* Store the clan tag this client should be using. */
	switch (g_iTagLen)
	{
		case 2:
		{
			decl String:ip[17], String:ccode[3];
		
			if (!GetClientIP(client, ip, sizeof(ip)))
				ccode = "??";

			if (!GeoipCode2(ip, ccode))
				ccode = "??";
			
			Format(g_sCountryTag[client], sizeof(g_sCountryTag[]), "[%s]", ccode);
		}
		case 3:
		{
			decl String:ip[17], String:ccode[4];
		
			if (!GetClientIP(client, ip, sizeof(ip)))
				ccode = "???";

			if (!GeoipCode3(ip, ccode))
				ccode = "???";
			
			Format(g_sCountryTag[client], sizeof(g_sCountryTag[]), "[%s]", ccode);
		}
	}
	
	if (IsFakeClient(client))
	{
		decl String:sBotTag[SIZEOF_BOTTAG];
		
		new idx = GetRandomInt(0, GetArraySize(g_aryBotTags) - 1);
		GetArrayString(g_aryBotTags, idx, sBotTag, SIZEOF_BOTTAG);
		
		Format(g_sCountryTag[client], sizeof(g_sCountryTag[]), "[%s]", sBotTag);
	}
}

public OnClientSettingsChanged(client)
{
	/* Set a client's clan tag once they finished loading their own tag. */
	if (IsClientInGame(client) && TagPlayer(client))
	{
		CS_SetClientClanTag(client, g_sCountryTag[client]);
	}
}

bool:TagPlayer(client)
{
	/* Should we be tagging this player? */
	decl String:sClanID[32];
	GetClientInfo(client, "cl_clanid", sClanID, sizeof(sClanID));

	if (g_iTagMethod == 1 || (g_iTagMethod == 2 && StringToInt(sClanID) == 0))
		return true;
	
	return false;
}

ExplodeString_adt(const String:text[], const String:split[], Handle:array, size)
{
	/* Rewritten ExplodeString stock (string.inc) using an adt array. */
	decl String:sBuffer[size];
	new idx, reloc_idx;
	
	while ((idx = SplitString(text[reloc_idx], split, sBuffer, size)) != -1)
	{
		PushArrayString(array, sBuffer);
		
		reloc_idx += idx;
		
		if (text[reloc_idx] == '\0')
			break;
	}
	
	if (text[reloc_idx] != '\0')
	{
		strcopy(sBuffer, size, text[reloc_idx]);
		PushArrayString(array, sBuffer);
	}
}