#pragma semicolon 1

#include <sourcemod>
#include <morecolors>
#include <clientprefs>

public Plugin:myinfo =
{
	name        = "Advertisements",
	author      = "Deathreus",
	description = "Displays advertisements",
	version     = "1.0",
};

new g_iFrames                 = 0;
new g_iTickrate;
new HideAds[MAXPLAYERS + 1];
new bool:g_bTickrate          = true;
new bool:basecommExists       = false;
new Float:g_flTime;
new Handle:g_hAdvertisements  = INVALID_HANDLE;
new Handle:g_hEnabled;
new Handle:g_hInterval;
new Handle:g_hFile;
new Handle:g_hTimer;
new Handle:hCookie            = INVALID_HANDLE;
new String:sChatTag[32]       = "{green}[Advert]";

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetUserMessageType");
	
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_advertisements_version", "1.0", "Display advertisements", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled  = CreateConVar("sm_advertisements_enabled", "1", "Enable/disable displaying advertisements.");
	g_hFile     = CreateConVar("sm_advertisements_file", "advertisements.txt", "File to read the advertisements from.");
	g_hInterval = CreateConVar("sm_advertisements_interval", "70", "Amount of seconds between advertisements.");
	
	RegConsoleCmd("sm_toggleads", Command_ToggleAdverts);
	RegServerCmd("sm_advertisements_reload", Command_ReloadAds, "Reload the advertisements");

	HookConVarChange(g_hInterval, ConVarChange_Interval);
}

public OnAllPluginsLoaded()
{
	new Handle:Plugin_ClientPrefs = FindPluginByFile("clientprefs.smx");
	new PluginStatus:Plugin_ClientPrefs_Status = GetPluginStatus(Plugin_ClientPrefs);
	if ((Plugin_ClientPrefs == INVALID_HANDLE) || (Plugin_ClientPrefs_Status != Plugin_Running))
		LogError("This plugin requires clientprefs plugin to allow users to disable the trade chat.");
	else
	{
		hCookie = RegClientCookie("tradechat", "Hides trade chat", CookieAccess_Protected);
	}
	
	basecommExists = LibraryExists("basecomm");
	if (!basecommExists)
		LogMessage("Could not find 'basecomm' plugin.");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "basecomm"))
		basecommExists = true;
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "basecomm"))
		basecommExists = false;
}

public OnMapStart()
{	
	ParseAds();
	g_hTimer = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnGameFrame()
{
	if(g_bTickrate)
	{
		g_iFrames++;
		
		new Float:flTime = GetEngineTime();
		if(flTime >= g_flTime)
		{
			if(g_iFrames == g_iTickrate)
			{
				g_bTickrate = false;
			}
			else
			{
				g_iTickrate = g_iFrames;
				g_iFrames   = 0;    
				g_flTime    = flTime + 1.0;
			}
		}
	}
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(g_hTimer)
		KillTimer(g_hTimer);
	
	g_hTimer = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}

public Action:Command_ToggleAdverts(client, args)
{
	if (hCookie != INVALID_HANDLE)
	{
		new String:name[MAX_NAME_LENGTH], String:steamID[32];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, steamID, sizeof(steamID));
		if (!HideAds[client])
		{
			SetClientCookie(client, hCookie, "on");
			HideAds[client] = 1;
			CPrintToChat(client, "{green}[%s] {lightgreen}You {green}will not {lightgreen}see ads.", sChatTag);
		}
		else
		{
			SetClientCookie(client, hCookie, "off");
			HideAds[client] = 0;
			CPrintToChat(client, "{green}[%s] {lightgreen}You {green}will {lightgreen}see ads.", sChatTag);
		}
	}
	else
		CPrintToChat(client, "{green}[%s] {lightgreen}This option is currently unavailable.", sChatTag);
	
	return Plugin_Handled;
}

public Action:Command_ReloadAds(args)
{
	ParseAds();
	return Plugin_Handled;
}

public Action:Timer_DisplayAds(Handle:timer)
{
	if(!GetConVarBool(g_hEnabled))
		return;
	decl String:sText[256];
	KvGetString(g_hAdvertisements, "text",  sText,  sizeof(sText));
	
	if(!KvGotoNextKey(g_hAdvertisements))
	{
		KvRewind(g_hAdvertisements);
		KvGotoFirstSubKey(g_hAdvertisements);
	}
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if (!HideAds[i])
			{
				CPrintToChat(i, "%s %s", sChatTag, sText);
				/*switch (GetRandomInt(1,7))
				{
					case 1:
					{
						CPrintToChat(i, "{green}[%s] {blue}You can find our group at {lime}steamcommunity.com/groups/Deltacommanderssquad", sChatTag);
					}
					case 2:
					{
						CPrintToChat(i, "{green}[%s] {default}These ads annoying you?\nYou can turn me off with {olive}/toggleads{default}.", sChatTag);
					}
					case 3:
					{
						CPrintToChat(i, "{green}[%s] {lightgreen}Want to see a list of sounds to play for saysounds?\nType {olive}!soundlist{lightgreen}.", sChatTag);
					}
					case 4:
					{
						CPrintToChat(i, "{green}[%s] {default}These ads annoying you?\nYou can turn me off with {olive}/toggleads{default}.", sChatTag);
					}
					case 5:
					{
						CPrintToChat(i, "{green}[%s] {default}Want to play {blue}Dodgeball{default}, {red}FortWars{default}, {olive}PropHunt{default}, or even {darkgray}Boss Battles{default}?\nThen vote for which one you want! It will do all the work for you!", sChatTag);
					}
					case 6:
					{
						CPrintToChat(i, "{green}[%s] {default}!soundlist and !trails are available to {red}everyone {default}, so go nuts!", sChatTag);
					}
					case 7:
					{
						CPrintToChat(i, "{green}[%s] {default}These ads annoying you?\nYou can turn me off with {olive}/toggleads{default}.", sChatTag);
					}
				}*/
			}
		}
	}
}

ParseAds()
{
	if(g_hAdvertisements)
		CloseHandle(g_hAdvertisements);
	
	g_hAdvertisements = CreateKeyValues("Advertisements");
	
	decl String:sFile[256], String:sPath[256];
	GetConVarString(g_hFile, sFile, sizeof(sFile));
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	if(!FileExists(sPath))
		SetFailState("File Not Found: %s", sPath);
	
	FileToKeyValues(g_hAdvertisements, sPath);
	KvGotoFirstSubKey(g_hAdvertisements);
}

stock bool:IsValidClient(client, bool:bReplay = true)
{
	if(client <= 0
	|| client > MaxClients
	|| !IsClientInGame(client))
		return false;

	if(bReplay
	&& (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}