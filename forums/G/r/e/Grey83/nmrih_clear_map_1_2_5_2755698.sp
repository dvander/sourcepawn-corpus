#pragma semicolon 1
#pragma newdecls required

#include <sdktools_entinput>

#if SOURCEMOD_V_MINOR > 10
	#define PL_NAME	"[NMRiH] Clear map"
	#define PL_VER	"1.2.5"
#endif

static const char
#if SOURCEMOD_V_MINOR < 11
	PL_NAME[]		= "[NMRiH] Clear map",
	PL_VER[]		= "1.2.5",
#endif

	CHAT_PREFIX[]	= "\x01[\x04Clear map\x01] \x03",
	CON_PREFIX[]	= "[Clear map] ",

	TYPE[][]		= {"item", "zombie", "items", "zombies"};

enum
{
	Type_Item = 0,
	Type_NPC
}

Handle
	hTimer;
bool
	bReport,
	bLate,
	bState3;
int
	iLimit,
	iNum;
float
	fTimer;

public Plugin myinfo = 
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Remove unnecessary items & zombies from the map",
	author		= "Grey83",
	url			= "https://steamcommunity.com/groups/grey83ds"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("nmrih_clear_map_version", PL_VER, PL_NAME, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cvar;
	cvar = CreateConVar("sm_clear_map_report",	"1",	"1/0 - On/Off report after clearing map.", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Report);
	bReport = cvar.BoolValue;

	cvar = CreateConVar("sm_clear_map_timer",	"30",	"Time (in seconds), which will be checked a number of items and they will be removed. 0 - disable timer, 1 and more - enable timer", _, true, _, true, 120.0);
	cvar.AddChangeHook(CVarChanged_Timer);
	fTimer = cvar.FloatValue;

	cvar = CreateConVar("sm_clear_map_limit",	"500",	"The maximum number of items that will be removed unnecessary items from the map.", _, true, _, true, 1000.0);
	cvar.AddChangeHook(CVarChanged_Limit);
	iLimit = cvar.IntValue;

	RegAdminCmd("sm_clear", Cmd_NoItems, ADMFLAG_SLAY, "Manual remove unnecessary items from the map.");
	RegAdminCmd("sm_nonpcs", Cmd_NoNPCs, ADMFLAG_SLAY, "Manual remove zombies from the map.");
	RegAdminCmd("sm_count", Cmd_Count, ADMFLAG_SLAY, "Shows the number of items and the zombies on the map.");

	HookEvent("state_change", Event_SC);

	if(bLate)
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) iNum++;
		PrintToServer(">	Players number: %i", iNum);
		if(!iNum) ClearMap();
		bLate = false;
	}

	PrintToServer("%s v.%s has been successfully loaded!", PL_NAME, PL_VER);
}

public void OnMapStart()
{
	iNum = 0;
}

public void CVarChanged_Report(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bReport = cvar.BoolValue;
}

public void CVarChanged_Timer(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fTimer = cvar.FloatValue;
}

public void CVarChanged_Limit(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iLimit = cvar.IntValue;
}

public Action Cmd_NoItems(int client, int args)
{
	CleaningMessage(client, RemoveItems(), Type_Item);
	return Plugin_Handled;
}

public Action Cmd_NoNPCs(int client, int args)
{
	int num;
	char class[12];
	for(int i = MaxClients+1, max = GetMaxEntities(); i < max; i++)
		if(CheckEntity(i, class, sizeof(class)) && !StrContains(class, "npc_nmrih_", true))
		{
			num++;
			AcceptEntityInput(i, "Kill");
		}

	CleaningMessage(client, num, Type_NPC);
	return Plugin_Handled;
}

public Action Cmd_Count(int client, int args)
{
	char class[32];
	int items, zombies;
	for(int i = MaxClients+1, max = GetMaxEntities(); i < max; i++) if(CheckEntity(i, class, sizeof(class)))
	{
		if(!StrContains(class, "npc_nmrih_", true)) zombies++;
		else if(IsValidItem(i, class)) items++;
	}

	class[0] = 0;
	if(IsValidClient(client))
	{
		if(zombies)	FormatEx(class, sizeof(class), " \x04%d \x03%s", zombies, TYPE[zombies > 1 ? 3 : 1]);
		if(items)	Format(class, sizeof(class), "%s%s \x04%d \x03%s", class, zombies ? " and" : "", items, TYPE[items > 1 ? 2 : 0]);
		else if(!zombies) strcopy(class, sizeof(class), " \x04nothing");
		PrintToChat(client, "%sFound:%s", CHAT_PREFIX, class);
	}
	else if(!client)
	{
		if(zombies)	FormatEx(class, sizeof(class), " %d %s", zombies, TYPE[zombies > 1 ? 3 : 1]);
		if(items)	Format(class, sizeof(class), "%s%s %d %s", class, zombies ? " and" : "", items, TYPE[items > 1 ? 2 : 0]);
		else if(!zombies) strcopy(class, sizeof(class), " nothing");
		PrintToServer("%sFound:%s", CON_PREFIX, class);
	}

	return Plugin_Handled;
}

public void Event_SC(Event event, const char[] name, bool dontBroadcast)
{
	static int state;
	if((bState3 = (state = event.GetInt("state")) == 3))
	{
		if(fTimer >= 1)
		{
			PrintToServer("%sAutoclearing is enabled.", CON_PREFIX);
			hTimer = CreateTimer(fTimer, AutoClear, _, TIMER_REPEAT);
		}
	}
	else
	{
		if(fTimer >= 1)
		{
			if(hTimer) delete hTimer;
			PrintToServer("%sAutoclearing is disabled.", CON_PREFIX);
		}
		if(state < 2 || state > 3) ClearMap();
	}
}

public void OnClientConnected(int client)
{
	iNum++;
	PrintToServer(">	Players number increased: %i", iNum);
}

public void OnClientDisconnect_Post(int client)
{
	iNum--;
	PrintToServer(">	Players number decreased: %i", iNum);
	if(!bState3 && !iNum) ClearMap();
}

stock void ClearMap()
{
	static int npcs, items;
	static char class[32];
	npcs = items = 0;

	for(int i = MaxClients+1, max = GetMaxEntities(); i < max; i++) if(CheckEntity(i, class, sizeof(class)))
	{
		if(!StrContains(class, "npc_nmrih_", true))	npcs++;
		else if(IsValidItem(i, class))				items++;
		else continue;
		AcceptEntityInput(i, "Kill");
	}
	class[0] = 0;
	if(npcs)	FormatEx(class, sizeof(class), " %d NPC(s)", npcs);
	if(items)	Format(class, sizeof(class), "%s%s %d item(s)", class, npcs ? " and" : "", items);
	if(npcs+items) PrintToServer(">	Server was successfully cleaned!\n	Deleted:%s", class);
}

public Action AutoClear(Handle timer)
{
	CleaningMessage(0, RemoveItems(iLimit), Type_Item, true);
	return Plugin_Continue;
}

int RemoveItems(int limit = 0)
{
	static int num, del;
	num = del = 0;
	static char class[17];
	for(int i = MaxClients+1, max = GetMaxEntities(); i < max; i++)
	{
		if(!CheckEntity(i, class, sizeof(class)) || !IsValidItem(i, class))
			continue;

		num++;
		if(num > limit)
		{
			AcceptEntityInput(i, "Kill");
			del++;
		}
	}
	return del;
}

stock void CleaningMessage(const int client, int num, int type, const bool auto = false)
{
	if(!bReport) return;

	if(num > 1) type += 2;
	if(IsValidClient(client))
	{
		if(!num) PrintToChat(client, "%sThere is nothing to remove.", CHAT_PREFIX);
		else
		{
			PrintToChat(client, "%sRemoved \x04%d \x03%s.", CHAT_PREFIX, num, TYPE[type]);
			PrintToServer("%s'%N' has removed %d %s.", CON_PREFIX, client, num, TYPE[type]);
		}
	}
	else if(!client && !auto)
	{
		if(!num) PrintToServer("%sThere is nothing to remove.", CON_PREFIX);
		else PrintToServer("%sRemoved %d %s.", CON_PREFIX, num, TYPE[type]);
	}
}

stock bool CheckEntity(int entity, char[] clsname, int maxlength)
{
	return IsValidEntity(entity) && GetEntityClassname(entity, clsname, maxlength);
}

stock bool IsValidItem(int ent, char[] cls)
{
	return strlen(cls) > 3 && (!StrContains(cls, "prop_ragdoll")
		|| (GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity") == -1
		&& (!StrContains(cls, "bow_") || !StrContains(cls, "exp_") || !StrContains(cls, "fa_")
		|| !StrContains(cls, "item_") || !StrContains(cls, "me_") || !strcmp(cls, "projectile_arrow")
		|| !StrContains(cls, "tool_"))));
}

stock bool IsValidClient(int client)
{
	return 0 < client && client <= MaxClients && IsClientInGame(client);
}