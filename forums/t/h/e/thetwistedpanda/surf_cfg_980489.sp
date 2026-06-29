/*
	Credits:
	- sumguy14: For his BunnyHop script, most of the code regarding it is his, I've only rewritten it to match my own coding style.
	- Fredd: For the general idea;this plugin stems from being unsatisfied with his creation.
	- psychonic: For the 64 array issue.
*/

/*
	v1.0 <--> v1.4
	Removed respawn mode 2 from sm_surfcfg_respawn_mode
	Added new variable sm_surfcfg_respawn_new_players to respawn new players
	Fixed an issue where the global counter was not reset on new rounds
	
	v1.5
	Fixed an issue that would cause 64 slot servers to error out.
	
	v1.6
	Added sm_surfcfg_display to allow the prefix of all chat messages to be modified.
	Added sm_surfcfg_teleport_cancel and sm_surfcfg_teleport_distance to allow teleportion requests to be cancelled upon movement.
	Added detection of "slide" maps to the dynamic detection of sm_surfcfg_enabled.
	Organized and re-defined the variables relating to Surf Config
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.6"

#define SPECTATOR_TEAM 0
#define UNASSIGNED_TEAM 1
#define TERRORIST_TEAM 2
#define COUNTER_TERRORIST_TEAM 3

#define PLAYER_SPAWNS 0
#define PLAYER_DIED 1
#define PLAYER_TELEPORT 2
#define PLAYER_DATA 3

#define LOCATION_X 0
#define LOCATION_Y 1
#define LOCATION_Z 2
#define LOCATION_DATA 3

new p_Player[MAXPLAYERS+1][PLAYER_DATA];
new Float:p_Spawns[MAXPLAYERS+1][LOCATION_DATA];  
new Float:p_Locations[MAXPLAYERS+1][LOCATION_DATA]; 
new p_vecVelocity_0;
new p_vecVelocity_1;
new p_vecBaseVelocity;
new p_CollisionGroup;
new bool:p_isEnabled = true;
new bool:canRespawn = true;
new Float:p_currentTime;
new Handle:airAccel = INVALID_HANDLE;
new Handle:globalTimer = INVALID_HANDLE;
new Handle:cfgTimer = INVALID_HANDLE;
new Handle:deleteTimer = INVALID_HANDLE;

new Handle:p_Display = INVALID_HANDLE;
new Handle:p_Enabled = INVALID_HANDLE;
new Handle:p_NoBlock = INVALID_HANDLE;
new Handle:p_Colors = INVALID_HANDLE;
new Handle:p_Protection = INVALID_HANDLE;
new Handle:p_Bunny = INVALID_HANDLE;
new Handle:p_Strip = INVALID_HANDLE;
new Handle:p_Teleport = INVALID_HANDLE;
new Handle:p_Respawn = INVALID_HANDLE;
new Handle:p_BuyZones = INVALID_HANDLE;
new Handle:p_MapConfigs = INVALID_HANDLE;
new Handle:p_AirAccel = INVALID_HANDLE;
new Handle:p_Notify = INVALID_HANDLE;
new Handle:p_ColorT = INVALID_HANDLE;
new Handle:p_ColorCT = INVALID_HANDLE;
new Handle:p_ProtectionTime = INVALID_HANDLE;
new Handle:p_BunnyHeight = INVALID_HANDLE;
new Handle:p_BunnyPush = INVALID_HANDLE;
new Handle:p_StripKnife = INVALID_HANDLE;
new Handle:p_StripWeapon = INVALID_HANDLE;
new Handle:p_TeleportDelay = INVALID_HANDLE;
new Handle:p_TeleportRefresh = INVALID_HANDLE;
new Handle:p_TeleportCancel = INVALID_HANDLE;
new Handle:p_TeleportCancelDistance = INVALID_HANDLE;
new Handle:p_RespawnTimer = INVALID_HANDLE;
new Handle:p_RespawnDelay = INVALID_HANDLE;
new Handle:p_RespawnAmount = INVALID_HANDLE;
new Handle:p_RespawnNew = INVALID_HANDLE;
new Handle:p_Configuration = INVALID_HANDLE;
new Handle:p_StripPlayer = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Surf Config", 
	author = "Twisted|Panda", 
	description = "Provides various settings for surf and slide maps.", 
	version = PLUGIN_VERSION, 
	url = "http://forums.alliedmods.com"
}

public OnPluginStart ()
{
	CreateConVar("sm_surfcfg_version", PLUGIN_VERSION, "Surf Config", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	p_Enabled  = CreateConVar("sm_surfcfg_enabled", "1", "Determines whether Surf Config is enabled, disabled, or dynamically enabled and disabled based on the map. (-1 = Dynamic, 0 = Disabled, 1 = Enabled)");
	
	p_Colors  = CreateConVar("sm_surfcfg_colors_mode", "1", "Enables or disables the color module, which allows teams to be color coded. (0 = Disabled, 1 = Enabled)");
	p_ColorT = CreateConVar("sm_surfcfg_color_t", "230 20 40 255", "The color combination to apply to the Terrorist team if sm_surfcfg_colors_mode is enabled. (Red Green Blue Alpha)");
	p_ColorCT = CreateConVar("sm_surfcfg_color_ct", "0 255 255 255", "The color combination to apply to the Counter-Terrorist team if sm_surfcfg_colors_mode is enabled. (Red Green Blue Alpha)");
	
	p_Protection  = CreateConVar("sm_surfcfg_protection_mode", "1", "Enables or disables the spawn protection module. (0 = Disabled, 1 = Enabled)");
	p_ProtectionTime = CreateConVar("sm_surfcfg_protection_time", "5.0", "The number of seconds players will spawn with protection. (0 = No Protection, # = Number of Seconds)");
	
	p_Bunny  = CreateConVar("sm_surfcfg_bhop_mode", "0", "Enables or disables the bunny hopping module. (0 = Disabled, 1 = Enabled)");
	p_BunnyHeight  = CreateConVar("sm_surfcfg_bhop_height", "1.0", "The amount of forward push applied when a player jumps if sm_surfcfg_bhop_mode is enabled. (1.0 = Normal)");
	p_BunnyPush = CreateConVar("sm_surfcfg_bhop_push", "1.0", "The amount of upward push applied when a player jumps if sm_surfcfg_bhop_mode is enabled. (1.0 = Normal)");
	
	p_Strip = CreateConVar("sm_surfcfg_strip_mode", "1", "Enables or disables the weapon stripping / spawning module. (0 = Disabled, 1 = Enabled)");
	p_StripKnife = CreateConVar("sm_surfcfg_strip_knife", "1", "Enables or disables the player's ability to spawn with a knife. (0 = No Knife, 1 = Has Knife)");
	p_StripWeapon = CreateConVar("sm_surfcfg_strip_weapon", "weapon_scout", "The weapon players will spawn with if specified. (weapon_scout)");

	p_Teleport = CreateConVar("sm_surfcfg_teleport_mode", "1", "Enables or disables the player teleport module. (0 = Disabled, 1 = Enabled)");
	p_TeleportDelay = CreateConVar("sm_surfcfg_teleport_delay", "5.0", "The number of seconds before a player's teleport request is processed (0 = Instantly, # = Number Of Seconds)");
	p_TeleportRefresh = CreateConVar("sm_surfcfg_teleport_refresh", "30.0", "The number of seconds players must wait before they may use the teleport command again. (0 = Instantly, # = Number Of Seconds)");
	p_TeleportCancel = CreateConVar("sm_surfcfg_teleport_cancel", "1.0", "If enabled, a teleportion attempt will fail if the player exceeds sm_surfcfg_teleport_distance (0 = Disabled, 1 = Enabled)");
	p_TeleportCancelDistance = CreateConVar("sm_surfcfg_teleport_distance", "320.0", "The distance a player is allowed to travel after typing starting a teleport (0 = No Movement Allowed, # = Distance Allowed)");
	
	p_Respawn = CreateConVar("sm_surfcfg_respawn_mode", "0", "Determines how Surf Config handles the respawn module. (-1 = Infinite Respawns, 0 = Disabled, 1 = Limited Respawns)");
	p_RespawnTimer = CreateConVar("sm_surfcfg_respawn_disable", "0.0", "The number of seconds after a match begins before players are no longer able to respawn. (0 = Always, # = Number of Seconds)");
	p_RespawnDelay = CreateConVar("sm_surfcfg_respawn_delay", "1.0", "The delay in seconds seconds required before players are respawned. (0 = No Delay, # = Delay in Seconds)");
	p_RespawnAmount = CreateConVar("sm_surfcfg_respawn_count", "0", "The number of respawns players will receive if sm_surfcfg_respawn_mode is equal to 1. (0 = No Respawns, # = Number of Respawns)");
	p_RespawnNew = CreateConVar("sm_surfcfg_respawn_new_players", "0", "If enabled, new players to the server will be allowed to spawn regardless of when they join.");

	p_Display  = CreateConVar("sm_surfcfg_display", "|oG| Surf", "The text that is prefixed to any message controlled by Surf Config.");    
	p_NoBlock  = CreateConVar("sm_surfcfg_noblock_mode", "1", "Enables or disables player collisions on spawn. (0 = Disabled, 1 = Enabled)");
	p_BuyZones = CreateConVar("sm_surfcfg_buyzone_mode", "0", "Enables or disables the buyzone removal module. (0 = Disabled, 1 = Enabled)");
	p_MapConfigs = CreateConVar("sm_surfcfg_config_mode", "1", "Enables or disables support for map configuration files located in /cfg/surf_cfg/ (0 = Disabled, 1 = Enabled)");
	p_AirAccel = CreateConVar("sm_surfcfg_airaccel_mode", "0", "Determines whether Surf Config will maintain a specific sv_airaccelerate value. (0 = Disabled, # = Specific Value)");
	p_Notify = CreateConVar("sm_surfcfg_notify_mode", "1", "Determines how Surf Config will display messages to clients. (0 = Disabled, 1 = Enabled, 2 = Respawn Only, 3 = Teleport Only)");

	AutoExecConfig(true);

	//The offset/signature file needed to make SDK calls, collisions, and bhop help to function
	p_Configuration = LoadGameConfigFile("surf_cfg.gamedata");
	if(p_Configuration == INVALID_HANDLE)
		SetFailState("gamedata/surf_cfg.gamedata.txt could not be located!");
	p_vecVelocity_0 = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	if(p_vecVelocity_0 == -1)
		SetFailState("m_vecVelocity[0] could not be located (CS:S Only!)");
	p_vecVelocity_1 = FindSendPropOffs("CBasePlayer", "m_vecVelocity[1]");
	if(p_vecVelocity_1 == -1)
		SetFailState("m_vecVelocity[1] could not be located (CS:S Only!)");
	p_vecBaseVelocity = FindSendPropOffs("CBasePlayer", "m_vecBaseVelocity");
	if(p_vecBaseVelocity == -1)
		SetFailState("m_vecBaseVelocity could not be located (CS:S Only!)");
	p_CollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if(p_CollisionGroup == -1)
		SetFailState("m_CollisionGroup could not be located (CS:S Only!)");
	airAccel = FindConVar("sv_airaccelerate");

	//Needed SDK call to strip player weapons
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(p_Configuration, SDKConf_Virtual, "RemoveAllItems");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	p_StripPlayer = EndPrepSDKCall();

	RegConsoleCmd("sm_tele", Command_Teleport);
	RegConsoleCmd("sm_recall", Command_Teleport);
	RegConsoleCmd("jointeam", Command_Join);

	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_jump", OnPlayerJump);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
}

public OnMapStart()
{
	//Strip buyzones from the map if we're supposed to.
	if(GetConVarInt(p_Enabled))
	{
		if(GetConVarInt(p_Enabled) == -1)
		{
			new String:currentMap[96];
			GetCurrentMap(currentMap, sizeof(currentMap));
			if(StrContains(currentMap, "surf") != -1 || StrContains(currentMap, "slide") != -1)
				p_isEnabled = true;
			else
				p_isEnabled = false;
		}
		
		if(p_isEnabled)
		{
			p_currentTime = 0.0;
			canRespawn = true;
			
			if(!GetConVarInt(p_BuyZones))
				cfgTimer = CreateTimer(0.0, deleteBuyZones);
		}
	}
}

public OnMapEnd()
{
	if(globalTimer != INVALID_HANDLE)
	{
		CloseHandle(globalTimer);
		globalTimer = INVALID_HANDLE;
	}
}

public OnAutoConfigsBuffered()
{
	//Load map configuration settings if we're supposed to.
	if(isScriptEnabled() && GetConVarInt(p_MapConfigs))
		cfgTimer = CreateTimer(0.0, loadMapConfigs);
}

public OnClientPostAdminCheck(client)
{
	//Set a player's data when they're connected to the server.
	if(isScriptEnabled())
		if(IsClientInGame(client))
			for(new i;i < PLAYER_DATA;i++)
				p_Player[client][i] = 0;
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(isScriptEnabled())
	{
		new clientTeam = GetClientTeam(client);
		
		decl String:p_tempString[255];
		GetConVarString(p_Display, p_tempString, sizeof(p_tempString));
		
		//Do color changing if we're supposed to.
		if(GetConVarInt(p_Colors))
		{
			decl String:strColors[4][4], String:varColors[32];
			if(clientTeam == TERRORIST_TEAM)
				GetConVarString(p_ColorT, varColors, sizeof(varColors));
			else
				GetConVarString(p_ColorCT, varColors, sizeof(varColors));
			
			ExplodeString(varColors, " ", strColors, 4, 4);
			SetEntityRenderColor(client, StringToInt(strColors[0]), StringToInt(strColors[1]), StringToInt(strColors[2]), StringToInt(strColors[3]));
		}      
		
		//Strip player's equipment if we're supposed to.
		if(GetConVarInt(p_Strip) && (clientTeam == TERRORIST_TEAM || clientTeam == COUNTER_TERRORIST_TEAM))
		{
			new String:userWeapon[32];
			SDKCall(p_StripPlayer, client, false);
			
			//Do they get a knife?
			if(GetConVarInt(p_StripKnife))
				GivePlayerItem(client, "weapon_knife");
			
			//Do they get a weapon?
			GetConVarString(p_StripWeapon, userWeapon, sizeof(userWeapon));
			if(StrContains(userWeapon, "weapon_") != -1)
			{
				GivePlayerItem(client, userWeapon);
				FakeClientCommand(client, "use %s", userWeapon);
			}
		}
		
		//Disable the player's collisions if we're supposed to.
		if(GetConVarInt(p_NoBlock))
			CreateTimer(0.0, DisableCollisions, client);
		
		//Give the player spawn protection if we're supposed to.
		if(GetConVarInt(p_Protection))
		{
			CreateTimer(0.0, EnableProtection, client);
			if(GetConVarFloat(p_ProtectionTime) > 0.0)
				CreateTimer(GetConVarFloat(p_ProtectionTime), DisableProtection, client);
		}
		
		//Update the player's respawn variables if we're supposed to.
		if(GetConVarInt(p_Respawn) > 0 && p_Player[client][PLAYER_DIED] == 1)
		{
			if(GetConVarInt(p_Respawn) == 1)
			{
				new numSpawns = p_Player[client][PLAYER_SPAWNS];
				if(numSpawns == -1)
					p_Player[client][PLAYER_SPAWNS] = GetConVarInt(p_RespawnAmount);
				
				if(numSpawns > 0)
					p_Player[client][PLAYER_SPAWNS]--;

				if(!p_Player[client][PLAYER_SPAWNS] && canNotifyUser(2))
					PrintToChat(client, "\x04%s: \x01You have run out of respawns this round!", p_tempString);
				else if(p_Player[client][PLAYER_SPAWNS] && canNotifyUser(2))
					PrintToChat(client, "\x04%s: \x01You have %d respawns remaining this round!", p_tempString, (GetConVarInt(p_RespawnAmount) - p_Player[client][PLAYER_SPAWNS]));

				p_Player[client][PLAYER_DIED] = 0;
			}
		}
		
		//Save the player's spawn location if we're supposed to.
		if(GetConVarInt(p_Teleport) && (clientTeam == TERRORIST_TEAM || clientTeam == COUNTER_TERRORIST_TEAM))
		{
			new Float:origin[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);

			p_Spawns[client][LOCATION_X] = origin[0];
			p_Spawns[client][LOCATION_Y] = origin[1];
			p_Spawns[client][LOCATION_Z] = origin[2];
		}        
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isScriptEnabled())
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetConVarInt(p_Respawn) == -1 || GetConVarInt(p_Respawn) == 1)
		{
			decl String:p_tempString[255];
			GetConVarString(p_Display, p_tempString, sizeof(p_tempString));
		
			if(canRespawn)
			{			
				if(GetConVarInt(p_Respawn) < 0)
				{
					p_Player[client][PLAYER_DIED] = true;
					
					if(GetConVarFloat(p_RespawnDelay) > 1.0 && canNotifyUser(2))
						PrintToChat(client, "\x04%s: \x01You will be respawned in \x04%.1f\x01 seconds!", p_tempString, GetConVarFloat(p_RespawnDelay));
					
					CreateTimer(GetConVarFloat(p_RespawnDelay), SpawnPlayer, any:client);
				}
				else
				{
					if(p_Player[client][PLAYER_SPAWNS] > 0)
					{
						p_Player[client][PLAYER_DIED] = true;
						
						if(GetConVarFloat(p_RespawnDelay) > 1.0 && canNotifyUser(2))
							PrintToChat(client, "\x04%s: \x01You will be respawned in \x04%.1f\x01 seconds!", p_tempString, GetConVarFloat(p_RespawnDelay));
						
						CreateTimer(GetConVarFloat(p_RespawnDelay), SpawnPlayer, any:client);
					}
				}
			}
			else
				if(canNotifyUser(2))
					PrintToChat(client, "\x04%s}: \x01You may no longer respawn this round!", p_tempString);
		}
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isScriptEnabled())
	{
		globalTimer = CreateTimer(1.0, globalCfgTime, _, TIMER_REPEAT);
	}
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isScriptEnabled())
	{
		if(globalTimer != INVALID_HANDLE)
			globalTimer = INVALID_HANDLE;
		p_currentTime = 0.0;
	}
}

public OnPlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isScriptEnabled() && GetConVarInt(p_Bunny))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new Float:velocity[3];

		velocity[0] =    GetEntDataFloat(client, p_vecVelocity_0) * GetConVarFloat(p_BunnyPush) / 2.0;
		velocity[1] =    GetEntDataFloat(client, p_vecVelocity_1) * GetConVarFloat(p_BunnyPush) / 2.0;
		velocity[2] =    GetConVarFloat(p_BunnyHeight) * 50.0;

		SetEntDataVector(client, p_vecBaseVelocity, velocity, true);
	}
}

public OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isScriptEnabled())
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new newTeam = GetEventInt(event, "team");
		new oldTeam = GetEventInt(event, "oldteam");
		
		if (GetConVarInt(p_RespawnNew))
			if(newTeam == SPECTATOR_TEAM && (oldTeam == TERRORIST_TEAM || oldTeam == COUNTER_TERRORIST_TEAM ))
				p_Player[client][PLAYER_DIED] = 1;
	}
}

public Action:Command_Join(client, args)
{
	if (isScriptEnabled())
	{
		decl String:iHasAString[3];
		GetCmdArg(1, iHasAString, sizeof(iHasAString));

		StripQuotes(iHasAString);
		TrimString(iHasAString);
		if(strlen(iHasAString) == 0)
			return Plugin_Handled;

		new bool:isAuto = StrEqual(iHasAString, "0");
		new team = StringToInt(iHasAString);
		new curTeam = GetClientTeam(client);

		if (team != TERRORIST_TEAM && team != COUNTER_TERRORIST_TEAM && !isAuto)
			return Plugin_Continue;
		else
		{
			if(canRespawn && GetConVarInt(p_RespawnNew) && (curTeam == UNASSIGNED_TEAM || curTeam == SPECTATOR_TEAM) && !p_Player[client][PLAYER_DIED])
			{
				if(p_currentTime > 30.0)
					CreateTimer(1.0, SpawnPlayer, any:client);
				
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_Teleport(client, args)
{
	if(isScriptEnabled() && GetConVarInt(p_Teleport))
	{
		decl String:p_tempString[255];
		GetConVarString(p_Display, p_tempString, sizeof(p_tempString));
		
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(!p_Player[client][PLAYER_TELEPORT])
			{
				if(GetConVarFloat(p_TeleportDelay) > 0.0 && canNotifyUser(3))
					PrintToChat(client, "\x04%s: \x01You will be teleported to your spawn in \x04%.1f\x01 seconds!", p_tempString, GetConVarFloat(p_TeleportDelay));
					
				//Save the player's teleport location if we're supposed to.
				if(GetConVarInt(p_TeleportCancel))
				{
					new Float:curLocation[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", curLocation);

					p_Locations[client][LOCATION_X] = curLocation[0];
					p_Locations[client][LOCATION_Y] = curLocation[1];
					p_Locations[client][LOCATION_Z] = curLocation[2];
				}
				
				CreateTimer(GetConVarFloat(p_TeleportDelay), TeleportPlayer, client);
				if(GetConVarFloat(p_TeleportRefresh) > 0.0)
				{
					p_Player[client][PLAYER_TELEPORT] = RoundFloat(p_currentTime + GetConVarFloat(p_TeleportRefresh) + GetConVarFloat(p_TeleportDelay));
					CreateTimer(GetConVarFloat(p_TeleportRefresh), RefreshTeleport, client);
				}     
			}
			else
			{
				if(canNotifyUser(3) && p_Player[client][PLAYER_TELEPORT] > RoundFloat(p_currentTime))
				{
					new timeLeft = p_Player[client][PLAYER_TELEPORT] - RoundFloat(p_currentTime);
					PrintToChat(client, "\x04%s: \x01You cannot use the teleport ability for \x04%d\x01 more seconds!", p_tempString, timeLeft);
				}
			}
		}
		else
			if(canNotifyUser(3))
				PrintToChat(client, "\x04%s: \x01You can only use the teleport ability if you're currently alive!", p_tempString);
	}

	return Plugin_Handled;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

public Action:loadMapConfigs(Handle:timer)
{
	if(cfgTimer != INVALID_HANDLE)
	{
		new String:currentMap[96], String:configDir[256];
		GetCurrentMap(currentMap, sizeof(currentMap));
		Format(configDir, sizeof(configDir), "cfg/surf_cfg/%s.cfg", currentMap);

		if(FileExists(configDir))     
			ServerCommand("exec surf_cfg/%s.cfg", currentMap);

		if(GetConVarInt(p_AirAccel))
		{
			new airAccelValue = GetConVarInt(airAccel);
			if(airAccelValue != GetConVarInt(p_AirAccel))
			SetConVarInt(airAccel, GetConVarInt(p_AirAccel));
			CloseHandle(airAccel);
		}
		
		cfgTimer = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action:globalCfgTime(Handle:timer)
{
	p_currentTime = p_currentTime + 1.0;

	if(globalTimer == INVALID_HANDLE)
		return Plugin_Stop;
	
	if(GetConVarFloat(p_RespawnTimer) > 0.0 && p_currentTime >= GetConVarFloat(p_RespawnTimer) && canRespawn)
		canRespawn = false;

	return Plugin_Continue;
}

public Action:deleteBuyZones(Handle:timer)
{
	if(deleteTimer != INVALID_HANDLE)
	{
		new buyZone = -1;
		while((buyZone = FindEntityByClassname(buyZone, "func_buyzone")) != -1)
			if(IsValidEntity(buyZone) && IsValidEdict(buyZone))
				RemoveEdict(buyZone);
		
		deleteTimer = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action:EnableCollisions(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client))
		SetEntData(client, p_CollisionGroup, 5, 4, true);
}

public Action:DisableCollisions(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && IsValidEntity(client))
		SetEntData(client, p_CollisionGroup, 2, 4, true);
}

public Action:EnableProtection(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
}

public Action:DisableProtection(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
}

public Action:TeleportPlayer(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:p_tempString[255];
		GetConVarString(p_Display, p_tempString, sizeof(p_tempString));
	
		new Float:curLocation[3];
		GetClientAbsOrigin(client, curLocation);
		
		new Float:curDistance = GetVectorDistance(curLocation, p_Locations[client]);
		new Float:cancelDistance = GetConVarFloat(p_TeleportCancelDistance);

		if (curDistance <= cancelDistance)
        {
			if(canNotifyUser(3))
				PrintToChat(client, "\x04%s: \x01You have been returned to your spawn position!", p_tempString);

			TeleportEntity(client, p_Spawns[client], NULL_VECTOR, NULL_VECTOR);
		}
		else
		{
			if(canNotifyUser(3))
			{
				if(cancelDistance == 0)
					PrintToChat(client, "\x04%s: \x01You cannot move after initiating a teleport!", p_tempString);	
				else
					PrintToChat(client, "\x04%s: \x01You cannot move more than \x04%.1f\x01 feet after initiating a teleport!", p_tempString, cancelDistance);	
			}					
		}
	}
	
}

public Action:RefreshTeleport(Handle:timer, any:client)
{
	if(IsClientInGame(client))
		p_Player[client][PLAYER_TELEPORT] = 0;
}

public Action:SpawnPlayer(Handle:timer, any:client)
{
	if(IsValidEntity(client) && IsClientInGame(client) && IsClientObserver(client) && !IsPlayerAlive(client))
	{
		new team = GetClientTeam(client);
		if(team == TERRORIST_TEAM || team == COUNTER_TERRORIST_TEAM)
			CS_RespawnPlayer(client);
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

bool:isScriptEnabled()
{
	switch (GetConVarInt(p_Enabled))
	{
		case -1:
		{
			if(p_isEnabled)
				return true;
			else
				return false;
		}
		case 0:
		{
			return false;
		}
		case 1:
		{
			return true;
		}
	}
	return true;
}

bool:canNotifyUser(index)
{
	switch (GetConVarInt(p_Notify))
	{
		case 0:
			return false;
		case 1:
			return true;
		case 2:
			if(index == GetConVarInt(p_Notify))
				return true;
		case 3:
			if(index == GetConVarInt(p_Notify))
				return true;
	}
	return true;
}