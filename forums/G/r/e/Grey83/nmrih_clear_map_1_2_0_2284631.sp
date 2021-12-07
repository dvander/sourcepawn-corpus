#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_NAME		"[NMRiH] Clear map"
#define PLUGIN_VERSION	"1.2.0"

#define CHAT_PREFIX		"\x01[\x04Clear map\x01] \x03"
#define CONSOLE_PREFIX	"[Clear map] "

Handle TimerClear;

ConVar hReport, hTimer, hLimit;
bool bReport, bTrue;
float fTimer;
int iLimit;

public Plugin myinfo = 
{
	name		= PLUGIN_NAME,
	author		= "Grey83",
	description	= "Remove unnecessary items & zombies from the map",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/member.php?u=256713"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("nmrih_clear_map_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hReport = CreateConVar("sm_clear_map_report", "1", "1/0 - On/Off report after clearing map.", FCVAR_NONE, true, 0.0, true, 1.0);
	hTimer = CreateConVar("sm_clear_map_timer", "30", "Time (in seconds), which will be checked a number of items and they will be removed. 0 - disable timer, 1 and more - enable timer", FCVAR_NONE, true, 0.0, true, 120.0);
	hLimit = CreateConVar("sm_clear_map_limit", "500", "The maximum number of items that will be removed unnecessary items from the map.", FCVAR_NONE, true, 0.0, true, 1000.0);
	RegAdminCmd("sm_clear", Cmd_NoItems, ADMFLAG_SLAY, "Manual remove unnecessary items from the map.");
	RegAdminCmd("sm_nonpcs", Cmd_NoNPCs, ADMFLAG_SLAY, "Manual remove zombies from the map.");
	RegAdminCmd("sm_count", Cmd_Count, ADMFLAG_SLAY, "Shows the number of items and the zombies on the map.");

	bReport = GetConVarBool(hReport);
	fTimer = GetConVarFloat(hTimer);
	iLimit = GetConVarInt(hLimit);

	HookConVarChange(hReport, OnConVarChanged);
	HookConVarChange(hTimer, OnConVarChanged);
	HookConVarChange(hLimit, OnConVarChanged);

	HookEvent("state_change", Event_SC);

	PrintToServer("%s v.%s has been successfully loaded!", PLUGIN_NAME, PLUGIN_VERSION);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == hReport) bReport = view_as<bool>(StringToInt(newValue));
	else if(convar == hTimer) fTimer = StringToFloat(newValue);		// добавить отключение таймера
	else if(convar == hLimit) iLimit = StringToInt(newValue);
}

public Action Cmd_NoItems(int client, int args)
{
	int num = RemoveItems();
	if(bReport) CleaningMessage(client, num, num == 1 ? "item" : "items");
	return Plugin_Handled;
}

public Action Cmd_NoNPCs(int client, int args)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i)) SetEntProp(i, Prop_Send, "m_bGrabbed", 0, 1);
	}

	char item[17];
	int num;
	for(int i = GetMaxClients(); i < GetMaxEntities(); i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, item, sizeof(item));
			if(StrContains(item, "npc_nmrih_", true) == 0)
			{
				num++;
				RemoveEdict(i);
			}
		}
	}

	if(bReport) CleaningMessage(client, num, num == 1 ? "NPC": "NPCs");
	return Plugin_Handled;
}

public Action Cmd_Count(int client, int args)
{
	char class[17];
	int items, zombies;
	for(int i = GetMaxClients(); i < GetMaxEntities(); i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if(StrContains(class, "npc_nmrih_", true) == 0) zombies++;
			else if(GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == -1 && (StrContains("bow_deerhunter", class) == 0 || StrContains(class, "exp_", true) == 0 || StrContains(class, "fa_", true) == 0 || StrContains(class, "item_", true) == 0 || StrContains(class, "me_", true) == 0 || StrContains("projectile_arrow", class) == 0 || StrContains(class, "tool_", true) == 0)) items++;
		}
	}

	if(0 < client <= MaxClients && IsClientInGame(client)) PrintToChat(client, "%sFound:\n	\x04%i \x03item%s\n	\x04%i \x03zombie%s", CHAT_PREFIX, items, items == 1 ? "" : "s", zombies, zombies == 1 ? "" : "s");
	else if(client == 0) PrintToServer("%sFound:\n	%i item%s\n	%i zombie%s", CONSOLE_PREFIX, items, items == 1 ? "" : "s", zombies, zombies == 1 ? "" : "s");

	return Plugin_Handled;
}

public void Event_SC(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("state") == 3 && fTimer >= 1)
	{
		bTrue = true;
		PrintToServer("%sAutoclearing is enabled.", CONSOLE_PREFIX);
		TimerClear = CreateTimer(fTimer, AutoClear, _, TIMER_REPEAT);
	}
	else if(bTrue)
	{
		if(TimerClear != null)
		{
			KillTimer(TimerClear);
			TimerClear = null;
		}
		bTrue = false;
		PrintToServer("%sAutoclearing is disabled.", CONSOLE_PREFIX);
	}
}

public Action AutoClear(Handle timer)
{
	if(!bTrue) return Plugin_Stop;
	int num = RemoveItems(iLimit);
	if(num) CleaningMessage(0, num, num == 1 ? "item" : "items");
	return Plugin_Continue;
}

int RemoveItems(int limit = 0)
{
	char item[17];
	int num, del;
	for(int i = GetMaxClients(); i < GetMaxEntities(); i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i) && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == -1)
		{
			GetEdictClassname(i, item, sizeof(item));
			if(StrContains("bow_deerhunter", item) == 0 || StrContains(item, "exp_", true) == 0 || StrContains(item, "fa_", true) == 0 || StrContains(item, "item_", true) == 0 || StrContains(item, "me_", true) == 0 || StrContains("projectile_arrow", item) == 0 || StrContains(item, "tool_", true) == 0)
			{
				num++;
				if(num > limit)
				{
					RemoveEdict(i);
					del++;
				}
			}
		}
	}
	return del;
}

void CleaningMessage(int client, int num, char[] kind)
{
	if(0 < client <= MaxClients && IsClientInGame(client))
	{
		if(!num) PrintToChat(client, "%sThere is nothing to remove.", CHAT_PREFIX);
		else
		{
			PrintToChat(client, "%sRemoved \x04%d \x03%s.", CHAT_PREFIX, num, kind);
			PrintToServer("%s '%N' has removed %d %s.", CONSOLE_PREFIX, client, num, kind);
		}
	}
	else if(client == 0)
	{
		if(!num) PrintToServer("%s There is nothing to remove.", CONSOLE_PREFIX);
		else PrintToServer("%s Removed %d %s.", CONSOLE_PREFIX, num, kind);
	}
}