#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define PLUGIN_VERSION "2.4"
#pragma newdecls required

Handle BossHud_Cookie = INVALID_HANDLE, HudSync = INVALID_HANDLE;
bool g_bStatus[MAXPLAYERS+1] = {false, ...};
int entityID[MAXPLAYERS+1] = -1;
ConVar g_cVHudPosition, g_cVHudColor, g_cVHudSymbols, g_cVUpdateTime, g_cVDisplayType, g_cVAdminOnly;
float HudPos[2];
int HudColor[3];
int UpdateTime;
int DisplayType;
int g_iTimer[MAXPLAYERS+1];
bool HudSymbols;
bool AdminOnly;
StringMap EntityMaxes;

public Plugin myinfo = {
	name = "BossHud",
	author = "AntiTeal",
	description = "",
	version = PLUGIN_VERSION,
	url = "antiteal.com"
};

public void OnPluginStart()
{
	CreateConVar("sm_bhud_version", PLUGIN_VERSION, "BHud Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	BossHud_Cookie = RegClientCookie("bhud_cookie", "Status of BHud", CookieAccess_Private);
	for(int i = 1; i <= MaxClients; i++)
	{
		if (!AreClientCookiesCached(i))
		continue;
		OnClientCookiesCached(i);
	}

	RegConsoleCmd("sm_bhud", Command_BHud, "Toggle BHud");

	HookEntityOutput("func_physbox", "OnHealthChanged", OnDamage);
	HookEntityOutput("func_physbox_multiplayer", "OnHealthChanged", OnDamage);
	HookEntityOutput("func_breakable", "OnHealthChanged", OnDamage);
	HookEntityOutput("math_counter", "OutValue", OnDamageCounter);

	//HookEntityOutput("math_counter", "OnChangedFromMin", OnMaxChanged);
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy); 

	RegAdminCmd("sm_currenthp", Command_CHP, ADMFLAG_GENERIC, "See Current HP");
	RegAdminCmd("sm_subtracthp", Command_SHP, ADMFLAG_GENERIC, "Subtract Current HP");
	RegAdminCmd("sm_addhp", Command_AHP, ADMFLAG_GENERIC, "Add Current HP");

	g_cVHudPosition = CreateConVar("sm_bhud_position", "-1.0 0.09", "The X and Y position for the hud.");
	g_cVHudColor = CreateConVar("sm_bhud_color", "255 0 0", "RGB color value for the hud.");
	g_cVHudSymbols = CreateConVar("sm_bhud_symbols", "1", "Determines whether >> and << are wrapped around the text.");
	g_cVUpdateTime = CreateConVar("sm_bhud_updatetime", "3", "How long to update the client's hud with current health for.");
	g_cVDisplayType = CreateConVar("sm_bhud_displaytype", "0", "Display type of HUD. (0 = game_text, 1 = center text)");
	g_cVAdminOnly = CreateConVar("sm_bhud_adminonly", "0", "Determines whether BHUD is public or admin only. (0 = public, 1 = admins)");

	g_cVHudPosition.AddChangeHook(ConVarChange);
	g_cVHudColor.AddChangeHook(ConVarChange);
	g_cVHudSymbols.AddChangeHook(ConVarChange);
	g_cVUpdateTime.AddChangeHook(ConVarChange);
	g_cVDisplayType.AddChangeHook(ConVarChange);
	g_cVAdminOnly.AddChangeHook(ConVarChange);

	AutoExecConfig(true);
	GetConVars();

	CreateTimer(0.25, UpdateHUD, _, TIMER_REPEAT);

	EntityMaxes = CreateTrie();
	ClearTrie(EntityMaxes);
}

public void Event_OnRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{ 
	EntityMaxes = CreateTrie();
	ClearTrie(EntityMaxes); 
}  

public void OnClientConnected(int client)
{
	g_iTimer[client] = 0;
}

public void ColorStringToArray(const char[] sColorString, int aColor[3])
{
	char asColors[4][4];
	ExplodeString(sColorString, " ", asColors, sizeof(asColors), sizeof(asColors[]));

	aColor[0] = StringToInt(asColors[0]);
	aColor[1] = StringToInt(asColors[1]);
	aColor[2] = StringToInt(asColors[2]);
}

public void GetConVars()
{
	char StringPos[2][8];
	char PosValue[16];
	g_cVHudPosition.GetString(PosValue, sizeof(PosValue));
	ExplodeString(PosValue, " ", StringPos, sizeof(StringPos), sizeof(StringPos[]));

	HudPos[0] = StringToFloat(StringPos[0]);
	HudPos[1] = StringToFloat(StringPos[1]);

	char ColorValue[64];
	g_cVHudColor.GetString(ColorValue, sizeof(ColorValue));

	ColorStringToArray(ColorValue, HudColor);

	HudSymbols = g_cVHudSymbols.BoolValue;
	AdminOnly = g_cVAdminOnly.BoolValue;
	UpdateTime = g_cVUpdateTime.IntValue;
	DisplayType = g_cVDisplayType.IntValue;
}

public void ConVarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	GetConVars();
}

public void OnMapStart()
{
	HudSync = CreateHudSynchronizer();
}
public void OnMapEnd()
{
	if(HudSync != INVALID_HANDLE)
	{
		CloseHandle(HudSync);
		HudSync = INVALID_HANDLE;
	}
}

public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, BossHud_Cookie, sValue, sizeof(sValue));
	g_bStatus[client] = (sValue[0] != '\0' && StringToInt(sValue));
}

public Action Command_BHud(int client, int argc)
{
	if(IsPlayerGenericAdmin(client) || !AdminOnly) 
	{
		char sValue[8];
		g_bStatus[client] = !g_bStatus[client];
		PrintToChat(client, "[SM] BHud has been %s.", g_bStatus[client] ? "enabled" : "disabled");
		Format(sValue, sizeof(sValue), "%i", g_bStatus[client]);
		SetClientCookie(client, BossHud_Cookie, sValue);
	}
	else
	PrintToChat(client, "[SM] You do not have access to this command.");
	return Plugin_Handled;
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

public void SendHudMsg(int client, char szMessage[128])
{
	if(!IsPlayerGenericAdmin(client) && AdminOnly) 
	return;

	if(DisplayType == 0)
	{
		SetHudTextParams(HudPos[0], HudPos[1], 3.0, HudColor[0], HudColor[1], HudColor[2], 255, 0, 0.0, 0.0, 0.0);
		ClearSyncHud(client, HudSync);
		ShowSyncHudText(client, HudSync, "%s", szMessage);
	}
	else
	{
		int rgb;
		rgb |= ((HudColor[0] & 0xFF) << 16);
		rgb |= ((HudColor[1] & 0xFF) << 8 );
		rgb |= ((HudColor[2] & 0xFF) << 0 );
		ReplaceString(szMessage, sizeof(szMessage), "<", "&lt;");
		PrintCenterText(client, "<font color='#%06X'>%s</font>", rgb, szMessage);
	}
}

public void OnDamage(const char[] output, int caller, int activator, float delay)
{
	if(IsValidClient(activator) && g_bStatus[activator] && (IsPlayerGenericAdmin(activator) || !AdminOnly))
	{
		char szName[64], szString[128];
		GetEntPropString(caller, Prop_Data, "m_iName", szName, sizeof(szName));

		if(strlen(szName) == 0)
		Format(szName, sizeof(szName), "Health");

		int health = GetEntProp(caller, Prop_Data, "m_iHealth");

		if(health > 0 && health <= 900000)
		{
			if(HudSymbols)
			Format(szString, sizeof(szString), ">> %s: %i HP <<", szName, health);
			else
			Format(szString, sizeof(szString), "%s: %i HP", szName, health);

			SendHudMsg(activator, szString);

			entityID[activator] = caller;

			g_iTimer[activator] = GetTime();
		}
	}
}

public void OnDamageCounter(const char[] output, int caller, int activator, float delay)
{
	if(IsValidClient(activator) && g_bStatus[activator] && (IsPlayerGenericAdmin(activator) || !AdminOnly))
	{
		char szName[64], szString[128];
		GetEntPropString(caller, Prop_Data, "m_iName", szName, sizeof(szName));

		if(strlen(szName) == 0)
		Format(szName, sizeof(szName), "Health");

		static int offset = -1;
		if (offset == -1)
		offset = FindDataMapInfo(caller, "m_OutValue");

		int health = RoundFloat(GetEntDataFloat(caller, offset));

		int max;
		if(GetTrieValue(EntityMaxes, szName, max) && max != RoundFloat(GetEntPropFloat(caller, Prop_Data, "m_flMax")))
		health = RoundFloat(GetEntPropFloat(caller, Prop_Data, "m_flMax")) - health;

		if(HudSymbols)
		Format(szString, sizeof(szString), ">> %s: %i HP <<", szName, health);
		else
		Format(szString, sizeof(szString), "%s: %i HP", szName, health);

		SendHudMsg(activator, szString);

		entityID[activator] = caller;

		g_iTimer[activator] = GetTime();
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(IsValidEntity(entity))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawnPost);
	}
}

public void OnEntitySpawnPost(int ent)
{
	RequestFrame(CheckEnt, ent);
}

public void CheckEnt(any ent)
{
	if(IsValidEntity(ent))
	{
		char szName[64], szType[64];
		GetEntityClassname(ent, szType, sizeof(szType));
		GetEntPropString(ent, Prop_Data, "m_iName", szName, sizeof(szName));

		if(StrEqual(szType, "math_counter", false))
		{
			SetTrieValue(EntityMaxes, szName, RoundFloat(GetEntPropFloat(ent, Prop_Data, "m_flMax")), true);
		}
	}
}

public Action Command_CHP(int client, int argc)
{
	if(!IsValidEntity(entityID[client]))
	{
		PrintToChat(client, "[SM] Current entity is invalid (id %i)", entityID[client]);
		return Plugin_Handled;
	}

	char szName[64], szType[64];
	int health;
	GetEntityClassname(entityID[client], szType, sizeof(szType));
	GetEntPropString(entityID[client], Prop_Data, "m_iName", szName, sizeof(szName));

	if(StrEqual(szType, "math_counter", false))
	{
		static int offset = -1;
		if (offset == -1)
		offset = FindDataMapInfo(entityID[client], "m_OutValue");

		health = RoundFloat(GetEntDataFloat(entityID[client], offset));
	}
	else
	{
		health = GetEntProp(entityID[client], Prop_Data, "m_iHealth");
	}

	PrintToChat(client, "[SM] Entity %s %i (%s): %i HP", szName, entityID[client], szType, health);
	return Plugin_Handled;
}

public Action Command_SHP(int client, int argc)
{
	if(!IsValidEntity(entityID[client]))
	{
		PrintToChat(client, "[SM] Current entity is invalid (id %i)", entityID[client]);
		return Plugin_Handled;
	}

	if (argc < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_subtracthp <health>");
		return Plugin_Handled;
	}

	char szName[64], szType[64], arg[8];
	int health, max;

	GetEntityClassname(entityID[client], szType, sizeof(szType));
	GetEntPropString(entityID[client], Prop_Data, "m_iName", szName, sizeof(szName));
	GetCmdArg(1, arg, sizeof(arg));
	SetVariantInt(StringToInt(arg));

	if(StrEqual(szType, "math_counter", false))
	{
		static int offset = -1;
		if (offset == -1)
		offset = FindDataMapInfo(entityID[client], "m_OutValue");

		health = RoundFloat(GetEntDataFloat(entityID[client], offset));
		if(GetTrieValue(EntityMaxes, szName, max) && max != RoundFloat(GetEntPropFloat(entityID[client], Prop_Data, "m_flMax")))
		AcceptEntityInput(entityID[client], "Add", client, client);
		else
		AcceptEntityInput(entityID[client], "Subtract", client, client);
		PrintToChat(client, "[SM] %i health subtracted. (%i HP to %i HP)", StringToInt(arg), health, health - StringToInt(arg));
	}
	else
	{
		health = GetEntProp(entityID[client], Prop_Data, "m_iHealth");
		AcceptEntityInput(entityID[client], "RemoveHealth", client, client);
		PrintToChat(client, "[SM] %i health subtracted. (%i HP to %i HP)", StringToInt(arg), health, health - StringToInt(arg));
	}

	return Plugin_Handled;
}

public Action Command_AHP(int client, int argc)
{
	if(!IsValidEntity(entityID[client]))
	{
		PrintToChat(client, "[SM] Current entity is invalid (id %i)", entityID[client]);
		return Plugin_Handled;
	}

	if (argc < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addhp <health>");
		return Plugin_Handled;
	}

	char szName[64], szType[64], arg[8];
	int health, max;

	GetEntityClassname(entityID[client], szType, sizeof(szType));
	GetEntPropString(entityID[client], Prop_Data, "m_iName", szName, sizeof(szName));
	GetCmdArg(1, arg, sizeof(arg));
	SetVariantInt(StringToInt(arg));

	if(StrEqual(szType, "math_counter", false))
	{
		static int offset = -1;
		if (offset == -1)
		offset = FindDataMapInfo(entityID[client], "m_OutValue");

		health = RoundFloat(GetEntDataFloat(entityID[client], offset));
		if(GetTrieValue(EntityMaxes, szName, max) && max != RoundFloat(GetEntPropFloat(entityID[client], Prop_Data, "m_flMax")))
		AcceptEntityInput(entityID[client], "Subtract", client, client);
		else
		AcceptEntityInput(entityID[client], "Add", client, client);
		PrintToChat(client, "[SM] %i health added. (%i HP to %i HP)", StringToInt(arg), health, health + StringToInt(arg));
	}
	else
	{
		health = GetEntProp(entityID[client], Prop_Data, "m_iHealth");
		AcceptEntityInput(entityID[client], "AddHealth", client, client);
		PrintToChat(client, "[SM] %i health added. (%i HP to %i HP)", StringToInt(arg), health, health + StringToInt(arg));
	}

	return Plugin_Handled;
}

public Action UpdateHUD(Handle timer, any client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && g_bStatus[i] && IsValidEntity(entityID[i]) && (IsPlayerGenericAdmin(i) || !AdminOnly))
		{
			int time = GetTime() - g_iTimer[i];
			if (time > UpdateTime)
			continue;

			char szName[64], szType[64], szString[128];
			int health;

			GetEntityClassname(entityID[i], szType, sizeof(szType));
			GetEntPropString(entityID[i], Prop_Data, "m_iName", szName, sizeof(szName));

			if(strlen(szName) == 0)
			Format(szName, sizeof(szName), "Health");

			if(StrEqual(szType, "math_counter", false))
			{
				static int offset = -1;
				if (offset == -1)
				offset = FindDataMapInfo(entityID[i], "m_OutValue");

				health = RoundFloat(GetEntDataFloat(entityID[i], offset));

				int max;
				if(GetTrieValue(EntityMaxes, szName, max) && max != RoundFloat(GetEntPropFloat(entityID[i], Prop_Data, "m_flMax")))
				health = RoundFloat(GetEntPropFloat(entityID[i], Prop_Data, "m_flMax")) - health;
			}
			else
			{
				health = GetEntProp(entityID[i], Prop_Data, "m_iHealth");
			}

			if(health <= 0 || health > 900000)
			continue;

			if(HudSymbols)
			Format(szString, sizeof(szString), ">> %s: %i HP <<", szName, health);
			else
			Format(szString, sizeof(szString), "%s: %i HP", szName, health);

			SendHudMsg(i, szString);
		}
	}
}

public bool IsPlayerGenericAdmin(int client) 
{ 
	return CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false);
}  
