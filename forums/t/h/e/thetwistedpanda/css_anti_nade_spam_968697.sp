#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <colors>

#define PLUGIN_VERSION "2.3.6"

#define CS_HE_GRENADE 11
#define CS_FB_GRENADE 12
#define CS_SM_GRENADE 13

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bPlayerSmokes[MAXPLAYERS + 1];
new bool:g_bPlayerFlashes[MAXPLAYERS + 1];
new bool:g_bPlayerGrenades[MAXPLAYERS + 1];
new g_iReturnCash[MAXPLAYERS + 1];
new g_iPlayerSmokes[MAXPLAYERS + 1];
new g_iPlayerFlashes[MAXPLAYERS + 1];
new g_iPlayerGrenades[MAXPLAYERS + 1];
new Handle:g_hReturnTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hBuyzonesOnly = INVALID_HANDLE;
new Handle:g_hMessageMode = INVALID_HANDLE;
new Handle:g_hNumGrenades = INVALID_HANDLE;
new Handle:g_hNumSmokes = INVALID_HANDLE;
new Handle:g_hNumFlashes = INVALID_HANDLE;
new Handle:g_hAmmoGrenades = INVALID_HANDLE;
new Handle:g_hAmmoSmokes = INVALID_HANDLE;
new Handle:g_hAmmoFlashes = INVALID_HANDLE;
new Handle:g_hRestrictConvar = INVALID_HANDLE;
new Handle:g_hRestrictGrenades[2] = { INVALID_HANDLE, INVALID_HANDLE };
new Handle:g_hRestrictSmokes[2] = { INVALID_HANDLE, INVALID_HANDLE };
new Handle:g_hRestrictFlashes[2] = { INVALID_HANDLE, INVALID_HANDLE };

new bool:g_bLateLoad, bool:g_bEnabled, bool:g_bEnding, bool:g_bBuyzonesOnly, bool:g_bRestrictEnabled, bool:g_bRestrictLoaded, bool:g_bRestrictGrenades[2] = { false, ... }, bool:g_bRestrictSmokes[2] = { false, ... }, bool:g_bRestrictFlashes[2] = { false, ... };
new g_iMessageMode, g_iNumGrenades, g_iNumSmokes, g_iNumFlashes, g_iAmmoGrenades, g_iAmmoSmokes, g_iAmmoFlashes;

public Plugin:myinfo = 
{
	name = "CSS Anti Nade Spam",
	author = "Twisted|Panda",
	description = "Another plugin designed to prevent players from spamming grenades.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("css_anti_nade_spam.phrases");

	CreateConVar("sm_anti_nade_spam_version", PLUGIN_VERSION, "CSS Anti Nade Spam: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_anti_nade_spam_enable", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hMessageMode = CreateConVar("css_anti_nade_spam_messages", "0", "Determines printing functionality (-1 = Disabled, 0 = Chat, 1 = Hint, 2 = Center, 3 = Key Hint)", FCVAR_NONE, true, -1.0, true, 3.0);
	HookConVarChange(g_hMessageMode, OnSettingsChange);
	g_hBuyzonesOnly = CreateConVar("css_anti_nade_spam_buyzones", "1", "Determines incremental functionality. (0 = Count all grenades, 1 = Count only grenades inside of buyzone)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hBuyzonesOnly, OnSettingsChange);
	g_hNumGrenades = CreateConVar("css_anti_nade_spam_hegrenade", "-1", "The number of HE Grenades players are allowed to use. (-2 = Ignore Grenades, -1 = ammo_hegrenade_max, 0 = Disable Grenades)", FCVAR_NONE, true, -2.0);
	HookConVarChange(g_hNumGrenades, OnSettingsChange);
	g_hNumSmokes = CreateConVar("css_anti_nade_spam_smokegrenade", "-1", "The number of Smoke Grenades players are allowed to use. (-2 = Ignore Smokes, -1 = ammo_smokegrenade_max, 0 = Disable Smokes)", FCVAR_NONE, true, -2.0);
	HookConVarChange(g_hNumSmokes, OnSettingsChange);
	g_hNumFlashes = CreateConVar("css_anti_nade_spam_flashbang", "-1", "The number of Flash Bangs players are allowed to use. (-2 = Ignore Flashes, -1 = ammo_flashbang_max, 0 = Disable Flashes)", FCVAR_NONE, true, -2.0);
	HookConVarChange(g_hNumFlashes, OnSettingsChange);
	AutoExecConfig(true, "css_anti_nade_spam");

	g_hAmmoGrenades = FindConVar("ammo_hegrenade_max");
	HookConVarChange(g_hAmmoGrenades, OnSettingsChange);
	g_hAmmoSmokes = FindConVar("ammo_smokegrenade_max");
	HookConVarChange(g_hAmmoSmokes, OnSettingsChange);
	g_hAmmoFlashes = FindConVar("ammo_flashbang_max");
	HookConVarChange(g_hAmmoFlashes, OnSettingsChange);
	
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("item_pickup", Event_OnItemPickup);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);

	Define_Defaults();
}

public OnAllPluginsLoaded()
{
	g_hRestrictConvar = FindConVar("sm_weaponrestrict_version");
	g_bRestrictEnabled = (g_hRestrictConvar != INVALID_HANDLE) ? true : false;
	if(g_bRestrictEnabled && !g_bRestrictLoaded)
	{
		g_bRestrictLoaded = true;
		g_hRestrictGrenades[0] = FindConVar("sm_restrict_hegrenade_t");
		if(g_hRestrictGrenades[0] != INVALID_HANDLE)
		{
			HookConVarChange(g_hRestrictGrenades[0], OnRestrictChange);
			g_bRestrictGrenades[0] = GetConVarInt(g_hRestrictGrenades[0]) == -1 ? false : true;
		}

		g_hRestrictGrenades[1] = FindConVar("sm_restrict_hegrenade_ct");
		if(g_hRestrictGrenades[1] != INVALID_HANDLE)
		{
			HookConVarChange(g_hRestrictGrenades[1], OnRestrictChange);
			g_bRestrictGrenades[1] = GetConVarInt(g_hRestrictGrenades[1]) == -1 ? false : true;
		}

		g_hRestrictSmokes[0] = FindConVar("sm_restrict_smokegrenade_t");
		if(g_hRestrictSmokes[0] != INVALID_HANDLE)
		{
			HookConVarChange(g_hRestrictSmokes[0], OnRestrictChange);
			g_bRestrictSmokes[0] = GetConVarInt(g_hRestrictSmokes[0]) == -1 ? false : true;
		}
		
		g_hRestrictSmokes[1] = FindConVar("sm_restrict_smokegrenade_ct");
		if(g_hRestrictSmokes[1] != INVALID_HANDLE)
		{
			HookConVarChange(g_hRestrictSmokes[1], OnRestrictChange);
			g_bRestrictSmokes[1] = GetConVarInt(g_hRestrictSmokes[1]) == -1 ? false : true;
		}

		g_hRestrictFlashes[0] = FindConVar("sm_restrict_flashbang_t");
		if(g_hRestrictFlashes[0] != INVALID_HANDLE)
		{
			HookConVarChange(g_hRestrictFlashes[0], OnRestrictChange);
			g_bRestrictFlashes[0] = GetConVarInt(g_hRestrictFlashes[0]) == -1 ? false : true;
		}

		g_hRestrictFlashes[1] = FindConVar("sm_restrict_flashbang_ct");
		if(g_hRestrictFlashes[1] != INVALID_HANDLE)
		{
			HookConVarChange(g_hRestrictFlashes[1], OnRestrictChange);	
			g_bRestrictFlashes[1] = GetConVarInt(g_hRestrictFlashes[1]) == -1 ? false : true;
		}
	}
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i) ? true : false;
					
					SDKHook(i, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
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
		if(IsClientInGame(client))
		{
			SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
		}
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		if(IsClientInGame(client))
		{
			g_iTeam[client] = 0;
			g_bAlive[client] = false;

			g_iPlayerGrenades[client] = g_iPlayerSmokes[client] = g_iPlayerFlashes[client] = 0;
			if(g_hReturnTimer[client] != INVALID_HANDLE && CloseHandle(g_hReturnTimer[client]))
				g_hReturnTimer[client] = INVALID_HANDLE;
		}
	}
}

public Action:Hook_WeaponCanUse(client, weapon)
{
	if(g_bEnabled)
	{
		if(!g_bEnding)
		{
			decl String:_sBuffer[32];
			GetEdictClassname(weapon, _sBuffer, 32);
			if(StrEqual(_sBuffer, "weapon_hegrenade"))
			{
				if(g_bRestrictGrenades[GetTeamIndex(g_iTeam[client])] || !g_iNumGrenades)
					return Plugin_Handled;
				else if(g_iNumGrenades == -2)
					return Plugin_Continue;
				else if(!g_bBuyzonesOnly || g_bPlayerGrenades[client])
				{
					new _iMax = g_iNumGrenades == -1 ? g_iAmmoGrenades : g_iNumGrenades;
					if(g_iPlayerGrenades[client] >= _iMax)
						return Plugin_Handled;
				}
			}
			else if(StrEqual(_sBuffer, "weapon_smokegrenade"))
			{
				if(g_bRestrictSmokes[GetTeamIndex(g_iTeam[client])] || !g_iNumSmokes)
					return Plugin_Handled;
				else if(g_iNumSmokes == -2)
					return Plugin_Continue;
				else if(!g_bBuyzonesOnly || g_bPlayerSmokes[client])
				{
					new _iMax = g_iNumSmokes == -1 ? g_iAmmoSmokes : g_iNumSmokes;
					if(g_iPlayerSmokes[client] >= _iMax)
						return Plugin_Handled;
				}
			}
			else if(StrEqual(_sBuffer, "weapon_flashbang"))
			{
				if(g_bRestrictFlashes[GetTeamIndex(g_iTeam[client])] || !g_iNumFlashes)
					return Plugin_Handled;
				else if(g_iNumFlashes == -2)
					return Plugin_Continue;
				else if(!g_bBuyzonesOnly || g_bPlayerFlashes[client])
				{
					new _iMax = g_iNumFlashes == -1 ? g_iAmmoFlashes : g_iNumFlashes;
					if(g_iPlayerFlashes[client] >= _iMax)
						return Plugin_Handled;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if(g_bEnabled)
	{
		if(client > 0 && IsClientInGame(client) && !g_bEnding)
		{
			decl String:_sWeapon[24];
			strcopy(_sWeapon, sizeof(_sWeapon), weapon);
			ReplaceString(_sWeapon, sizeof(_sWeapon), "weapon_", "", false);
			if(StrEqual(_sWeapon, "hegrenade", false))
			{
				if(g_iNumGrenades == -2)
					return Plugin_Continue;
				else if(g_bRestrictGrenades[GetTeamIndex(g_iTeam[client])])
					PrintToClient(client, "%T", "Buy_Grenade_Restricted", client);
				else if(!g_iNumGrenades)
					PrintToClient(client, "%T", "Buy_Grenade_Disabled", client);
				else
				{
					new _iMax = g_iNumGrenades == -1 ? g_iAmmoGrenades : g_iNumGrenades;
					if(g_iPlayerGrenades[client] >= _iMax)
					{
						if(!GetGrenadeCount(client, CS_HE_GRENADE))
							PrintToClient(client, "%T", "Buy_Grenade_Maximum", client, _iMax);
					}
					else
					{
						g_bPlayerGrenades[client] = true;
						CreateTimer(0.1, Timer_ResetGrenades, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						return Plugin_Continue;
					}
				}

				return Plugin_Handled;
			}
			else if(StrEqual(_sWeapon, "smokegrenade", false))
			{
				if(g_iNumSmokes == -2)
					return Plugin_Continue;
				else if(g_bRestrictSmokes[GetTeamIndex(g_iTeam[client])])
					PrintToClient(client, "%T", "Buy_Smoke_Restricted", client);
				else if(!g_iNumSmokes)
					PrintToClient(client, "%T", "Buy_Smoke_Disabled", client);
				else
				{
					new _iMax = g_iNumSmokes == -1 ? g_iAmmoSmokes : g_iNumSmokes;
					if(g_iPlayerSmokes[client] >= _iMax)
					{
						if(!GetGrenadeCount(client, CS_SM_GRENADE))
							PrintToClient(client, "%T", "Buy_Smoke_Maximum", client, _iMax);
					}
					else
					{
						g_bPlayerSmokes[client] = true;
						CreateTimer(0.1, Timer_ResetSmokes, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						return Plugin_Continue;
					}
				}
					
				return Plugin_Handled;
			}
			else if(StrEqual(_sWeapon, "flashbang", false))
			{
				if(g_iNumFlashes == -2)
					return Plugin_Continue;
				else if(g_bRestrictFlashes[GetTeamIndex(g_iTeam[client])])
					PrintToClient(client, "%T", "Buy_Flash_Restricted", client);
				else if(!g_iNumFlashes)
					PrintToClient(client, "%T", "Buy_Flash_Disabled", client);
				else
				{
					new _iMax = g_iNumFlashes == -1 ? g_iAmmoFlashes : g_iNumFlashes;
					if(g_iPlayerFlashes[client] >= _iMax)
					{
						if(!GetGrenadeCount(client, CS_FB_GRENADE))
							PrintToClient(client, "%T", "Buy_Flash_Maximum", client, _iMax);
					}
					else
					{
						g_bPlayerFlashes[client] = true;
						CreateTimer(0.1, Timer_ResetFlashes, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
						return Plugin_Continue;
					}
				}
					
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_ResetGrenades(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0)
		g_bPlayerGrenades[client] = false;

	return Plugin_Continue;
}

public Action:Timer_ResetSmokes(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0)
		g_bPlayerSmokes[client] = false;

	return Plugin_Continue;
}

public Action:Timer_ResetFlashes(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client > 0)
		g_bPlayerFlashes[client] = false;

	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = false;
	}
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = true;

		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_iPlayerGrenades[i] = g_iPlayerSmokes[i] = g_iPlayerFlashes[i] = 0;
				if(g_hReturnTimer[i] != INVALID_HANDLE && CloseHandle(g_hReturnTimer[i]))
					g_hReturnTimer[i] = INVALID_HANDLE;
			}
		 }
	 }
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
			
		g_iTeam[client] = GetEventInt(event, "team");
		if(g_iTeam[client] <= CS_TEAM_SPECTATOR)
			g_bAlive[client] = false;
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client) || g_iTeam[client] <= CS_TEAM_SPECTATOR)
			return Plugin_Continue;
			
		g_bAlive[client] = true;
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

public Action:Event_OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		decl String:_sBuffer[24];
		GetEventString(event, "item", _sBuffer, sizeof(_sBuffer));
		if(StrEqual(_sBuffer, "hegrenade"))
		{
			if(!g_bBuyzonesOnly || g_bPlayerGrenades[client])
				g_iPlayerGrenades[client]++;
		}
		else if(StrEqual(_sBuffer, "smokegrenade"))
		{
			if(!g_bBuyzonesOnly || g_bPlayerSmokes[client])
				g_iPlayerSmokes[client]++;
		}
		else if(StrEqual(_sBuffer, "flashbang"))
		{
			if(!g_bBuyzonesOnly || g_bPlayerFlashes[client])
				g_iPlayerFlashes[client]++;
		}
	}

	return Plugin_Continue;
}

public Action:Timer_ReturnCash(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new _iReturn = GetEntProp(client, Prop_Send, "m_iAccount");
		_iReturn += g_iReturnCash[client];
		
		if(_iReturn > 16000)
			SetEntProp(client, Prop_Send, "m_iAccount", 16000);
		else
			SetEntProp(client, Prop_Send, "m_iAccount", _iReturn);
	}

	g_iReturnCash[client] = 0;
	g_hReturnTimer[client] = INVALID_HANDLE;
}

PrintToClient(client, const String:_sMessage[], any:...)
{
	if(g_iMessageMode != -1)
	{
		decl String:_sBuffer[192];
		VFormat(_sBuffer, sizeof(_sBuffer), _sMessage, 3);

		switch(g_iMessageMode)
		{
			case 0:
				CPrintToChat(client, "%t%s", "Prefix_Chat", _sBuffer);
			case 1:
				PrintHintText(client, "%t%s", "Prefix_Hint", _sBuffer);
			case 2:
				PrintCenterText(client, "%t%s", "Prefix_Center", _sBuffer);
			case 3:
			{
				Format(_sBuffer, sizeof(_sBuffer), "%t%s", "Prefix_Key", _sBuffer);
				new Handle:_hMessage = StartMessageOne("KeyHintText", client);
				BfWriteByte(_hMessage, 1);
				BfWriteString(_hMessage, _sBuffer); 
				EndMessage();
			}
		}
	}
}

GetTeamIndex(team)
{
	return (team == CS_TEAM_T) ? 0 : 1;
}

GetGrenadeCount(client, type)
{
	new offsAmmo = FindDataMapOffs(client, "m_iAmmo") + (type * 4);
	return GetEntData(client, offsAmmo);
}

Define_Defaults()
{
	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_iMessageMode = GetConVarInt(g_hMessageMode);
	g_bBuyzonesOnly = GetConVarInt(g_hBuyzonesOnly) ? true : false;
	g_iNumGrenades = GetConVarInt(g_hNumGrenades);
	g_iNumSmokes = GetConVarInt(g_hNumSmokes);
	g_iNumFlashes = GetConVarInt(g_hNumFlashes);
	g_iAmmoGrenades = GetConVarInt(g_hAmmoGrenades);
	g_iAmmoSmokes = GetConVarInt(g_hAmmoSmokes);
	g_iAmmoFlashes = GetConVarInt(g_hAmmoFlashes);
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hMessageMode)
		g_iMessageMode = StringToInt(newvalue);
	else if(cvar == g_hBuyzonesOnly)
		g_bBuyzonesOnly = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hNumGrenades)
		g_iNumGrenades = StringToInt(newvalue);
	else if(cvar == g_hNumSmokes)
		g_iNumSmokes = StringToInt(newvalue);
	else if(cvar == g_hNumFlashes)
		g_iNumFlashes = StringToInt(newvalue);
	else if(cvar == g_hAmmoGrenades)
		g_iAmmoGrenades = StringToInt(newvalue);
	else if(cvar == g_hAmmoSmokes)
		g_iAmmoSmokes = StringToInt(newvalue);
	else if(cvar == g_hAmmoFlashes)
		g_iAmmoFlashes = StringToInt(newvalue);
}

public OnRestrictChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hRestrictGrenades[0])
		g_bRestrictGrenades[0] = StringToInt(newvalue) == -1 ? false : true;
	else if(cvar == g_hRestrictSmokes[0])
		g_bRestrictSmokes[0] = StringToInt(newvalue) == -1 ? false : true;
	else if(cvar == g_hRestrictFlashes[0])
		g_bRestrictFlashes[0] = StringToInt(newvalue) == -1 ? false : true;
	else if(cvar == g_hRestrictGrenades[1])
		g_bRestrictGrenades[1] = StringToInt(newvalue) == -1 ? false : true;
	else if(cvar == g_hRestrictSmokes[1])
		g_bRestrictSmokes[1] = StringToInt(newvalue) == -1 ? false : true;
	else if(cvar == g_hRestrictFlashes[1])
		g_bRestrictFlashes[1] = StringToInt(newvalue) == -1 ? false : true;
}