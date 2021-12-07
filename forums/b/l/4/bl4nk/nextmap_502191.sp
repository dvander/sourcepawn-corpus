/*
NextMap Selector by pRED*, ferret

Port of nextmap.amxx from Amx Mod X.

Creates a cvar called sm_nextmap.
At intermission checks if sm_nextmap contains a valid map name and changes to that map.
Otherwise do nothing an let default map change happen.

Allow for admins to set the cvar to the map they want next and would go well with a map chooser menu plugin (port of mapchooser.amxx?)
*/
 
#include <sourcemod>
 
#define MAXMAPS 128
#define PLUGIN_VERSION "1.1"
 
new bool:g_bIntermissionCalled;
new UserMsg:g_umVGuiMenu;
 
new Handle:g_hMpChattime;
new Handle:g_hSmNextMap;
new Handle:g_hMpFriendlyfire;
new Handle:g_hMapCycleFile;
 
new String:g_szNextMap[32];
new g_iMapPosition = -1;
 
new String:g_szMapNames[MAXMAPS][32];
new g_iMapCount;
 
public Plugin:myinfo = 
{
	name = "Nextmap",
	author = "pRED*, ferret",
	description = "SM port of nextmap.amxx",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	LoadTranslations("plugin.nextmap");
	
	CreateConVar("sm_nextmap_version", PLUGIN_VERSION, "NextMap Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_umVGuiMenu = GetUserMessageId("VGUIMenu");
	HookUserMessage(g_umVGuiMenu, _g_umVGuiMenu);
	
	g_hMpChattime = FindConVar("mp_chattime")
	g_hMpFriendlyfire = FindConVar("mp_friendlyfire")
	g_hMapCycleFile = FindConVar("mapcyclefile")
	g_hSmNextMap = CreateConVar("sm_nextmap", "", "Sets the Next Map",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	HookConVarChange(g_hMapCycleFile, ConVarChange_Mapcyclefile);
	HookConVarChange(g_hSmNextMap, ConVarChange_Nextmap);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_InsSay);
	RegConsoleCmd("say_team", Command_Say);
	
	RegConsoleCmd("nextmap", Command_Nextmap);
	RegConsoleCmd("currentmap", Command_Currentmap);
	RegConsoleCmd("ff", Command_FF);
	RegConsoleCmd("listmaps", Command_List);
	
	decl String:szMapCycle[64];
	GetConVarString(g_hMapCycleFile, szMapCycle, 64);
	LoadMaps(szMapCycle);
	
	/* Set to the current map so OnMapStart() will know what to do */
	decl String:szCurrentMap[64];
	GetCurrentMap(szCurrentMap, 64);
	SetConVarString(g_hSmNextMap, szCurrentMap);
}
 
public OnMapStart()
{
	decl String:szLastMap[64], String:szCurrentMap[64];
	GetConVarString(g_hSmNextMap, szLastMap, 64);
	GetCurrentMap(szCurrentMap, 64);
	
	// Why am I doing this? If we switched to a new map, but it wasn't what we expected (Due to sm_map, sm_votemap, or
	// some other plugin/command), we don't want to scramble the map cycle. Or for example, admin switches to a custom map
	// not in mapcyclefile. So we keep it set to the last expected nextmap. - ferret
	if (strcmp(szLastMap, szCurrentMap) == 0)
	{
		FindAndSetNextMap();
	}
}
 
public OnMapEnd()
{
	g_bIntermissionCalled = false;
}
 
public ConVarChange_Mapcyclefile(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue, false) != 0)
	{
		LoadMaps(newValue);
	}
}
 
public ConVarChange_Nextmap(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_szNextMap, 64, newValue);
} 
 
public Action:Command_Say(client, args)
{
	new String:szText[30];
	GetCmdArgString(szText, sizeof(szText));
 
	if (StrEqual(szText, "\"nextmap\"") || StrEqual(szText, "\"/nextmap\""))
	{
		return Command_Nextmap(client,args)
	}
		
	if (StrEqual(szText, "\"currentmap\"") || StrEqual(szText, "\"/currentmap\"")) 
	{
		return Command_Currentmap(client,args);
 	}
	
	if (StrEqual(szText, "\"ff\"") || StrEqual(szText, "\"/ff\"")) 
	{
		return Command_FF(client,args);
	}
	
	return Plugin_Continue;
}

public Action:Command_InsSay(client, args)
{
	new String:szText[30];
	GetCmdArgString(szText, sizeof(szText));
 
	new startidx = 0;	
	if (szText[strlen(szText)-1] == '"')
	{
		szText[strlen(szText)-1] = '\0';
		startidx = 1;
	}	

	if (StrEqual(szText[startidx+4], "nextmap") || StrEqual(szText[startidx+4], "/nextmap"))
	{
		new String:szMap[32];
		getNextMapName(szMap, 31)
		
		PrintToChatAll("%T %s", "NEXT_MAP", LANG_SERVER, szMap);
		
		return Plugin_Continue;
	}
		
	if (StrEqual(szText[startidx+4], "currentmap") || StrEqual(szText[startidx+4], "/currentmap")) 
	{
		new String:szMap[32];
		GetCurrentMap(szMap, sizeof(szMap))
		
		PrintToChatAll("%T: %s","PLAYED_MAP", LANG_SERVER, szMap);

		return Plugin_Continue;
 	}
	
	if (StrEqual(szText[startidx+4], "ff") || StrEqual(szText[startidx+4], "/ff")) 
	{
		PrintToChatAll("%T: %s", "FRIEND_FIRE", LANG_SERVER, GetConVarInt(g_hMpFriendlyfire) ? "ON" : "OFF");

		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}
 
public Action:Command_Nextmap(client, args) 
{
	new String:szMap[32];
	getNextMapName(szMap, 31)
	
	PrintToChatAll("%T %s", "NEXT_MAP", LANG_SERVER, szMap);
	
	return Plugin_Continue;
}
 
 
public Action:Command_Currentmap(client, args) 
{
	new String:szMap[32];
	GetCurrentMap(szMap, sizeof(szMap))
	
	PrintToChatAll("%T: %s","PLAYED_MAP", LANG_SERVER, szMap);

	return Plugin_Continue;
}
 
public Action:Command_FF(client, args) 
{
	PrintToChatAll("%T: %s", "FRIEND_FIRE", LANG_SERVER, GetConVarInt(g_hMpFriendlyfire) ? "ON" : "OFF");

	return Plugin_Continue;
}
 
public Action:_g_umVGuiMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (g_bIntermissionCalled)
	{
		return Plugin_Handled;
	}
	
	new String:szType[10];
	BfReadString(bf, szType, sizeof(szType));
 
	if (BfReadByte(bf) == 1 && BfReadByte(bf) == 0 && (strcmp(szType, "scores", false) == 0))
	{
		g_bIntermissionCalled = true;
		
		decl String:szMap[32]
		new Float:fChattime = GetConVarFloat(g_hMpChattime);
		
		getNextMapName(szMap, 31)
		
		if (fChattime < 2.0)
			SetConVarFloat(g_hMpChattime, 2.0);
		
		new Handle:hDp;
		CreateDataTimer(fChattime - 1.0, Timer_ChangeMap, hDp);
		WritePackString(hDp, szMap);
	}
	
	return Plugin_Handled;
}
 
public Action:Timer_ChangeMap(Handle:timer, Handle:dp)
{
	new String:szMap[32];
	
	ResetPack(dp);
	ReadPackString(dp, szMap, sizeof(szMap));
 
	InsertServerCommand("changelevel \"%s\"", szMap);
	ServerExecute()
	
	LogMessage("Nextmap changed map to \"%s\"", szMap);
	
	return Plugin_Stop;
}
 
getNextMapName(String:szArg[], iMax)
{
	GetConVarString(g_hSmNextMap, szArg, iMax)
	
	if (IsMapValid(szArg)) return
	
	strcopy(szArg, iMax, g_szNextMap)
	
	SetConVarString(g_hSmNextMap, g_szNextMap)
	
	return
}
 
public Action:Command_List(client, args) 
{
	PrintToConsole(client, "Map Cycle:");
	
	for (new i = 0; i < g_iMapCount; i++)
	{
		PrintToConsole(client, "%s", g_szMapNames[i]);
	}
 
	return Plugin_Handled;
}
 
LoadMaps(const String:filename[])
{
	if (!FileExists(filename))
		return 0;
 
	new String:szText[32];
 
	new Handle:hMapFile = OpenFile(filename, "r");
	
	g_iMapCount = 0;
	g_iMapPosition = -1;
	
	while (g_iMapCount < MAXMAPS && !IsEndOfFile(hMapFile))
	{
		ReadFileLine(hMapFile, szText, sizeof(szText));
		TrimString(szText);
 
		if (szText[0] != ';' && strcopy(g_szMapNames[g_iMapCount], sizeof(g_szMapNames[]), szText) &&
			IsMapValid(g_szMapNames[g_iMapCount]))
		{
			++g_iMapCount;
		}
	}
 
	return g_iMapCount;
}
 
FindAndSetNextMap()
{
	if (g_iMapPosition == -1)
	{
		decl String:szCurrent[64];
		GetCurrentMap(szCurrent, 64);

		for (new i = 0; i < g_iMapCount; i++)
		{
			if (strcmp(szCurrent, g_szMapNames[i], false) == 0)
			{
				g_iMapPosition = i;
				break;
			}
		}
		
		if (g_iMapPosition == -1)
			g_iMapPosition = 0;
	}
	
	g_iMapPosition++;
	if (g_iMapPosition >= g_iMapCount)
		g_iMapPosition = 0;	
 
	strcopy(g_szNextMap, sizeof(g_szNextMap), g_szMapNames[g_iMapPosition]);
	SetConVarString(g_hSmNextMap,g_szNextMap);
}