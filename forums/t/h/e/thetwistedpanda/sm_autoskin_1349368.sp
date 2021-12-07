/*
	v2.0.3
	------
	- Cleaned up aging / baddie code.
	- Increased total of hardcoded commands to 20.
	- Flag cvars sm_autoskin_tier_* have been renamed to sm_autoskin_tier_*_flag.
	- Added override cvars sm_autoskin_tier_*_override.
	- Replaced auth system with proper CheckCommandAccess using sm_autoskin_tier_*_override and sm_autoskin_tier_*_flag. 
	- Fixed a bug with multiple skins in a single tier only verifying the first skin index.
	- Fixed a bug where clients were never actually given tier_none status on initial connect if it was enabled.
	- Fixed a bug where if a client had authed and spawned prior to loading cookies, their skin was forced.
	- Fixed a bug where when removing a skin, if tier none wasn't forced or enabled, clients didn't receive a default skin.
	- Fixed phrasing on sm_autoskin_bots and modified it so it can actually work properly.
	
	
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "2.0.3"
#define PLUGIN_PREFIX "\x04Skins: \x03"

#define NUM_TIERS 6
#define NUM_PATHS 8

#define ACCESS_NO_ACCESS -1
#define ACCESS_TIER_ONE 0
#define ACCESS_TIER_TWO 1
#define ACCESS_TIER_THREE 2
#define ACCESS_TIER_FOUR 3
#define ACCESS_TIER_FIVE 4
#define ACCESS_TIER_NONE 5

#define TEAM_NONE 0
#define TEAM_SPEC 1
#define TEAM_RED 2
#define TEAM_BLUE 3

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hDefault = INVALID_HANDLE;
new Handle:g_hBots = INVALID_HANDLE;
new Handle:g_hDelay = INVALID_HANDLE;
new Handle:g_hCommands = INVALID_HANDLE;
new Handle:g_hAllowed = INVALID_HANDLE;
new Handle:g_hFlag[NUM_TIERS] = { INVALID_HANDLE, ... };
new Handle:g_hOverride[NUM_TIERS] = { INVALID_HANDLE, ... };
new Handle:g_hPathT[NUM_TIERS] = { INVALID_HANDLE, ... };
new Handle:g_hPathCT[NUM_TIERS] = { INVALID_HANDLE, ... };
new Handle:g_hForced[NUM_TIERS] = { INVALID_HANDLE, ... };
new Handle:g_hCookie = INVALID_HANDLE;
new Handle:g_hTrie = INVALID_HANDLE;
new Handle:g_hTimer_Changable = INVALID_HANDLE;

new g_iTeam[MAXPLAYERS + 1];
new g_iClientAccess[MAXPLAYERS + 1];
new bool:g_bAppear[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bLoaded[MAXPLAYERS + 1];

new bool:g_bLateLoad = true, bool:g_bEnabled = true, bool:g_bDefault, bool:g_bForced[NUM_TIERS], bool:g_bRedAvailable[NUM_TIERS][NUM_PATHS], bool:g_bBlueAvailable[NUM_TIERS][NUM_PATHS], bool:g_bChangable = true, bool:g_bValidSkin[NUM_TIERS];
new g_iBots, g_iFlag[NUM_TIERS], g_iRedTotal[NUM_TIERS], g_iBlueTotal[NUM_TIERS];
new Float:g_fDelay, Float:g_fAllowed;
new String:g_sOverride[NUM_TIERS][32], String:g_sRedPaths[NUM_TIERS][NUM_PATHS][PLATFORM_MAX_PATH], String:g_sBluePaths[NUM_TIERS][NUM_PATHS][PLATFORM_MAX_PATH], String:g_sCommands[20][24];

static const String:g_sBlueModels[4][] = 
{
	"models/player/ct_urban.mdl",
	"models/player/ct_gsg9.mdl",
	"models/player/ct_sas.mdl",
	"models/player/ct_gign.mdl"
};

static const String:g_sRedModels[4][] = 
{
	"models/player/t_phoenix.mdl",
	"models/player/t_leet.mdl",
	"models/player/t_arctic.mdl",
	"models/player/t_guerilla.mdl"
};

public Plugin:myinfo =
{
	name = "Auto Skin", 
	author = "Twisted|Panda", 
	description = "Provides simple functionality for applying skins to players automatically.", 
	version = PLUGIN_VERSION, 
	url = "http://ominousgaming.com"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("sm_autoskin.phrases");

	CreateConVar("sm_autoskin_version", PLUGIN_VERSION, "Auto Skin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("sm_autoskin_enable", "1.0", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hBots = CreateConVar("sm_autoskin_bots", "-1", "Default access level for bots. (-1 = Disabled, 0 - 4 = Tiers One through Five)", FCVAR_NONE, true, -1.0, true, 5.0);
	g_hDefault = CreateConVar("sm_autoskin_default", "1.0", "Controls how data is assigned for new players. (0 = Skins start disabled, 1 = Skins start enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hDelay = CreateConVar("sm_autoskin_delay", "0.1", "Controls how long after a player spawns that their skin is applied.", FCVAR_NONE, true, 0.0);
	g_hCommands = CreateConVar("sm_autoskin_commands", "!skins, /skins, !skin, /skin", "The commands that can be used to access Auto Skin's menu, separated by \", \", up to 8 commands allowed.", FCVAR_NONE);
	g_hAllowed = CreateConVar("sm_autoskin_allowed", "30.0", "The number of seconds after the round starts that they're subject to skin changes (be it via sm_autoskin_commands or player_spawn being fired)", FCVAR_NONE, true, 0.0);

	g_hFlag[0] = CreateConVar("sm_autoskin_tier_one_flag", "p", "Flag checked against the client if client does not possess defined override.", FCVAR_NONE);
	g_hOverride[0] = CreateConVar("sm_autoskin_tier_one_override", "", "Override checked against the client for access to the Tier 1 skin. (\"\" = Disabled)", FCVAR_NONE);
	g_hPathT[0] = CreateConVar("sm_autoskin_tier_one_t", "", "Path to player model, access level == sm_autoskin_tier_one. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hPathCT[0] = CreateConVar("sm_autoskin_tier_one_ct", "", "Path to player model, access level == sm_autoskin_tier_one. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hForced[0] = CreateConVar("sm_autoskin_tier_one_forced", "0", "Controls whether or not this tier's skin will be forced upon clients with appropriate access.", FCVAR_NONE, true, 0.0, true, 1.0);

	g_hFlag[1] = CreateConVar("sm_autoskin_tier_two_flag", "q", "Flag checked against the client if client does not possess defined override.", FCVAR_NONE);
	g_hOverride[1] = CreateConVar("sm_autoskin_tier_two_override", "", "Override checked against the client for access to the Tier 2 skin. (\"\" = Disabled)", FCVAR_NONE);
	g_hPathT[1] = CreateConVar("sm_autoskin_tier_two_t", "", "Path to player model, access level == sm_autoskin_tier_two. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hPathCT[1] = CreateConVar("sm_autoskin_tier_two_ct", "", "Path to player model, access level == sm_autoskin_tier_two. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hForced[1] = CreateConVar("sm_autoskin_tier_two_forced", "0", "Controls whether or not this tier's skin will be forced upon clients with appropriate access.", FCVAR_NONE, true, 0.0, true, 1.0);

	g_hFlag[2] = CreateConVar("sm_autoskin_tier_three_flag", "r", "Flag checked against the client if client does not possess defined override.", FCVAR_NONE);
	g_hOverride[2] = CreateConVar("sm_autoskin_tier_three_override", "", "Override checked against the client for access to the Tier 3 skin. (\"\" = Disabled)", FCVAR_NONE);
	g_hPathT[2] = CreateConVar("sm_autoskin_tier_three_t", "", "Path to player model, access level == sm_autoskin_tier_three. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hPathCT[2] = CreateConVar("sm_autoskin_tier_three_ct", "", "Path to player model, access level == sm_autoskin_tier_three. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hForced[2] = CreateConVar("sm_autoskin_tier_three_forced", "0", "Controls whether or not this tier's skin will be forced upon clients with appropriate access.", FCVAR_NONE, true, 0.0, true, 1.0);

	g_hFlag[3] = CreateConVar("sm_autoskin_tier_four_flag", "s", "Flag checked against the client if client does not possess defined override.", FCVAR_NONE);
	g_hOverride[3] = CreateConVar("sm_autoskin_tier_four_override", "", "Override checked against the client for access to the Tier 4 skin. (\"\" = Disabled)", FCVAR_NONE);
	g_hPathT[3] = CreateConVar("sm_autoskin_tier_four_t", "", "Path to player model, access level == sm_autoskin_tier_four. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hPathCT[3] = CreateConVar("sm_autoskin_tier_four_ct", "", "Path to player model, access level == sm_autoskin_tier_four. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hForced[3] = CreateConVar("sm_autoskin_tier_four_forced", "0", "Controls whether or not this tier's skin will be forced upon clients with appropriate access.", FCVAR_NONE, true, 0.0, true, 1.0);

	g_hFlag[4] = CreateConVar("sm_autoskin_tier_five_flag", "t", "Flag checked against the client if client does not possess defined override.", FCVAR_NONE);
	g_hOverride[4] = CreateConVar("sm_autoskin_tier_five_override", "", "Override checked against the client for access to the Tier 5 skin. (\"\" = Disabled)", FCVAR_NONE);
	g_hPathT[4] = CreateConVar("sm_autoskin_tier_five_t", "", "Path to player model, access level == sm_autoskin_tier_five. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hPathCT[4] = CreateConVar("sm_autoskin_tier_five_ct", "", "Path to player model, access level == sm_autoskin_tier_five. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hForced[4] = CreateConVar("sm_autoskin_tier_five_forced", "0", "Controls whether or not this tier's skin will be forced upon clients with appropriate access.", FCVAR_NONE, true, 0.0, true, 1.0);

	g_hFlag[5] = CreateConVar("sm_autoskin_tier_none", "0", "If enabled, players without access to any other tier will be assigned tier none models.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hPathT[5] = CreateConVar("sm_autoskin_tier_none_t", "", "Path to player model, access level == none. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hPathCT[5] = CreateConVar("sm_autoskin_tier_none_ct", "", "Path to player model, access level == none. (\"\" Disables, separate multiple paths with \", \")", FCVAR_NONE);
	g_hForced[5] = CreateConVar("sm_autoskin_tier_none_forced", "0", "Controls whether or not this tier's skin will be forced upon clients with appropriate access.", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sm_autoskin");

	HookConVarChange(g_hEnabled, Action_OnSettingsChange);
	HookConVarChange(g_hDelay, Action_OnSettingsChange);
	HookConVarChange(g_hBots, Action_OnSettingsChange);
	HookConVarChange(g_hDefault, Action_OnSettingsChange);
	HookConVarChange(g_hCommands, Action_OnSettingsChange);
	HookConVarChange(g_hAllowed, Action_OnSettingsChange);
	
	g_hTrie = CreateTrie();
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");

	SetCookieMenuItem(Menu_Cookies, 0, "Skin Settings");
	g_hCookie = RegClientCookie("AutoSkin_Status", "Auto Skin: The client's skin status.", CookieAccess_Protected);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);
	
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_iBots = GetConVarInt(g_hBots);
	g_bDefault = GetConVarBool(g_hDefault);
	g_fDelay = GetConVarFloat(g_hDelay);
	g_fAllowed = GetConVarFloat(g_hAllowed);

	decl String:sBuffer[256];
	GetConVarString(g_hCommands, sBuffer, sizeof(sBuffer));
	ClearTrie(g_hTrie);
	new iCount = ExplodeString(sBuffer, ", ", g_sCommands, sizeof(g_sCommands), sizeof(g_sCommands[]));
	for(new i = 0; i < iCount; i++)
		SetTrieValue(g_hTrie, g_sCommands[i], iCount);
}

public OnMapStart()
{
	if(g_bEnabled)
	{
		Define_Downloads();

		for(new i = 0; i <= 3; i++)
		{
			PrecacheModel(g_sRedModels[i], true);
			PrecacheModel(g_sBlueModels[i], true);
		}
	}
}

public OnMapEnd()
{
	if(g_hTimer_Changable != INVALID_HANDLE && CloseHandle(g_hTimer_Changable))
	{
		g_hTimer_Changable = INVALID_HANDLE;
		g_bChangable = true;
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Define_Skins();

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i);

					if(!IsFakeClient(i))
					{
						g_iClientAccess[i] = ACCESS_NO_ACCESS;

						for(new j = ACCESS_TIER_ONE; j <= ACCESS_TIER_FIVE; j++)
						{
							if(!g_bValidSkin[j])
								continue;
							
							if(CheckCommandAccess(i, g_sOverride[j], g_iFlag[j]))
							{
								g_iClientAccess[i] = j;
								break;
							}
						}
						
						if(g_iClientAccess[i] == ACCESS_NO_ACCESS && g_iFlag[ACCESS_TIER_NONE])
							g_iClientAccess[i] = ACCESS_TIER_NONE;

						if(!g_bLoaded[i] && AreClientCookiesCached(i))
							Define_Cookies(i);
	
						if(g_bAppear[i] && g_iClientAccess[i] != ACCESS_NO_ACCESS)
							CreateTimer(g_fDelay, Timer_Apply, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						g_iClientAccess[i] = g_iBots;
						g_bAppear[i] = true;
						g_bLoaded[i] = true;
						
						if(g_iClientAccess[i] != ACCESS_NO_ACCESS)
							CreateTimer(g_fDelay, Timer_Apply, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		if(IsFakeClient(client))
		{
			g_iClientAccess[client] = g_iBots;
			g_bAppear[client] = true;
			g_bLoaded[client] = true;
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(g_bEnabled)
	{
		if(!IsFakeClient(client))
		{
			g_iClientAccess[client] = ACCESS_NO_ACCESS;

			for(new i = ACCESS_TIER_ONE; i <= ACCESS_TIER_FIVE; i++)
			{
				if(!g_bValidSkin[i])
					continue;
				
				if(CheckCommandAccess(client, g_sOverride[i], g_iFlag[i]))
				{
					g_iClientAccess[client] = i;
					break;
				}
			}

			if(g_iClientAccess[client] == ACCESS_NO_ACCESS && g_iFlag[ACCESS_TIER_NONE])
				g_iClientAccess[client] = ACCESS_TIER_NONE;

			if(!g_bLoaded[client] && AreClientCookiesCached(client))
				Define_Cookies(client);

			if(g_bAppear[client] && g_iClientAccess[client] != ACCESS_NO_ACCESS && g_bAlive[client])
				CreateTimer(g_fDelay, Timer_Apply, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bAlive[client] = false;
		g_bLoaded[client] = false;
	}
}

public OnClientCookiesCached(client)
{
	if(!g_bLoaded[client] && g_iClientAccess[client] != ACCESS_NO_ACCESS)
	{
		Define_Cookies(client);

		if(g_bAppear[client] && g_bAlive[client])
			CreateTimer(g_fDelay, Timer_Apply, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Command_Say(client, const String:command[], argc)
{
	if(g_bEnabled)
	{
		if(!client || !IsClientInGame(client) || g_iClientAccess[client] == ACCESS_NO_ACCESS || g_bForced[g_iClientAccess[client]])
			return Plugin_Continue;

		decl String:sText[192], String:sBuffer[24];
		GetCmdArgString(sText, sizeof(sText));

		new iStart;
		if(sText[strlen(sText) - 1] == '"')
		{
			sText[strlen(sText) - 1] = '\0';
			iStart = 1;
		}

		BreakString(sText[iStart], sBuffer, sizeof(sBuffer));
		if(GetTrieValue(g_hTrie, sBuffer, iStart))
		{
			Menu_Skins(client);
			return Plugin_Stop;
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= TEAM_SPEC)
			return Plugin_Continue;

		g_bAlive[client] = true;
		if(g_iClientAccess[client] != ACCESS_NO_ACCESS && g_bAppear[client])
			CreateTimer(g_fDelay, Timer_Apply, userid);
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_bAlive[client] = false;
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] <= TEAM_SPEC)
			g_bAlive[client] = false;
		else if(g_iClientAccess[client] != ACCESS_NO_ACCESS && g_bAppear[client])
			CreateTimer(g_fDelay, Timer_Apply, userid);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bChangable = true;
		if(g_fAllowed > 0.0)
			g_hTimer_Changable = CreateTimer(g_fAllowed, Timer_Changable, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bChangable = true;
		if(g_hTimer_Changable != INVALID_HANDLE && CloseHandle(g_hTimer_Changable))
			g_hTimer_Changable = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action:Timer_Apply(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client) && g_bAlive[client])
	{
		switch(g_iTeam[client])
		{
			case TEAM_RED:
			{
				if(g_iRedTotal[g_iClientAccess[client]])
				{
					new iTemp = GetRandomInt(0, (g_iRedTotal[g_iClientAccess[client]] - 1));
					if(g_bRedAvailable[g_iClientAccess[client]][iTemp])
						SetEntityModel(client, g_sRedPaths[g_iClientAccess[client]][iTemp]);
				}
			}
			case TEAM_BLUE:
			{
				if(g_iBlueTotal[g_iClientAccess[client]])
				{
					new iTemp = GetRandomInt(0, (g_iBlueTotal[g_iClientAccess[client]] - 1));
					if(g_bBlueAvailable[g_iClientAccess[client]][iTemp])
						SetEntityModel(client, g_sBluePaths[g_iClientAccess[client]][iTemp]);
				}
			}
		}
	}
}

public Action:Timer_Changable(Handle:timer)
{
	g_hTimer_Changable = INVALID_HANDLE;
	g_bChangable = false;
}	

bool:Bool_Check(const String:_sTemp[])
{
	if(StrEqual(_sTemp, "") || !FileExists(_sTemp))
		return false;
		
	return true;
}

public Menu_Cookies(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) 
{
	switch(action)
	{
		case CookieMenuAction_DisplayOption:
			Format(buffer, maxlen, "Skin Settings");
		case CookieMenuAction_SelectOption:
		{
			if(!g_bEnabled)
				PrintToChat(client, "%s%t", PLUGIN_PREFIX, "Phrase_Inactive");
			else if(g_iClientAccess[client] == ACCESS_NO_ACCESS)
				PrintToChat(client, "%s%t", PLUGIN_PREFIX, "Phrase_Restricted");
			else if(client && IsClientInGame(client) && !g_bForced[g_iClientAccess[client]])
				Menu_Skins(client);
		}
	}
}

Menu_Skins(client)
{
	decl String:sBuffer[128];
	new Handle:_hMenu = CreateMenu(MenuHandler_MenuSkins);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title_Main", client);
	SetMenuTitle(_hMenu, sBuffer);
	SetMenuPagination(_hMenu, MENU_NO_PAGINATION);
	SetMenuExitButton(_hMenu, true);

	if(g_bAppear[client])
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Disable", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Option_Enable", client);
	AddMenuItem(_hMenu, "0", sBuffer);
	
	DisplayMenu(_hMenu, client, MENU_TIME_FOREVER);
}

public MenuHandler_MenuSkins(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Select:
		{
			decl String:_sTemp[8];
			GetMenuItem(menu, param2, _sTemp, sizeof(_sTemp));

			switch(StringToInt(_sTemp))
			{
				case 0:
				{
					if(!g_bAppear[param1])
					{
						g_bAppear[param1] = true;
						PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Enable");
						SetClientCookie(param1, g_hCookie, "1");

						if(g_bAlive[param1] && g_bChangable)
							CreateTimer(0.0, Timer_Apply, GetClientUserId(param1), TIMER_FLAG_NO_MAPCHANGE);
					}
					else
					{
						g_bAppear[param1] = false;
						PrintToChat(param1, "%s%t", PLUGIN_PREFIX, "Phrase_Disable");
						SetClientCookie(param1, g_hCookie, "0");

						if(g_bAlive[param1] && g_bChangable)
						{
							if(g_iFlag[ACCESS_TIER_NONE] && g_bForced[ACCESS_TIER_NONE])
							{
								switch(g_iTeam[param1])
								{
									case TEAM_RED:
									{
										if(g_iRedTotal[ACCESS_TIER_NONE])
										{
											new iTemp = GetRandomInt(0, (g_iRedTotal[ACCESS_TIER_NONE] - 1));
											if(g_bRedAvailable[ACCESS_TIER_NONE][iTemp])
											{
												SetEntityModel(param1, g_sRedPaths[ACCESS_TIER_NONE][iTemp]);
											
												Menu_Skins(param1);
												return;
											}
										}
										
										SetEntityModel(param1, g_sRedModels[GetRandomInt(0, 3)]);
									}
									case TEAM_BLUE:
									{
										if(g_iBlueTotal[ACCESS_TIER_NONE])
										{
											new iTemp = GetRandomInt(0, (g_iBlueTotal[ACCESS_TIER_NONE] - 1));
											if(g_bBlueAvailable[ACCESS_TIER_NONE][iTemp])
											{
												SetEntityModel(param1, g_sBluePaths[ACCESS_TIER_NONE][iTemp]);
										
												Menu_Skins(param1);
												return;
											}
										}
										
										SetEntityModel(param1, g_sBlueModels[GetRandomInt(0, 3)]);
									}
								}
							}
							else
							{
								switch(g_iTeam[param1])
								{
									case TEAM_RED:
										SetEntityModel(param1, g_sRedModels[GetRandomInt(0, 3)]);
									case TEAM_BLUE:
										SetEntityModel(param1, g_sBlueModels[GetRandomInt(0, 3)]);
								}
							}
						}
					}

					Menu_Skins(param1);
				}
			}
		}
	}
}

Define_Cookies(client)
{
	if(g_bForced[g_iClientAccess[client]])
		g_bAppear[client] = true;
	else
	{
		decl String:g_sCookie[3];
		GetClientCookie(client, g_hCookie, g_sCookie, sizeof(g_sCookie));

		if(StrEqual(g_sCookie, ""))
		{
			SetClientCookie(client, g_hCookie, g_bDefault ? "1" : "0");
			g_bAppear[client] = g_bDefault;
		}
		else
			g_bAppear[client] = StringToInt(g_sCookie) ? true : false;
	}
		
	g_bLoaded[client] = true;
}


Define_Skins()
{
	decl String:sBuffer[1024];
	for(new i = ACCESS_TIER_ONE; i <= ACCESS_TIER_NONE; i++)
	{
		if(i == ACCESS_TIER_NONE)
			g_iFlag[ACCESS_TIER_NONE] = GetConVarInt(g_hFlag[i]);
		else
		{
			GetConVarString(g_hFlag[i], sBuffer, sizeof(sBuffer));
			g_iFlag[i] = ReadFlagString(sBuffer);
			GetConVarString(g_hOverride[i], g_sOverride[i], sizeof(g_sOverride[]));
			
			g_bValidSkin[i] = !StrEqual(g_sOverride[i], "");
		}

		if((i == ACCESS_TIER_NONE && g_iFlag[ACCESS_TIER_NONE]) || g_bValidSkin[i])
		{
			GetConVarString(g_hPathT[i], sBuffer, sizeof(sBuffer));
			g_iRedTotal[i] = ExplodeString(sBuffer, ", ", g_sRedPaths[i], NUM_PATHS, PLATFORM_MAX_PATH);
			for(new j = 0; j < g_iRedTotal[i]; j++)
				g_bRedAvailable[i][j] = Bool_Check(g_sRedPaths[i][j]);
			
			GetConVarString(g_hPathCT[i], sBuffer, sizeof(sBuffer));
			g_iBlueTotal[i] = ExplodeString(sBuffer, ", ", g_sBluePaths[i], NUM_PATHS, PLATFORM_MAX_PATH);
			for(new j = 0; j < g_iRedTotal[i]; j++)
				g_bBlueAvailable[i][j] = Bool_Check(g_sBluePaths[i][j]);
		}
		else
		{
			g_iRedTotal[i] = 0;
			g_iBlueTotal[i] = 0;
		}
	}
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = bool:StringToInt(newvalue);
	else if(cvar == g_hBots)
		g_iBots = StringToInt(newvalue);
	else if(cvar == g_hDefault)
		g_bDefault = bool:StringToInt(newvalue);
	else if(cvar == g_hDelay)
		g_fDelay = StringToFloat(newvalue);
	else if(cvar == g_hAllowed)
		g_fAllowed = StringToFloat(newvalue);
	else if(cvar == g_hCommands)
	{
		ClearTrie(g_hTrie);

		new iCount = ExplodeString(newvalue, ", ", g_sCommands, sizeof(g_sCommands), sizeof(g_sCommands[]));
		for(new i = 0; i < iCount; i++)
			SetTrieValue(g_hTrie, g_sCommands[i], iCount);
	}
}

Define_Downloads()
{
	new String:sBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "configs/sm_autoskin.ini");

	new Handle:hTemp = OpenFile(sBuffer, "r");
	if(hTemp != INVALID_HANDLE) 
	{
		new iSize;
		while (ReadFileLine(hTemp, sBuffer, sizeof(sBuffer)))
		{	
			iSize = strlen(sBuffer);
			if(sBuffer[(iSize - 1)] == '\n')
				sBuffer[--iSize] = '\0';

			TrimString(sBuffer);
			if(!StrEqual(sBuffer, ""))
				ReadFileFolder(sBuffer);

			if(IsEndOfFile(hTemp))
				break;
		}

		CloseHandle(hTemp);
	}
}

ReadFileFolder(String:sPath[])
{
	new Handle:hTemp = INVALID_HANDLE;
	new iSize, FileType:iType = FileType_Unknown;
	decl String:sBuffer[256], String:sLine[256];
	
	iSize = strlen(sPath);
	if(sPath[iSize-1] == '\n')
		sPath[--iSize] = '\0';

	TrimString(sPath);
	if(DirExists(sPath))
	{
		hTemp = OpenDirectory(sPath);
		while(ReadDirEntry(hTemp, sBuffer, sizeof(sBuffer), iType))
		{
			iSize = strlen(sBuffer);
			if(sBuffer[iSize-1] == '\n')
				sBuffer[--iSize] = '\0';
			TrimString(sBuffer);

			if(!StrEqual(sBuffer, "") && !StrEqual(sBuffer, ".", false) && !StrEqual(sBuffer,"..",false))
			{
				strcopy(sLine, sizeof(sLine), sPath);
				StrCat(sLine, sizeof(sLine), "/");
				StrCat(sLine, sizeof(sLine), sBuffer);

				if(iType == FileType_File)
					ReadItem(sLine);
				else
					ReadFileFolder(sLine);
			}
		}
	}
	else
		ReadItem(sPath);

	if(hTemp != INVALID_HANDLE)
		CloseHandle(hTemp);
}

ReadItem(String:sBuffer[])
{
	decl String:sTemp[3];
	new iSize = strlen(sBuffer);
	if(sBuffer[iSize-1] == '\n')
		sBuffer[--iSize] = '\0';
	TrimString(sBuffer);

	strcopy(sTemp, sizeof(sTemp), sBuffer);
	if(!StrEqual(sBuffer, "") && StrContains(sBuffer, "//") == -1)
	{
		if(FileExists(sBuffer))
		{
			if((StrContains(sBuffer, ".wav") >= 0) || (StrContains(sBuffer, ".mp3") >= 0))
				PrecacheSound(sBuffer);
			else if(StrContains(sBuffer, ".mdl") >= 0 || StrContains(sBuffer, ".vtf") >= 0 || StrContains(sBuffer, ".vmt") >= 0)
				PrecacheModel(sBuffer);

			AddFileToDownloadsTable(sBuffer);
		}
	}
}