/*
NextMap Selector by pRED*

Overly simplified port of nextmap.amxx from Amx Mod X.

Creates a cvar called sm_nextmap.
At intermission checks if sm_nextmap contains a valid map name and changes to that map.
Otherwise do nothing an let default map change happen.

Allow for admins to set the cvar to the map they want next and would go well with a map chooser menu plugin (port of mapchooser.amxx?)
*/

#include <sourcemod>

new bool:IsIntermissionCalled;
new UserMsg:VGuiMenu;

new Handle:g_cvar_chattime;
new Handle:g_cvar_nextmap;
new Handle:g_cvar_ff;
new Handle:g_cvar_mapcyclefile;
new Handle:g_cvar_lastmapcycle;
new Handle:g_cvar_lastpos;

new String:g_nextMap[32]
new String:g_mapCycle[32]
new g_pos

public Plugin:myinfo = 
{
	name = "Nextmap",
	author = "pRED*",
	description = "SM port of nextmap.amxx",
	version = "0.1",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	VGuiMenu = GetUserMessageId("VGUIMenu");
	HookUserMessage(VGuiMenu, _VGuiMenu);
    
	g_cvar_chattime = 		FindConVar("mp_chattime")
	g_cvar_ff = 			FindConVar("mp_friendlyfire")
	g_cvar_mapcyclefile = 	FindConVar("mapcyclefile")
	g_cvar_nextmap = 		CreateConVar("sm_nextmap", "", "Sets the Next Map")
	g_cvar_lastmapcycle = 	CreateConVar("sm_lastmapcycle","","Stores the mapcycle file name")
	g_cvar_lastpos = 		CreateConVar("sm_lastpos","","Stores the last position in the mapcycle")
    
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	RegConsoleCmd("nextmap", Cmd_Nextmap);
	RegConsoleCmd("currentmap", Cmd_Currentmap);
	RegConsoleCmd("ff", Cmd_FF);
	
	LoadTranslations("plugin.nextmap.cfg");

	new String:szString[32]
	
	GetConVarString(g_cvar_lastmapcycle,szString,31)
	g_pos=GetConVarInt(g_cvar_lastpos)
	GetConVarString(g_cvar_mapcyclefile,g_mapCycle,31)


	if (!StrEqual(g_mapCycle, szString))
		g_pos = 0	// mapcyclefile has been changed - go from first

	readMapCycle(g_mapCycle, g_nextMap, 31)
	SetConVarString(g_cvar_nextmap,g_nextMap)
	SetConVarString(g_cvar_lastmapcycle,g_mapCycle)
	SetConVarInt(g_cvar_lastpos,g_pos)
}

public Action:Command_Say(client, args) {
	new String:text[30];
	GetCmdArgString(text, sizeof(text));
	new startidx = TrimQuotes(text);

	if (StrEqual(text[startidx], "nextmap") || (StrEqual(text[startidx], "/nextmap")))
	{
		Cmd_Nextmap(client,args)
		
		return Plugin_Continue;
	}
		
	if (StrEqual(text[startidx], "currentmap") || StrEqual(text[startidx], "/currentmap")) 
	{
		return Cmd_Currentmap(client,args);
	}
	
	if (StrEqual(text[startidx], "ff") || StrEqual(text[startidx], "/ff")) 
	{
		return Cmd_FF(client,args);
	}
	
	return Plugin_Continue;
}

public Action:Cmd_Nextmap(client, args) 
{
	new String:map[32];
	getNextMapName(map, 31)
	
	new maxClients = GetMaxClients();
	
	for (new i = 1; i <= maxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PrintToChat(i, "%L %s","NEXT_MAP",client,map);
		}
	}

	return Plugin_Handled;
}

public Action:Cmd_Currentmap(client, args) 
{
	new String:map[32];
	GetCurrentMap(map,sizeof(map))
	
	new maxClients = GetMaxClients();
	
	for (new i = 1; i <= maxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PrintToChat(i, "%L: %s","PLAYED_MAP",client,map);
		}
	}

	return Plugin_Handled;
}

public Action:Cmd_FF(client, args) 
{
	new maxClients = GetMaxClients();
	
	for (new i = 1; i <= maxClients; i++)
	{
		if (IsClientInGame(i))
		{
			PrintToChat(i, "%L: %s","FRIEND_FIRE",client, GetConVarInt(g_cvar_ff) ? "ON" : "OFF");
		}
	}

	return Plugin_Handled;
}


public Action:_VGuiMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    if(IsIntermissionCalled)
    {
        return Plugin_Handled;
    }

    new String:Type[10];
    BfReadString(bf, Type, sizeof(Type));

    if(strcmp(Type, "scores", false) == 0)
    {
        if(BfReadByte(bf) == 1 && BfReadByte(bf) == 0)
        {
			IsIntermissionCalled = true;
            
			decl String:string[32]
			new Float:chattime = GetConVarFloat(g_cvar_chattime);
			
			getNextMapName(string, 31)
			
			if (!IsMapValid(string))
			{
				return Plugin_Handled;
			}
	
			SetConVarFloat(g_cvar_chattime,chattime + 20.0); // make sure mp_chattime is long
	
			new Handle:dp;
			CreateDataTimer(chattime-0.1, Timer_ChangeMap, dp);
			WritePackString(dp, string);
        }
    }
    
    return Plugin_Handled;
}

public Action:Timer_ChangeMap(Handle:timer, Handle:dp)
{
	new String:map[32];
	
	ResetPack(dp);
	ReadPackString(dp, map, sizeof(map));
	
	SetConVarFloat(g_cvar_chattime,GetConVarFloat(g_cvar_chattime) - 20.0);

	ServerCommand("changelevel \"%s\"", map);
	
	LogMessage("Nextmap changed map to \"%s\"", map);
	
	return Plugin_Stop;
}

public OnMapEnd()
{
    IsIntermissionCalled = false;
}

stock TrimQuotes(String:text[]) {
	new startidx = 0;
	if (text[0] == '"') {
		new len = strlen(text);
		if (text[len-1] == '"') {
			startidx = 1;
			text[len-1] = '\0';
		}
	}
	return startidx;
}

readMapCycle(String:szFileName[], String:szNext[], iNext)
{
	new iMaps = 0
	new String:szBuffer[32], String:szFirst[32]

	new Handle:file = OpenFile(szFileName, "rt");
	
	if (file == INVALID_HANDLE) 
	{
		return;
	}

	while (!IsEndOfFile(file) && ReadFileLine(file, szBuffer, sizeof(szBuffer)))
	{
		if (!isalnum(szBuffer[0]) || !IsMapValid(szBuffer)) continue
		
		if (!iMaps)
			strcopy(szFirst, 31, szBuffer)
		
		if (++iMaps > g_pos)
		{
			strcopy(szNext, iNext, szBuffer)
			g_pos = iMaps
			
			CloseHandle(file);
			
			return
		}
	}

	if (!iMaps)
	{
		LogMessage("WARNING: Couldn't find a valid map or the file doesn't exist (file \"%s\")", szFileName)
		GetCurrentMap(szFirst,31)
	}

	strcopy(szNext, iNext, szFirst)
	g_pos = 1
	
	CloseHandle(file);
}

stock bool:isalnum(chr)
{
	if (IsCharAlpha(chr) || IsCharNumeric(chr))
		return true;
		
	return false;
}

getNextMapName(String:szArg[], iMax)
{
	GetConVarString(g_cvar_nextmap,szArg,iMax)
	
	if (IsMapValid(szArg)) return
	
	strcopy(szArg, iMax, g_nextMap)
	
	SetConVarString(g_cvar_nextmap,g_nextMap)
	
	return
}