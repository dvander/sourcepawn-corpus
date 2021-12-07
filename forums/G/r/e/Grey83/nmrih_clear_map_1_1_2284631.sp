#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION	"1.1"
#define CHAT_PREFIX		"\x01[\x0700DF00Clear map\x01]"
#define CONSOLE_PREFIX	"[Clear map]"

new Handle:hReport, bool:bReport,
	Handle:hTimer, Float:fTimer,
	Handle:hLimit, iLimit,
	bool:bTrue;

public Plugin:myinfo = 
{
	name = "[NMRiH] Clear map",
	author = "Grey83",
	description = "Remove unnecessary items & zombies from the map",
	version	= PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=256713"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("nmrih_clear_map_version", PLUGIN_VERSION, "[NMRiH] Clear map version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hReport = CreateConVar("sm_clear_map_report", "1", "1/0 - On/Off report after clearing map.", FCVAR_NONE, true, 0.0, true, 1.0);
	hTimer = CreateConVar("sm_clear_map_timer", "30", "Time (in seconds), which will be checked a number of items and they will be removed. 0 - disable timer, 1 and more - enable timer", FCVAR_NONE, true, 0.0, true, 120.0);
	hLimit = CreateConVar("sm_clear_map_limit", "500", "The maximum number of items that will be removed unnecessary items from the map.", FCVAR_NONE, true, 0.0, true, 1000.0);
	RegAdminCmd("sm_clear", Manual_NoItems, ADMFLAG_SLAY, "Manual remove unnecessary items from the map.");
	RegAdminCmd("sm_nonpcs", Manual_NoNPCs, ADMFLAG_SLAY, "Manual remove zombies from the map.");

	bReport = GetConVarBool(hReport);
	fTimer = GetConVarFloat(hTimer);
	iLimit = GetConVarInt(hLimit);

	HookConVarChange(hReport, OnConVarChange);
	HookConVarChange(hTimer, OnConVarChange);
	HookConVarChange(hLimit, OnConVarChange);

	HookEvent("state_change", Event_SC);

	PrintToServer("[NMRiH] Clear map v.%s has been successfully loaded!", PLUGIN_VERSION);
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == hReport) bReport = bool:StringToInt(newValue);
	else if (hCvar == hTimer) fTimer = StringToFloat(newValue);
	else if (hCvar == hLimit) iLimit = StringToInt(newValue);
}

public Action:Manual_NoItems(client, args)
{
	new maxent = GetMaxEntities(), String:item[64], num = 0;
	for (new i = GetMaxClients(); i < maxent; i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, item, sizeof(item));
			if ( ( StrEqual("bow_deerhunter", item) || (StrContains(item, "exp_", true) == 0) || (StrContains(item, "fa_", true) == 0) || (StrContains(item, "item_", true) == 0) || (StrContains(item, "me_", true) == 0) || StrEqual("projectile_arrow", item) || (StrContains(item, "tool_", true) == 0) ) && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == -1 )
			{
				num++;
				RemoveEdict(i);
			}
		}
	}
	if (bReport) CleaningMessage(client, num, "item");
	return Plugin_Continue;
}

public Action:Manual_NoNPCs(client, args)
{
	new maxent = GetMaxEntities(), String:item[64], num = 0;
	for (new i = GetMaxClients(); i < maxent; i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, item, sizeof(item));
			if (StrContains(item, "npc_nmrih_", true) == 0)
			{
				num++;
				RemoveEdict(i);
			}
		}
	}
	if (bReport) CleaningMessage(client, num, "NPC");
	return Plugin_Continue;
}

public Event_SC(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iState = GetEventInt(event, "state");
	if (iState == 3 && fTimer >= 1)
	{
		bTrue = true;
		PrintToServer("%s Autoclearing is enabled.", CONSOLE_PREFIX);
		CreateTimer(fTimer, AutoClear, _, TIMER_REPEAT);
	}
	else
	{
		bTrue = false;
		PrintToServer("%s Autoclearing is disabled.", CONSOLE_PREFIX);
	}
}

public Action:AutoClear(Handle:timer)
{
	new maxent = GetMaxEntities(), String:item[64], num = 0, del = 0;
	for (new i = GetMaxClients(); i < maxent; i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, item, sizeof(item));
			if ( ( StrEqual("bow_deerhunter", item) || (StrContains(item, "exp_", true) == 0) || (StrContains(item, "fa_", true) == 0) || (StrContains(item, "item_", true) == 0) || (StrContains(item, "me_", true) == 0) || StrEqual("projectile_arrow", item) || (StrContains(item, "tool_", true) == 0) ) && GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity") == -1 )
			{
				num++;
				if (num > iLimit )
					{
						RemoveEdict(i);
						del++;
					}
			}
		}
	}
	if (del) CleaningMessage(0, del, "item");
	if (bTrue) return Plugin_Continue;
	else return Plugin_Stop;
}

CleaningMessage(client, num, String:kind[])
{
	if (0 < client <= MaxClients)
	{
		if (!num) PrintToChat(client, "%s There is nothing to remove.", CHAT_PREFIX);
		else
		{
			PrintToChat(client, "%s Removed \x0700DF00%d \x01%ss.", CHAT_PREFIX, num, kind);
			PrintToServer("%s %N has removed %d %ss.", CONSOLE_PREFIX, client, num, kind);
		}
	}
	else if (!client)
	{
		if (!num) PrintToServer("%s There is nothing to remove.", CONSOLE_PREFIX);
		else PrintToServer("%s Removed %d %ss.", CONSOLE_PREFIX, num, kind);
	}
}