/*
 *
 *	AutoChangeLevel
 *		
 *		Nicolous
 */
 
#include <sourcemod>

#define __VERSION__ "1.1"
 
new empty 

new Handle:acl_clientscount_limite
new Handle:acl_exclude_bots
new Handle:acl_time_before_changelevel
new Handle:acl_type_changelevel
new Handle:acl_type_2_map

public Plugin:myinfo = 
{
	name = "AutoChangeLevel",
	author = "Nicolous",
	description = "Change the level if there are no or one player on the server",
	version = __VERSION__,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("autochangelevel_version",__VERSION__,"Currently version of the Nicolous's AutoChangeLevel plugin",FCVAR_REPLICATED|FCVAR_NOTIFY)

	acl_clientscount_limite = CreateConVar("autochangelevel_clientscount_limite","1","AutoChangeLevel : number of players in lower part (and from) of which a changelevel is considered",_,true,1.0,false,0.0)
	acl_exclude_bots = CreateConVar("autochangelevel_exclude_bots","0","AutoChangeLevel : 1 = exclude the bots, 0 = bots are counted", _,true,0.0,true,1.0)
	acl_time_before_changelevel = CreateConVar("autochangelevel_time_before_changelevel","15","AutoChangeLevel : time (in minutes) before changelevel (0 = off)", _,true,0.0,false,1.0)
	acl_type_changelevel = CreateConVar("autochangelevel_type_changelevel","0","AutoChangeLevel : 0 = nextmap (mapcyclefile), 1 = current map (reset timeleft), 2 = map provided by acl_type_2_map ConVar",_,true,0.0,true,3.0)
	acl_type_2_map = CreateConVar("autochangelevel_type_2_map","de_dust2","AutoChangeLevel : if acl_type_changelevel is 2, map loaded at the auto-changelevel")

	empty = 0

	CreateTimer(60.0, checkPlayerCount, _, TIMER_REPEAT)
}

public OnMapStart()
{
	empty = 0

	AutoExecConfig()
}

ChangeToNextmap()
{
	new Handle:mapcyclefile = FindConVar("mapcyclefile")
	new String:mapcyclename[32]
	GetConVarString(mapcyclefile, mapcyclename, sizeof(mapcyclename))
	
	if (FileExists(mapcyclename))
	{
		new Handle:f = OpenFile(mapcyclename, "r")
		
		new String:nextmap[32]
		strcopy(nextmap,sizeof(nextmap),"aucune")
		new String:line[32]
		new String:currentMap[32]
		GetCurrentMap(currentMap,sizeof(currentMap))
		
		while (!IsEndOfFile(f))
		{
			ReadFileLine(f,line,sizeof(line))
			TrimString(line)
			if (StrEqual(line,currentMap))
			{
				if (!IsEndOfFile(f))
				{
					ReadFileLine(f,nextmap,sizeof(nextmap))
					TrimString(nextmap)
					if (IsMapValid(nextmap))
					{
						ServerCommand("changelevel %s", nextmap)
						break
					}
				}
				else
				{
					FileSeek(f,0,SEEK_SET)
					ReadFileLine(f,nextmap,sizeof(nextmap))
					TrimString(nextmap)
					PrintToChatAll("nextmap = %s", nextmap)
					if (IsMapValid(nextmap))
					{
						ServerCommand("changelevel %s",nextmap)
						break
					}
				}
			}
		}
		if (StrEqual(nextmap,"aucune"))
			PrintToServer("AutoChangeLevel : Unable to changelevel from \"%s\"",mapcyclefile)
			
		CloseHandle(f)
	}
	else
		PrintToServer("AutoChangeLevel : Unable to find \"%s\"",mapcyclefile)
}

public Action:checkPlayerCount(Handle:timer)
{
	if (GetConVarInt(acl_exclude_bots) == 0)
	{
		if (GetClientCount() <= GetConVarInt(acl_clientscount_limite))
			empty++
		else
			empty = 0
	}
	else
	{
		new maxClients = GetMaxClients()
		new joueurs = 0
		for (new i=1;i<maxClients;i++)
		{
			if (IsClientConnected(i))
				if (!IsFakeClient(i))
					joueurs++
		}
		if (joueurs <= GetConVarInt(acl_clientscount_limite))
			empty++
		else
			empty = 0
	}
	if (empty >= GetConVarInt(acl_time_before_changelevel))
	{
		if (GetConVarInt(acl_type_changelevel) == 0)
		{
			ChangeToNextmap()
		}
		else if (GetConVarInt(acl_type_changelevel) == 1)
		{
			new String:currentMap[32]
			GetCurrentMap(currentMap,sizeof(currentMap))
			ServerCommand("changelevel %s",currentMap)
		}
		else
		{
			new String:nextmap[32]
			GetConVarString(acl_type_2_map,nextmap,sizeof(nextmap))
			if (IsMapValid(nextmap))
				ServerCommand("changelevel %s",nextmap)
			else
				PrintToServer("AutoChangeLevel : Unable to load map %s",nextmap)
		}
	}	
	return Plugin_Continue
}
