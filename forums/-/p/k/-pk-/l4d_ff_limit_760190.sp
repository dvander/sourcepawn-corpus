/********************************************************************************************
* Plugin	: l4d_ff_limit
* Version	: 1.1.1
* Game		: Left 4 Dead
* Author	: -pk-
*
* Description	: Limits friendly-fire damage for Survivors and includes important features for servers.
*
* WARNING	: Requires sourcemod 1.2.  This plugin was tested with 2562 snapshot.
*
*
* Changelog	:
*
* Version 1.1.1 (02-21-2009)
*	- Players will now be logged when they receive a permban warning.
*	- Fix a player who is warned instead of being banned will no longer have their damage reset.
*	- Fix admins will no longer be notified that a player has reached the FF limit while the player
*	  is being banned.
*
* Version 1.1.0 (02-18-2009)
*	- Expert difficulty, (if greater than 0) l4d_ff_limit will be set to 0 (saferoom only) and
*	  l4d_ff_teammate will be disabled automatically.
*	- Advanced difficulty, (if greater than 0) l4d_ff_limit and l4d_ff_teammate will be multiplied
*	  by 4.5, and l4d_ff_grenmin will be multilpied by 2.
*
* Version 1.0.9 (02-17-2009)
*	- Add cvars l4d_ff_permban_x and l4d_ff_permban_y, X number of bans allowed within Y days until
*	  a player is permanently banned.
*	- If ban duration is set to 0, and l4d_ff_ban is set to 1 or 2, and l4d_ff_permban_y is greater
*	  than 0 Days, a player will recieve a warning instead of being banned. The player will be
*	  permanently banned once they reach l4d_ff_permban_x warnings/bans.
*
* Version 1.0.8 (02-15-2009)
*	- Fix bug in 1.0.7 causing missing name in chat when player is banned.
*
* Version 1.0.7 (02-14-2009)
*	- Add ability to ban by IP address instead of clientID, by entering negative l4d_ff_ban values.
*
* Version 1.0.6 (02-14-2009)
*	- Admins are immune if they have any of the following flags "abcdfz"
*	- Fix accidentally banning admins after rewriting the code in 1.0.4.
*	- Fix grenade damage can now be dealt to a player after reaching the Teammate FF limit as long as
*	  the damage is above grendmg_min (where damage will not be counted as FF) and below grendmg_max.
*
* Version 1.0.5 (02-13-2009)
*	- Add l4d_ff_grendmg_min = -1 (infinite).
*
* Version 1.0.4 (02-13-2009)
*	- Fix bug when l4d_ff_grendmg_min = 0 (do not count as FF).
*
* Version 1.0.3 (02-13-2009)
*	- Add cvar l4d_ff_grendmg_min, Grenade or Fire damage above this value will still hurt,
*	  but will not count against the player's FF limit.
*	- Add cvar l4d_ff_grendmg_max_team, a player can deal this much Grenade or Fire damage
*	  to Team before the damage is prevented.
*	- Add cvar l4d_ff_grendmg_max_teammate, a player can deal this much Grenade or Fire damage
*	  to Teammate before the damage is prevented.
*	- Damage to incapacitated players will no longer count towards FF limit, and will deal
*	  the normal damage.
*
* Version 1.0.2 (02-12-2009)
*	- Add cvar l4d_ff_teammate, limit max FF that can be dealt to a teammate.
*	- Add cvar l4d_ff_ban, ban method.
*	- Add: player's steamid is now logged.
*	- Improved Coop detection of player left saferoom.
*	- Fix bug when a player that has gone over the limit could sometimes heal a teammate
*	  with FF damage.
*
* Version 1.0.1 (02-11-2009)
*	- Add support for SourceBans.
*
* Version 1.0.0 (02-11-2009)
*	- initial release.
*
**********************************************************************************************/

#include <sourcemod>
#define PLUGIN_VERSION "1.1.1"
#define DEBUGMODE 0

#if DEBUGMODE
new bool:firstrun = true;
#endif

new offsetIsIncapacitated;

new Handle:kvBans; //handle for banDB
new String:fileFFVault[128]; //file for FF Bans
new String:fileFFLog[128]; //file for FF Log
new bool:lateLoaded;  // Check if plugin was late loaded

new TotalDamageDoneTA[MAXPLAYERS+1][MAXPLAYERS+1];  // [attacker][0] stores total damage to team, [attacker][victim] stores damage to teammate
new TotalGrenadeDamageTA[MAXPLAYERS+1][MAXPLAYERS+1];
new NotifyLimitReached[MAXPLAYERS+1];
new bool:LeavedSafeRoom = false;
new bool:activated = true;

new Handle:FFlimit = INVALID_HANDLE;
new Handle:FFteammate = INVALID_HANDLE;
new Handle:FFGrendmgMin = INVALID_HANDLE;
new Handle:FFGrendmgMaxTeam = INVALID_HANDLE;
new Handle:FFGrendmgMaxTeammate = INVALID_HANDLE;
new Handle:FFnotify = INVALID_HANDLE;
new Handle:FFban = INVALID_HANDLE;
new Handle:FFbanduration = INVALID_HANDLE;
new Handle:FFbanexpire = INVALID_HANDLE;
new Handle:FFconsecutivebans = INVALID_HANDLE;
new Handle:FFlog = INVALID_HANDLE;
new Handle:announce = INVALID_HANDLE;
new Handle:g_SourceBans = INVALID_HANDLE;
new Handle:gamedifficulty = INVALID_HANDLE;
new g_difficulty;
new g_maxClients;
new g_limit;
new g_teammate;
new g_grenmin;
new g_grenmax_team;
new g_grenmax_teammate;


public Plugin:myinfo = 
{
	name = "L4D Friendly Fire Limit",
	author = "-pk-",
	description = "Limits friendly fire damage.",
	version = PLUGIN_VERSION,
	url = ""
};

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	lateLoaded = late;
	return true;
}

public OnPluginStart()
{
	// find offsets
	offsetIsIncapacitated = FindSendPropInfo("CTerrorPlayer", "m_isIncapacitated");	//6924

	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));

	if (!StrEqual(ModName, "left4dead", false))
	{
		SetFailState("Use this in Left 4 Dead only.");
	}

	CreateConVar("l4d_fflimit_version", PLUGIN_VERSION, "L4D Friendly Fire Limiter", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	FFlimit = CreateConVar("l4d_ff_limit", "60", "-1 = Block All Damage (full map), 0 = Block All Damage (saferoom only), any other = Player can deal this much damage to his entire Team.",FCVAR_NONE,true,-1.0);
	FFteammate = CreateConVar("l4d_ff_teammate", "30", "(limit > 0) Player can deal this much damage to each Teammate.",FCVAR_NONE,true,0.0);
	FFGrendmgMin = CreateConVar("l4d_ff_grendmg_min", "20", "(limit > 0) Grenade or Fire damage above this value will still hurt, but will not count against the player's FF limit. any value = Only count this much grendmg, -1 = infinite.",FCVAR_NONE,true,-1.0);
	FFGrendmgMaxTeam = CreateConVar("l4d_ff_grendmg_max_team", "40", "(limit > 0) Player can deal this much Grenade or Fire damage to Team before the damage is prevented. 0 = infinite.",FCVAR_NONE,true,0.0);
	FFGrendmgMaxTeammate = CreateConVar("l4d_ff_grendmg_max_teammate", "15", "(limit > 0) Player can deal this much Grenade or Fire damage to Teammate before the damage is prevented. 0 = infinite.",FCVAR_NONE,true,0.0);
	FFban = CreateConVar("l4d_ff_ban", "0", "0 = don't ban, 1 = Ban only if player reaches Team FF limit (limit = 40+), 2 = Ban whichever comes first (limit = 40+) or (teammate = 30+). Use negative values if you require ban by IP address.",FCVAR_NONE,true,-2.0,true,2.0);
	FFbanduration = CreateConVar("l4d_ff_banduration", "0", "(ban > 0) Ban Duration in minutes. 0 = Don't ban but warn the player if they may be permbanned.",FCVAR_NONE,true,0.0);
	FFconsecutivebans = CreateConVar("l4d_ff_permban_x", "3", "Valid between 2 to 5. A value of 2 will permanently ban the player on their 2nd offense, etc.",FCVAR_NONE,true,2.0,true,5.0);
	FFbanexpire = CreateConVar("l4d_ff_permban_y", "30", "(ban > 0) Only count the number of times the player was warned/banned within this many days. 0 = don't perm ban, any other = number of days.",FCVAR_NONE,true,0.0);
	FFlog = CreateConVar("l4d_ff_log", "1", "Log players that are banned or reach the FF limit (FriendlyFire.log). 0 = Disable, 1 = Enable.",FCVAR_NONE,true,0.0,true,1.0);
	FFnotify = CreateConVar("l4d_ff_notify", "1", "Notification when players reach the FF limit. 1 = Notify Admins.",FCVAR_NONE,true,0.0,true,1.0);
	announce = CreateConVar("l4d_ff_announce","1","For Survivors only.  0 = Don't Announce, 1 = Announce Active/Inactive Status (limit = 0) or Announce Limit (limit > 0)",FCVAR_NONE,true,0.0,true,1.0);
	gamedifficulty = FindConVar("z_difficulty");

	HookConVarChange(FFlimit,OnCVFFLimitChange);
	HookConVarChange(FFteammate,OnCVFFTeammateChange);
	HookConVarChange(FFGrendmgMin,OnCVGrenminChange);
	HookConVarChange(FFGrendmgMaxTeam,OnCVGrenmaxChange);
	HookConVarChange(FFGrendmgMaxTeammate,OnCVGrenmaxChange);

	AutoExecConfig(true, "l4d_ff_limit");

	HookEvent("difficulty_changed", Event_difficulty_changed);
	HookEvent("player_hurt", Event_player_hurt, EventHookMode_Pre);
	HookEvent("player_left_start_area", Event_player_left_start_area);
	HookEvent("door_open", Event_DoorOpen);
	HookEvent("round_start", Event_round_start);

  	BuildPath(Path_SM, fileFFVault, 128, "data/l4d_ff_limit_vault.txt");
  	BuildPath(Path_SM, fileFFLog, 128, "logs/FriendlyFire.log");

	//Create KeyValues
	kvBans=CreateKeyValues("PlayerBans");
	if (!FileToKeyValues(kvBans, fileFFVault))
	    	KeyValuesToFile(kvBans, fileFFVault);


	// If plugin was loaded after OnMapStart
	if (lateLoaded)
	{
		g_SourceBans = FindConVar("sb_version");  // SourceBans
		g_maxClients = GetMaxClients();
	}


	// Get the initial plugin settings and game difficulty

	new String:this[20];
	GetConVarString(gamedifficulty, this, sizeof(this)); 
	if (StrEqual("Easy", this, false))
		g_difficulty = 0;
	else if (StrEqual("Normal", this, false))
		g_difficulty = 1;
	else if (StrEqual("Hard", this, false))
		g_difficulty = 2;
	else if (StrEqual("Impossible", this, false))
		g_difficulty = 3;
	scaleDifficultySettings();

	g_grenmax_team = GetConVarInt(FFGrendmgMaxTeam);
	g_grenmax_teammate = GetConVarInt(FFGrendmgMaxTeammate);

	// if feature is disabled, set the max really high
	if (g_grenmax_team == 0)
		g_grenmax_team = 2500;
	if (g_grenmax_teammate == 0)
		g_grenmax_teammate = 2500;
}

public OnMapStart()
{
	g_SourceBans = FindConVar("sb_version");  // SourceBans
	g_maxClients = GetMaxClients();
}

public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	LeavedSafeRoom = false;
	activated = true;

	// Clear All Friendly-Fire
	if (GetConVarBool(announce))
	{
		for (new client = 1; client <= g_maxClients; client++)
		{
			// Announce
			if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
				PrintToChat(client, "\x04[SM]\x01 Friendly-Fire is disabled in spawn");

			NotifyLimitReached[client] = 0;

			for (new i = 0; i <= g_maxClients; i++)
			{
				TotalDamageDoneTA[client][i] = 0;
				TotalGrenadeDamageTA[client][i] = 0;
			}
		}
	}
	else
	{
		for (new client = 1; client <= g_maxClients; client++)
		{
			NotifyLimitReached[client] = 0;

			for (new i = 0; i <= g_maxClients; i++)
			{
				TotalDamageDoneTA[client][i] = 0;
				TotalGrenadeDamageTA[client][i] = 0;
			}
		}
	}
}

// Saferoom Detection for versus and first map of coop
public Action:Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!LeavedSafeRoom)
	{
		LeavedSafeRoom = true;
		Announce();
	}
}

// Saferoom Detection for coop
public Action:Event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!LeavedSafeRoom)
	{
		if (GetEventBool(event, "checkpoint"))
		{
			LeavedSafeRoom = true;
			Announce();
		}
	}
}

// Prepare new client
public OnClientPutInServer(client)
{
	// Clear client's FF damage
	if (!IsFakeClient(client))
	{
		NotifyLimitReached[client] = 0;

		for (new i = 0; i <= g_maxClients; i++)
		{
			TotalDamageDoneTA[client][i] = 0;
			TotalGrenadeDamageTA[client][i] = 0;
		}

		// Announce
		if (GetConVarBool(announce))
			CreateTimer(5.0, TimerAnnounce, client);
	}
}

// Announcement when a player joins the game
public Action:TimerAnnounce(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		if (!LeavedSafeRoom)
			PrintToChat(client, "\x04[SM]\x01 Friendly-Fire is disabled in spawn");
		else if (g_limit == 0)
			PrintToChat(client, "\x04[SM]\x01 Friendly-Fire is ON");
		else if (g_limit > 0)
			PrintToChat(client, "\x04[SM]\x01 Friendly-Fire Limit \x04%i HP\x01,  griefers may be banned.", g_limit);
	}
}

// Announcement when players leave saferoom
Announce()
{
	if (g_limit == 0)  // saferoom only
	{
		activated = false;  // stop checking for FF

		if (GetConVarBool(announce))
		{
			for (new i = 1; i <= g_maxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
				PrintToChat(i, "\x04[SM]\x01 Friendly-Fire is ON");
			}
		}
	}
	else if (g_limit > 0)  // FF limit
	{
		if (GetConVarBool(announce))
		{
			for (new i = 1; i <= g_maxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
				PrintToChat(i, "\x04[SM]\x01 Friendly-Fire Limit \x04%i HP\x01,  griefers may be banned.", g_limit);
			}
		}
	}
}

public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (activated)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (victim != 0 && attacker != 0)
		{
			if (!LeavedSafeRoom)
			{
				// Always block FF in saferoom
				if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2)
				{
					SetEntityHealth(victim,(GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")));
					return Plugin_Continue;
				}

				// Survivors have definately left the saferoom when an infected player/bot has taken damage.
				else
				{
					LeavedSafeRoom = true;

					Announce();
					return Plugin_Continue;
				}
			}
			else if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2)
			{
				// Block All Damage (full map), block FF damage from players that already reached the team FF limit (quick process), and block FF damage from bots
				if (g_limit < 0 || TotalDamageDoneTA[attacker][0] == g_limit || IsFakeClient(attacker))
				{
					SetEntityHealth(victim,(GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")));
					return Plugin_Continue;
				}

				// FF Limit
				else if (!IsPlayerIncapacitated(victim))
				{
					new damage = GetEventInt(event,"dmg_health");
					new type = GetEventInt(event, "type");
					new bool:grenade = false;

					// Check for Grenade or Fire damage
					if (type == 64 || type == 8 || type == 2056)
						grenade = true;


					#if DEBUGMODE
					DebugDamageOutput(attacker, victim, -1)
					#endif

					// while damage remains and no limit has been reached
					if (!grenade)
					{
						while ((damage > 0) && (TotalDamageDoneTA[attacker][0] < g_limit) && (TotalDamageDoneTA[attacker][victim] < g_teammate))
						{
							TotalDamageDoneTA[attacker][0] += 1;
							TotalDamageDoneTA[attacker][victim] += 1;
							damage--;
						}
					}
					else
					{
						while ((damage > 0) && (TotalGrenadeDamageTA[attacker][0] < g_grenmax_team) && (TotalGrenadeDamageTA[attacker][victim] < g_grenmax_teammate))
						{
							// below min, count the damage as friendly fire
							if (TotalGrenadeDamageTA[attacker][0] < g_grenmin || g_grenmin == -1)
							{
								if ((TotalDamageDoneTA[attacker][0] < g_limit) && (TotalDamageDoneTA[attacker][victim] < g_teammate))
								{
									TotalDamageDoneTA[attacker][0] += 1;
									TotalDamageDoneTA[attacker][victim] += 1;
								}
								else
								{
									// FF limit reached while grenade damage was below min
									break;
								}
							}

							TotalGrenadeDamageTA[attacker][0] += 1;
							TotalGrenadeDamageTA[attacker][victim] += 1;
							damage--;
						}
					}
					#if DEBUGMODE
					DebugDamageOutput(attacker, victim, damage)
					#endif


					// Heal excess damage
					if (damage > 0)
						SetEntityHealth(victim,(GetEventInt(event,"health") + damage));


					// Notify and Ban when a FF limit has been reached
					if (TotalDamageDoneTA[attacker][0] == g_limit)
					{
						// ban player?
						if (g_limit >= 40 && GetConVarInt(FFban) != 0)
							BanPlayer(attacker, 0);

						// notify admins
						if (GetConVarBool(FFnotify) && NotifyLimitReached[attacker] < 5)
							NotifyAdmins(attacker, 0);
					}
					else if (TotalDamageDoneTA[attacker][victim] == g_teammate)
					{
						// ban player?
						if (g_teammate >= 30 && (GetConVarInt(FFban) == 2 || GetConVarInt(FFban) == -2))
							BanPlayer(attacker, 1);

						// notify admins (only once for FF Teammate)
						if (GetConVarBool(FFnotify) && NotifyLimitReached[attacker] < 1)
							NotifyAdmins(attacker, 1);
					}
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}

bool:IsPlayerIncapacitated(client)
{
	new isIncapacitated;
	isIncapacitated = GetEntData(client, offsetIsIncapacitated, 1);
	
	if (isIncapacitated == 1)
		return true;
	else
	return false;
}

bool:CheckAdmin(client)
{
	new AdminId:id = GetUserAdmin(client);
	if (id == INVALID_ADMIN_ID)
		return false;
	
	// Check the Admin's flags
	if (GetAdminFlag(id, Admin_Reservation)||GetAdminFlag(id, Admin_Generic)||GetAdminFlag(id, Admin_Kick)||GetAdminFlag(id, Admin_Ban)||GetAdminFlag(id, Admin_Slay)||GetAdminFlag(id, Admin_Root))
		return true;
	else
	return false;
}

// Notification when player reaches limit
NotifyAdmins(client, reason)
{
	decl String:sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName));

	// Team FFlimit reached
	if (reason == 0)
	{
		for (new i = 1; i <= g_maxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetUserAdmin(client) != INVALID_ADMIN_ID)
				PrintToChat(i, "\x04(ADMINS)\x01 %s has reached the Friendly-Fire Limit: %i HP (Team)", sName, g_limit);
		}

		if (GetConVarBool(FFlog))
		{
			decl String:steamID[MAX_NAME_LENGTH];
			GetClientAuthString(client, steamID, sizeof(steamID));
			LogToFile(fileFFLog, "[%s] \"%s\" has reached the Friendly-Fire Limit: %i HP (Team)", steamID, sName, g_limit);
		}
	}
	// Teammate FFlimit reached
	else
	{
		NotifyLimitReached[client] = 1;

		for (new i = 1; i <= g_maxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetUserAdmin(client) != INVALID_ADMIN_ID)
				PrintToChat(i, "\x04(ADMINS)\x01 %s has reached the Friendly-Fire Limit: %i HP (Teammate)", sName, g_teammate);
		}

		if (GetConVarBool(FFlog))
		{
			decl String:steamID[MAX_NAME_LENGTH];
			GetClientAuthString(client, steamID, sizeof(steamID));
			LogToFile(fileFFLog, "[%s] \"%s\" has reached the Friendly-Fire Limit: %i HP (Teammate)", steamID, sName, g_teammate);
		}
	}
}

// Ban when player reaches limit
BanPlayer(client, reason)
{
	if(IsClientConnected(client) && IsClientInGame(client) && !CheckAdmin(client))
	{
		decl String:sName[MAX_NAME_LENGTH];
		decl String:steamID[MAX_NAME_LENGTH];
		GetClientName(client, sName, sizeof(sName));
		GetClientAuthString(client, steamID, sizeof(steamID));

		new timesBanned;
		if (NotifyLimitReached[client] < 2)  // If client was warned instead of being banned, max is 1 ban entry per round.
			timesBanned = CheckRecentBans(steamID);
			
		new nBansAllowed = GetConVarInt(FFconsecutivebans);
		if (timesBanned >= nBansAllowed)
		{
			//Log Player
			if (GetConVarBool(FFlog))
			{
				if (reason == 0)
					LogToFile(fileFFLog, "[%s] \"%s\" was permanently banned(%i) [Team FF %iHP]", steamID, sName, timesBanned, g_limit);
				else
					LogToFile(fileFFLog, "[%s] \"%s\" was permanently banned(%i) [Teammate FF %iHP]", steamID, sName, timesBanned, g_teammate);
			}
			PrintToChatAll("\x04[SM]\x01 %s was Permanently Banned(%i) for Friendly Fire", sName, timesBanned);
			NotifyLimitReached[client] = 5;

			// Permanent Ban
			if (GetConVarInt(FFban) < 0)  // banip
			{
				decl String:playerIP[16];
				GetClientIP(client, playerIP, sizeof(playerIP), true); 
				ServerCommand("sm_banip %s 0 \"FF Limit Reached\"", playerIP);
				ServerCommand("sm_kick #%d \"FF Limit Reached\"", GetClientUserId(client));
			}
			else if (g_SourceBans == INVALID_HANDLE)
				BanClient(client, 0, BANFLAG_AUTO, "FF Limit Reached", "FF Limit Reached", _, client);  // SM
			else
				ServerCommand("sm_ban #%d 0 \"FF Limit Reached\"", GetClientUserId(client));  // SourceBans

			// Clear the damage
			for (new i = 0; i <= g_maxClients; i++)
			{
				TotalDamageDoneTA[client][i] = 0;
				TotalGrenadeDamageTA[client][i] = 0;
			}
			return;
		}
		else
		{
			new duration = GetConVarInt(FFbanduration);
			if (duration >= 1)
			{
				//Log Player
				if (GetConVarBool(FFlog))
				{
					if (reason == 0)
						LogToFile(fileFFLog, "[%s] \"%s\" was banned for %d Minutes [Team FF %iHP]", steamID, sName, duration, g_limit);
					else
						LogToFile(fileFFLog, "[%s] \"%s\" was banned for %d Minutes [Teammate FF %iHP]", steamID, sName, duration, g_teammate);
				}
				PrintToChatAll("\x04[SM]\x01 %s was Banned %d Minutes for Friendly Fire", sName, duration);
				NotifyLimitReached[client] = 4;

				// Ban Duration
				if (GetConVarInt(FFban) < 0)  // banip
				{
					decl String:playerIP[16];
					GetClientIP(client, playerIP, sizeof(playerIP), true); 
					ServerCommand("sm_banip %s %d \"FF Limit Reached\"", playerIP, duration);
					ServerCommand("sm_kick #%d \"FF Limit Reached\"", GetClientUserId(client));
				}
				else if (g_SourceBans == INVALID_HANDLE)
					BanClient(client, duration, BANFLAG_AUTO, "FF Limit Reached", "FF Limit Reached", _, client);  // SM
				else
					ServerCommand("sm_ban #%d %d \"FF Limit Reached\"", GetClientUserId(client), duration);  // SourceBans

				// Clear the damage
				for (new i = 0; i <= g_maxClients; i++)
				{
					TotalDamageDoneTA[client][i] = 0;
					TotalGrenadeDamageTA[client][i] = 0;
				}
				return;
			}

			// Don't ban, but warn the player if they may be permbanned
			else if (nBansAllowed > 0 && NotifyLimitReached[client] < 2)
			{
				if (reason == 0)
				{
					if (GetConVarBool(FFlog))
						LogToFile(fileFFLog, "[%s] \"%s\" has received a warning(%i) [Team FF %iHP]", steamID, sName, timesBanned, g_limit);

					NotifyLimitReached[client] = 2;
					PrintToChat(client, "\x04[SM]\x01 You have reached the Friendly-Fire Limit: %i HP (Team)", g_limit);
					PrintToChat(client, "\x04[SM] Do this again and you will be permanently banned.");
				}
				else
				{
					if (GetConVarBool(FFlog))
						LogToFile(fileFFLog, "[%s] \"%s\" has received a warning(%i) [Teammate FF %iHP]", steamID, sName, timesBanned, g_teammate);

					NotifyLimitReached[client] = 2;
					PrintToChat(client, "\x04[SM]\x01 You have reached the Friendly-Fire Limit: %i HP (Teammate)", g_teammate);
					PrintToChat(client, "\x04[SM] Do this again and you will be permanently banned.");
				}
			}
			return;
		}
	}
}

// Adds a new keyvalue ban entry, and then returns how many times the steamID was recently banned.
CheckRecentBans(String:steamID[])
{
	new String:buffer[36];

	// Get the current date
	FormatTime(buffer, sizeof(buffer), "%j", GetTime());
	new currentDay = StringToInt(buffer);
	FormatTime(buffer, sizeof(buffer), "%Y", GetTime());
	new currentYear = StringToInt(buffer);


	KvRewind(kvBans);
	if (KvJumpToKey(kvBans, steamID))
	{
		// Retrieve the ban dates
		new day[4];
		new year[4];
		new String:dates[8][5];
		KvGetString(kvBans, "bans", buffer, sizeof(buffer), "0-0-0-0-0-0-0-0");
		ExplodeString(buffer, "-", dates, 8, 5);
		for (new i = 0; i < 4; i++)
		{
			day[i] = StringToInt(dates[i*2]);		// 0, 2, 4, 6
			year[i] = StringToInt(dates[(i*2) + 1]);	// 1, 3, 5, 7
			
		}

		// Count how many times the player was recently banned
		new timesBanned = 1;
		new expiration = GetConVarInt(FFbanexpire);
		if (expiration != 0)
		{
			// Find the expiration date
			new xDay = currentDay - expiration;
			new xYear = currentYear;
			while (xDay < 1)
			{
				xYear--;
				xDay += 365;
			}

			for (new i = 0; i < 4; i++)
			{
				if (year[i] > xYear)   //consecutive ban
					timesBanned++;
				else if (day[i] >= xDay)  //consecutive ban
					timesBanned++;
			}
		}

		// Replace the oldest ban entry
		new pointer = KvGetNum(kvBans, "pointer") + 1;
		if (pointer < 0 || pointer > 4)
			pointer = 0;

		day[pointer] = currentDay;
		year[pointer] = currentYear;


		// Update the keyvalues
		Format(buffer, sizeof(buffer), "%i-%i-%i-%i-%i-%i-%i-%i", day[0], year[0], day[1], year[1], day[2], year[2], day[3], year[3]);
		KvSetString(kvBans, "bans", buffer);
		KvSetNum(kvBans, "pointer", pointer);

		#if DEBUGMODE
		PrintToChatAll("%s", buffer);
		#endif

		// Save to file
		KvRewind(kvBans);
		KeyValuesToFile(kvBans, fileFFVault);

		return timesBanned;
	}
	else
	{
		// Create a new steamID ban entry
		KvJumpToKey(kvBans, steamID, true);
		Format(buffer, sizeof(buffer), "%i-%i-0-0-0-0-0-0", currentDay, currentYear);
		KvSetString(kvBans, "bans", buffer);
		KvSetNum(kvBans, "pointer", 0);

		#if DEBUGMODE
		PrintToChatAll("new %s", buffer);
		#endif

		// Save to file
		KvRewind(kvBans);
		KeyValuesToFile(kvBans, fileFFVault);

		return 1;
	}
}

public Action:Event_difficulty_changed(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_difficulty = GetEventInt(event, "newDifficulty");
	scaleDifficultySettings();
}

public OnCVGrenmaxChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_grenmax_team = GetConVarInt(FFGrendmgMaxTeam);
	g_grenmax_teammate = GetConVarInt(FFGrendmgMaxTeammate);

	// if feature is disabled, set the max really high
	if (g_grenmax_team == 0)
		g_grenmax_team = 2500;
	if (g_grenmax_teammate == 0)
		g_grenmax_teammate = 2500;
}

public OnCVGrenminChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (g_difficulty == 2)
	{
		g_grenmin = GetConVarInt(FFGrendmgMin) * 2;

		if (g_grenmin < 0)
			g_grenmin = -1;
	}
	else
		g_grenmin = GetConVarInt(FFGrendmgMin);
}

public OnCVFFLimitChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	switch (g_difficulty)
	{
	  case 0:
		g_limit = GetConVarInt(FFlimit);
	  case 1:
		g_limit = GetConVarInt(FFlimit);
	  case 2:
	  {
		g_limit = RoundToCeil(GetConVarInt(FFlimit) * 4.5);

		if (g_limit < 0)
			g_limit = -1;
	  }
	  case 3:
		g_limit = 0;
	}
}

public OnCVFFTeammateChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	switch (g_difficulty)
	{
	  case 0:
		g_teammate = GetConVarInt(FFteammate);
	  case 1:
		g_teammate = GetConVarInt(FFteammate);
	  case 2:
		g_teammate = RoundToCeil(GetConVarInt(FFteammate) * 4.5);
	  case 3:
		g_teammate = 0;
	}
}

scaleDifficultySettings()
{
	// Set FF limits according to difficulty
	switch (g_difficulty)
	{
	  case 0:
	  {
		g_limit = GetConVarInt(FFlimit);
		g_teammate = GetConVarInt(FFteammate);
		g_grenmin = GetConVarInt(FFGrendmgMin);
	  }
	  case 1:
	  {
		g_limit = GetConVarInt(FFlimit);
		g_teammate = GetConVarInt(FFteammate);
		g_grenmin = GetConVarInt(FFGrendmgMin);
	  }
	  case 2:
	  {
		g_limit = RoundToCeil(GetConVarInt(FFlimit) * 4.5);
		g_teammate = RoundToCeil(GetConVarInt(FFteammate) * 4.5);
		g_grenmin = GetConVarInt(FFGrendmgMin) * 2;

		if (g_limit < 0)
			g_limit = -1;
		if (g_grenmin < 0)
			g_grenmin = -1;
	  }
	  case 3:
	  {
		g_limit = 0;
		g_teammate = 0;
		g_grenmin = GetConVarInt(FFGrendmgMin);
	  }
	}
}



#if DEBUGMODE
DebugDamageOutput(attacker, victim, damage)
{
	if (damage == -1)
	{
		if (firstrun)
		{
			firstrun = false;
			new excessdmg[4];
			excessdmg[0] = TotalDamageDoneTA[attacker][0] - g_limit;
			excessdmg[1] = TotalDamageDoneTA[attacker][victim] - g_teammate;
			excessdmg[2] = TotalGrenadeDamageTA[attacker][0] - g_grenmax_team;
			excessdmg[3] = TotalGrenadeDamageTA[attacker][victim] - g_grenmax_teammate;

			for (new i = 0; i < 4; i++)
			{
				PrintToChatAll("[%i]: %i", i, excessdmg[i]);
			}
			PrintToChatAll("--^-BASE-^--");
		}
	}
	else
	{
		new excessdmg[4];
		excessdmg[0] = TotalDamageDoneTA[attacker][0] - g_limit;
		excessdmg[1] = TotalDamageDoneTA[attacker][victim] - g_teammate;
		excessdmg[2] = TotalGrenadeDamageTA[attacker][0] - g_grenmax_team;
		excessdmg[3] = TotalGrenadeDamageTA[attacker][victim] - g_grenmax_teammate;

		for (new i = 0; i < 4; i++)
		{
			PrintToChatAll("[%i]: %i", i, excessdmg[i]);
		}
		PrintToChatAll("dmg prevented: %i", damage);

		if (TotalGrenadeDamageTA[attacker][0] == g_grenmax_team)
			PrintToChatAll("Gren Team");
		if (TotalGrenadeDamageTA[attacker][victim] == g_grenmax_teammate)
			PrintToChatAll("Gren Teammate");
		if (TotalDamageDoneTA[attacker][0] == g_limit)
			PrintToChatAll("FF Team");
		if (TotalDamageDoneTA[attacker][victim] == g_teammate)
			PrintToChatAll("FF Teammate");
		PrintToChatAll("-----------------");
	}
}
#endif