#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Player Whitelist",
	author = "Stevo.TVR",
	description = "Restricts server to SteamIDs listed in the whitelist",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org/"
}

// maximum SteamIDs the plugin can handle; increase value as needed
#define WHITELIST_MAX 255

new Handle:sm_whitelist_enable = INVALID_HANDLE;
new Handle:sm_whitelist_immunity = INVALID_HANDLE;

new String:whitelist[WHITELIST_MAX][64];
new listlen;

public OnPluginStart()
{
	CreateConVar("sm_whitelist_version", PLUGIN_VERSION, "Server Whitelist plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	sm_whitelist_enable = CreateConVar("sm_whitelist_enable", "1", "Enable server whitelist", _, true, 0.0, true, 1.0);
	sm_whitelist_immunity = CreateConVar("sm_whitelist_immunity", "1", "Automatically grant admins access", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "whitelist");
	
	RegAdminCmd("sm_whitelist_reload", CommandReload, ADMFLAG_GENERIC, "Reloads server whitelist");
	RegAdminCmd("sm_whitelist_list", CommandList, ADMFLAG_GENERIC, "List all SteamIDs in whitelist");
	RegAdminCmd("sm_whitelist_add", CommandAdd, ADMFLAG_CONVARS, "Adds a SteamID to the whitelist");
	
	HookConVarChange(sm_whitelist_enable, OnEnableChange);
	
	LoadList();
}

public OnClientPostAdminCheck(client)
{
	if(GetConVarBool(sm_whitelist_enable) && !IsFakeClient(client) && !IsImmune(client))
	{
		new String:auth[64];
		GetClientAuthString(client, auth, sizeof(auth));
		new bool:allow = false;
		for(new i; i < listlen; i++)
		{
			if(strcmp(auth, whitelist[i]) == 0)
			{
				allow = true;
				break;
			}
		}
		
		if(!allow)
		{
			KickClient(client, "%s is not listed on the server whitelist", auth);
		}
	}
}

public OnEnableChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(StringToInt(newVal) > 0)
	{
		LoadList();
	}
}

public Action:CommandReload(client, args)
{
	LoadList();
	ReplyToCommand(client, "[Whitelist] %d SteamIDs loaded from whitelist", listlen);
	return Plugin_Handled;
}

public Action:CommandList(client, args)
{
	PrintToConsole(client, "[Whitelist] Listing current whitelist (%d items):", listlen);
	for(new i; i < listlen; i++)
	{
		PrintToConsole(client, "%s", whitelist[i]);
	}
	return Plugin_Handled;
}

public Action:CommandAdd(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_whitelist_add <steamid>");
		return Plugin_Handled;
	}
	new String:steamid[64];
	GetCmdArg(1, steamid, sizeof(steamid));
	TrimString(steamid);
	
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(PathType:Path_SM, path, sizeof(path), "configs/whitelist.txt");
	
	new Handle:file = OpenFile(path, "a");
	if(file != INVALID_HANDLE)
	{
		WriteFileLine(file, steamid);
		whitelist[listlen] = steamid;
		listlen++;
		
		ReplyToCommand(client, "[SM] %s successfully added to whitelist", steamid);
	}
	else
	{
		ReplyToCommand(client, "[SM] Failed to open %s for writing", path);
	}
	CloseHandle(file);
	
	return Plugin_Handled;
}

public LoadList()
{
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(PathType:Path_SM, path, sizeof(path), "configs/whitelist.txt");
	
	new Handle:file = OpenFile(path, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("[Whitelist] Unable to read file %s", path);
	}
	
	listlen = 0;
	new String:steamid[64];
	while(!IsEndOfFile(file) && ReadFileLine(file, steamid, sizeof(steamid)))
	{
		if (steamid[0] == ';' || !IsCharAlpha(steamid[0]))
		{
			continue;
		}
		new len = strlen(steamid);
		for (new i; i < len; i++)
		{
			if (IsCharSpace(steamid[i]) || steamid[i] == ';')
			{
				steamid[i] = '\0';
				break;
			}
		}
		whitelist[listlen] = steamid;
		listlen++;
	}
	
	CloseHandle(file);
}

public IsImmune(client)
{
	new bool:immune = false;
	if(GetConVarBool(sm_whitelist_immunity))
	{
		if(GetUserAdmin(client) != INVALID_ADMIN_ID)
		{
			immune = true;
		}
	}
	return immune;
}