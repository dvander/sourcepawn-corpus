#pragma semicolon 1
#pragma newdecls required

#include <clientprefs>
#include <cstrike>
#include <sdkhooks>
#include <sdktools_entinput>
#include <sdktools_entoutput>
#tryinclude <sdktools_variant_t>

#define PL_VER "2.5.0"

static const int ADMIN_FLAG = ADMFLAG_ROOT;	// access flag for health commands

Handle
	hCookie,
	hHUD,
	hTimer[MAXPLAYERS+1];
StringMap
	smMaxes;
bool
	bCSGO,
	bShow[MAXPLAYERS+1] = {true, ...},
	bSymbols;
int
	iColor,
	iFlags,
	iEntRef[MAXPLAYERS+1],
	iUpdate,
	bCenter;
float
	fPosX,
	fPosY;

public Plugin myinfo =
{
	name		= "BossHud",
	version		= PL_VER,
	description	= "Displays the health / value of any func_breakable or math_counter that you activate.",
	author		= "AntiTeal, Grey83",
	url			= "https://forums.alliedmods.net/showthread.php?t=302675"
}

public void OnPluginStart()
{
	bCSGO = GetEngineVersion() == Engine_CSGO;

	CreateConVar("sm_bhud_version", PL_VER, "BossHud Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_bhud_enabled", "1", "The default state of info for newcomers.", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Show);
	CVarChange_Show(cvar, "", "");

	cvar = CreateConVar("sm_bhud_center", "1", "Show text in: 0 - HUD, 1 - center.", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Center);
	bCenter = cvar.BoolValue;

	cvar = CreateConVar("sm_bhud_flags", "", "Flags, one of which the player must have to see info. Empty - for all", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Flags);
	CVarChange_Flags(cvar, "", "");

	cvar = CreateConVar("sm_bhud_symbols", "1", "Determines whether '>>' and '<<' are wrapped around the text.", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChange_Symbols);
	bSymbols = cvar.BoolValue;

	cvar = CreateConVar("sm_bhud_color", "f00", "HUD info color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = red.", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChange_Color);
	CVarChange_Color(cvar, "", "");

	cvar = CreateConVar("sm_bhud_update", "3", "How long to update the client's hud with current health for.", _, true, _, true, 5.0);
	cvar.AddChangeHook(CVarChange_Update);
	iUpdate = cvar.IntValue;

	cvar = CreateConVar("sm_bhud_x", "-1.0", "HUD info position X (0.0 - 1.0 left to right or -1.0 for center)", _, true, -2.0, true, 1.0);
	cvar.AddChangeHook(CVarChange_PosX);
	fPosX = cvar.FloatValue;

	cvar = CreateConVar("sm_bhud_y", "0.09", "HUD info position Y (0.0 - 1.0 top to bottom or -1.0 for center)", _, true, -2.0, true, 1.0);
	cvar.AddChangeHook(CVarChange_PosY);
	fPosY = cvar.FloatValue;

	AutoExecConfig(true, "bosshud");

	RegAdminCmd("sm_addhp",		Cmd_EntityHP, ADMIN_FLAG, "Add Current HP");
	RegAdminCmd("sm_currenthp",	Cmd_EntityHP, ADMIN_FLAG, "See Current HP");
	RegAdminCmd("sm_subtracthp",Cmd_EntityHP, ADMIN_FLAG, "Subtract Current HP");


	HookEvent("round_start", Event_Round, EventHookMode_PostNoCopy);

	HookEntityOutput("func_physbox", "OnHealthChanged", OnDamaged);
	HookEntityOutput("func_physbox_multiplayer", "OnHealthChanged", OnDamaged);
	HookEntityOutput("func_breakable", "OnHealthChanged", OnDamaged);
	HookEntityOutput("math_counter", "OutValue", OnDamaged);

	hHUD = CreateHudSynchronizer();

	smMaxes = CreateTrie();

	hCookie = RegClientCookie("bhud_cookie", "Status of BossHud", CookieAccess_Private);
	RegConsoleCmd("sm_bhud",	Cmd_ToggleHud, "Toggle BHud");

	for(int i = 1; i <= MaxClients; i++) if(AreClientCookiesCached(i)) OnClientCookiesCached(i);
}

public void CVarChange_Show(ConVar cvar, char[] oldValue, char[] newValue)
{
	bShow[0] = cvar.BoolValue;

	for(int i = 1; i <= MaxClients; i++) if(!IsClientInGame(i)) bShow[i] = bShow[0];
}

public void CVarChange_Center(ConVar cvar, char[] oldValue, char[] newValue)
{
	bCenter = cvar.BoolValue;
}

public void CVarChange_Flags(ConVar cvar, char[] oldValue, char[] newValue)
{
	char buffer[24];
	cvar.GetString(buffer, sizeof(buffer));
	if((iFlags = ReadFlagString(buffer))) iFlags |= ADMFLAG_ROOT;
}

public void CVarChange_Symbols(ConVar cvar, char[] oldValue, char[] newValue)
{
	bSymbols = cvar.BoolValue;
}

public void CVarChange_Color(ConVar cvar, char[] oldValue, char[] newValue)
{
	char clr[8];
	cvar.GetString(clr, sizeof(clr));
	clr[7] = 0;	// чтобы проверялось максимум 7 первых символов

	int i;
	while(clr[i])
	{
		if(!(clr[i] >= '0' && clr[i] <= '9') && !(clr[i] >= 'A' && clr[i] <= 'F') && !(clr[i] >= 'a' && clr[i] <= 'f'))
		{	// не HEX-число
			iColor = 0xFF0000;
			LogError("HEX color '%s' isn't valid!\nHUD color is 0x%x (%d %d %d)!\n", clr, iColor, (iColor & 0xFF0000) >> 16, (iColor & 0xFF00) >> 8, iColor & 0xFF);
			return;
		}
		i++;
	}

	clr[6] = 0;
	if(i == 3)	// короткая форма => полная форма
	{
		clr[4] = clr[5] = clr[2];
		clr[2] = clr[3] = clr[1];
		clr[1] = clr[0];
		i = 6;
	}

	if(i != 6) iColor = 0xFF0000;	// невалидный цвет
	else StringToIntEx(clr, iColor , 16);
}

public void CVarChange_Update(ConVar cvar, char[] oldValue, char[] newValue)
{
	iUpdate = cvar.IntValue;

	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i) && hTimer[i])
	{
		delete hTimer[i];
		if(!iUpdate) continue;

		hTimer[i] = CreateTimer(iUpdate + 0.0, Timer_UpdateHUD, GetClientUserId(i));
		TriggerTimer(hTimer[i]);
	}
}

public void CVarChange_PosX(ConVar cvar, char[] oldValue, char[] newValue)
{
	fPosX = cvar.FloatValue;
}

public void CVarChange_PosY(ConVar cvar, char[] oldValue, char[] newValue)
{
	fPosY = cvar.FloatValue;
}

public void OnMapEnd()
{
	ClearTrie(smMaxes);
	for(int i = 1; i <= MaxClients; i++) if(hTimer[i]) delete hTimer[i];
}

public void Event_Round(Handle event, const char[] name, bool dontBroadcast)
{
	ClearTrie(smMaxes);
}

public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason)
{
	ClearTrie(smMaxes);
}

public void OnClientDisconnect(int client)
{
	bShow[client] = bShow[0];
	iEntRef[client] = 0;
	if(hTimer[client]) delete hTimer[client];
}

public void OnClientCookiesCached(int client)
{
	if(!client || IsFakeClient(client) || !IsHasAccess(client)) return;

	char buffer[4];
	GetClientCookie(client, hCookie, buffer, sizeof(buffer));
	bShow[client] = !buffer[0] ? bShow[0] : buffer[0] == '1';
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!strcmp(classname, "math_counter", false)) RequestFrame(RequestFrame_CheckEnt, EntIndexToEntRef(entity));
}

public void RequestFrame_CheckEnt(int entity)
{
	if(EntRefToEntIndex(entity) <= MaxClients) return;

	char name[64];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	SetTrieValue(smMaxes, name, GetEntMax(entity), true);
}

public void OnDamaged(const char[] output, int caller, int activator, float delay)
{
	if(!IsValidClient(activator)) return;

	iEntRef[activator] = EntIndexToEntRef(caller);
	ShowInfo(activator, caller, output[1] == 'u');
}

public Action Timer_UpdateHUD(Handle timer, int client)
{
	if((client = GetClientOfUserId(client)))
	{
		hTimer[client] = null;

		static int entity;
		static char cls[16];
		if((entity = EntRefToEntIndex(iEntRef[client])) > MaxClients)
			ShowInfo(client, entity, GetEntityClassname(entity, cls, sizeof(cls)) && !strcmp(cls, "math_counter", false));
	}
}

stock void ShowInfo(int client, int entity, bool math_counter)
{
	if(hTimer[client]) delete hTimer[client];

	if(!bShow[client] || !IsHasAccess(client))
		return;

	static char name[64];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	if(!name[0]) Format(name, sizeof(name), "Health");

	static int health;
	if(math_counter)
	{
		static int offset = -1, max, val;
		if(offset == -1) offset = FindDataMapInfo(entity, "m_OutValue");
		health = RoundFloat(GetEntDataFloat(entity, offset));
		if(GetTrieValue(smMaxes, name, max) && max != (val = GetEntMax(entity))) health = val - health;
	}
	else if((health = GetEntProp(entity, Prop_Data, "m_iHealth")) < 1 && health > 900000) return;

	if(!bCenter)
	{
		SetHudTextParams(fPosX, fPosY, iUpdate + 0.0, (iColor & 0xFF0000) >> 16, (iColor & 0xFF00) >> 8, iColor & 0xFF, 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, hHUD, bSymbols ? ">> %s: %i HP <<" : "%s: %i HP", name, health);
	}
	else if(bCSGO)
	{
		PrintCenterText(client, bSymbols ? "<font color='#%06X'>&gt;&gt; %s: %i HP &lt;&lt;</font>" : "<font color='#%06X'>%s: %i HP</font>", iColor, name, health);
	}
	else PrintCenterText(client, bSymbols ? ">> %s: %i HP <<" : "%s: %i HP", name, health);

	hTimer[client] = CreateTimer(iUpdate + 0.0, Timer_UpdateHUD, GetClientUserId(client));
}

public Action Cmd_EntityHP(int client, int argc)
{
	if(!client) return Plugin_Handled;

	static int ent;
	if((ent = EntRefToEntIndex(iEntRef[client])) <= MaxClients)
	{
		PrintToChat(client, "[SM] Current entity is invalid");
		return Plugin_Handled;
	}

	char cmd[16];
	GetCmdArg(0, cmd, sizeof(cmd));
	if(argc < 1 && cmd[3] != 'c')
	{
		ReplyToCommand(client, "[SM] Usage: %s <health>", cmd);
		return Plugin_Handled;
	}

	char name[64], cls[64];
	int health, max;

	if(cmd[3] != 'c')
	{
		GetCmdArg(1, name, sizeof(name));
		SetVariantInt(StringToInt(name));
		max = StringToInt(name);
	}

	GetEntityClassname(ent, cls, sizeof(cls));
	GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name));

	if(!strcmp(cls, "math_counter", false))
	{
		static int offset = -1;
		if(offset == -1) offset = FindDataMapInfo(ent, "m_OutValue");
		health = RoundFloat(GetEntDataFloat(ent, offset));

		if(cmd[3] != 'c')
		{
			if(GetTrieValue(smMaxes, name, max) && max != GetEntMax(ent))
				AcceptEntityInput(ent, cmd[3] == 's' ? "Add" : "Subtract", client, client);
			else AcceptEntityInput(ent, cmd[3] == 's' ? "Subtract" : "Add", client, client);
		}
	}
	else
	{
		health = GetEntProp(ent, Prop_Data, "m_iHealth");
		if(cmd[3] != 'c') AcceptEntityInput(ent, cmd[3] == 's' ? "RemoveHealth" : "AddHealth", client, client);
	}

	switch(cmd[3])
	{
		case 'a': PrintToChat(client, "[SM] %i health added. (%i HP to %i HP)", max, health, health + max);
		case 'c': PrintToChat(client, "[SM] Entity %s %i (%s): %i HP", name, ent, cls, health);
		case 's': PrintToChat(client, "[SM] %i health subtracted. (%i HP to %i HP)", max, health, health - max);
	}

	return Plugin_Handled;
}

public Action Cmd_ToggleHud(int client, int argc)
{
	if(!client) return Plugin_Handled;

	if(IsHasAccess(client))
	{
		bShow[client] = !bShow[client];
		PrintToChat(client, "[SM] BHud has been %s.", bShow[client] ? "enabled" : "disabled");
		SetClientCookie(client, hCookie, bShow[client] ? "1" : "0");
	}
	else PrintToChat(client, "[SM] You don't have access to this command.");

	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	return 0 < client && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

static bool IsHasAccess(int client)
{
	return !iFlags || GetUserFlagBits(client) & iFlags;
}

stock int GetEntMax(int entity)
{
	return RoundFloat(GetEntPropFloat(entity, Prop_Data, "m_flMax"));
}