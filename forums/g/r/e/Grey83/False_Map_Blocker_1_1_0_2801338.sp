#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>

int
	iTime;
char
	sMap[64],
	sAdmin[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name		= "False Map Blocker",
	version		= "1.1.0",
	author		= "Swolly, Grey83",
	url			= "https://forums.alliedmods.net/showthread.php?t=342163"
}

public void OnPluginStart()
{
	AddCommandListener(Cmd_Map, "sm_map");
}

public Action Cmd_Map(int client, const char[] command, int args)
{
	if(args && client && CheckCommandAccess(client, "sm_map", ADMFLAG_CHANGEMAP))
	{
		if(iTime > GetTime())
		{
			PrintToChat(client, "[SM] Map change already initialized.");
			return Plugin_Stop;
		}

		char arg[32], map[64], current[64];
		GetCmdArg(1, arg, sizeof(arg));
		if(TrimString(arg) < 2)
			return Plugin_Stop;

		GetCurrentMap(current, sizeof(current));
		GetMapDisplayName(current, current, sizeof(current));

		ArrayList list = new ArrayList(ByteCountToCells(64));
		Handle dir = OpenDirectory("maps");
		FileType type;
		int len, start;
		while(ReadDirEntry(dir, map, sizeof(map), type))
			if(type == FileType_File && (len = strlen(map) - 4) > 0 && !strcmp(map[len], ".bsp", false))
			{
				map[len] = 0;
				if((start = FindCharInString(map, '/', true)) < 0) start = 0;

				if(StrContains(map[start], arg, false) != -1 && strcmp(map[start], current, false))
					list.PushString(map);
			}
		CloseHandle(dir);

		if(list.Length > 0)
		{
			Menu menu = new Menu(Handler_Menu);
			menu.SetTitle("Similar maps (%i):", list.Length);
			while(list.Length)
			{
				list.GetString(0, map, sizeof(map));
				if((start = FindCharInString(map, '/', true)) < 0) start = 0;
				menu.AddItem(map, map[start]);
				list.Erase(0);
			}
			menu.ExitButton = true;
			menu.Display(client, MENU_TIME_FOREVER);

			PrintToChat(client, "[SM] Select the map you want to open from the menu.");
		}
		else PrintToChat(client, "[SM] \x04Similar maps not found.");

		CloseHandle(list);

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public int Handler_Menu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		if(iTime > GetTime())
		{
			PrintToChat(client, "[SM] Map change already initialized.");
			return 0;
		}

		menu.GetItem(param, sMap, sizeof(sMap));

		PrintToChatAll("[SM] The %s map is forced by \x04%N\x01.", sMap, client);
		SetNextMap(sMap);

		SetCvar("mp_respawn_on_death_ct");
		SetCvar("mp_respawn_on_death_t");
		SetCvar("mp_timelimit");
		SetCvar("mp_maxrounds");

		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) > 1 && IsPlayerAlive(i))
			ForcePlayerSuicide(i);

		FormatEx(sAdmin, sizeof(sAdmin), "Changed by %L", client);
		iTime = GetTime() + 15;

		CreateTimer(1.0, Timer_ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
		Timer_ChangeMap(null);
	}
	else if(action == MenuAction_End) CloseHandle(menu);
	return 0;
}

public Action Timer_ChangeMap(Handle timer)
{
	int time = iTime - GetTime();
	if(time < 1) ForceChangeLevel(sMap, sAdmin);
	else
	{
		Event msg = CreateEvent("cs_win_panel_round");
		if(!msg)
			return Plugin_Continue;

		char buffer[128];
		FormatEx(buffer, sizeof(buffer), "Change map to '%s' in %i sec", sMap, time);
		msg.SetString("funfact_token", buffer);
		msg.Fire();
	}
	return Plugin_Continue;
}

void SetCvar(char[] name, int value = 0)
{
	Handle cvar = FindConVar(name);
	if(!cvar) return;

	int flags = GetConVarFlags(cvar);
	SetConVarFlags(cvar, (flags & ~FCVAR_NOTIFY));
	SetConVarInt(cvar, value);
	SetConVarFlags(cvar, flags);
}