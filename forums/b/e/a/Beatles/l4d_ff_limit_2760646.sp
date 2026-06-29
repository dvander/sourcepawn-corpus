#include <sourcemod>

#define PLUGIN_VERSION "1.1.2"

new offsetIsIncapacitated;

new Handle:kvBans;
new String:fileFFVault[128];
new String:fileFFLog[128];
new bool:lateLoaded;

new TotalDamageDoneTA[MAXPLAYERS+1][MAXPLAYERS+1];
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

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	lateLoaded = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	offsetIsIncapacitated = FindSendPropInfo("CTerrorPlayer", "m_isIncapacitated");	//6924

	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));

	if (!StrEqual(ModName, "left4dead", false))
	{
		SetFailState("Use this in Left 4 Dead only.");
	}

	CreateConVar("l4d_fflimit_version", PLUGIN_VERSION, "L4D Friendly Fire Limiter", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
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

	kvBans=CreateKeyValues("PlayerBans");
	if (!FileToKeyValues(kvBans, fileFFVault))
	    	KeyValuesToFile(kvBans, fileFFVault);

	if (lateLoaded)
	{
		g_SourceBans = FindConVar("sb_version");
		g_maxClients = MaxClients;
	}

	new String:gthis[16];
	GetConVarString(gamedifficulty, gthis, sizeof(gthis)); 
	if (StrEqual("Easy", gthis, false))
		g_difficulty = 0;
	else if (StrEqual("Normal", gthis, false))
		g_difficulty = 1;
	else if (StrEqual("Hard", gthis, false))
		g_difficulty = 2;
	else if (StrEqual("Impossible", gthis, false))
		g_difficulty = 3;
		
	scaleDifficultySettings();

	g_grenmax_team = GetConVarInt(FFGrendmgMaxTeam);
	g_grenmax_teammate = GetConVarInt(FFGrendmgMaxTeammate);

	if (g_grenmax_team == 0)
		g_grenmax_team = 2500;
	if (g_grenmax_teammate == 0)
		g_grenmax_teammate = 2500;
}

public OnMapStart()
{
	g_SourceBans = FindConVar("sb_version");  // SourceBans
	g_maxClients = MaxClients;
}

public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	LeavedSafeRoom = false;
	activated = true;

	if (GetConVarBool(announce))
	{
		for (new client = 1; client <= g_maxClients; client++)
		{
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

public Action:Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!LeavedSafeRoom)
	{
		LeavedSafeRoom = true;
		Announce();
	}
}

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

public OnClientPutInServer(client)
{
	if (!IsFakeClient(client))
	{
		NotifyLimitReached[client] = 0;

		for (new i = 0; i <= g_maxClients; i++)
		{
			TotalDamageDoneTA[client][i] = 0;
			TotalGrenadeDamageTA[client][i] = 0;
		}

		if (GetConVarBool(announce))
			CreateTimer(5.0, TimerAnnounce, client);
	}
}

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

Announce()
{
	if (g_limit == 0)
	{
		activated = false;

		if (GetConVarBool(announce))
		{
			for (new i = 1; i <= g_maxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
				PrintToChat(i, "\x04[SM]\x01 Friendly-Fire is ON");
			}
		}
	}
	else if (g_limit > 0)
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
				if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2)
				{
					SetEntityHealth(victim,(GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")));
					return Plugin_Continue;
				}
				else
				{
					LeavedSafeRoom = true;

					Announce();
					return Plugin_Continue;
				}
			}
			else if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2)
			{
				if (g_limit < 0 || TotalDamageDoneTA[attacker][0] == g_limit || IsFakeClient(attacker))
				{
					SetEntityHealth(victim,(GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")));
					return Plugin_Continue;
				}
				else if (!IsPlayerIncapacitated(victim))
				{
					new damage = GetEventInt(event,"dmg_health");
					new type = GetEventInt(event, "type");
					new bool:grenade = false;

					if (type == 64 || type == 8 || type == 2056)
						grenade = true;

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
							if (TotalGrenadeDamageTA[attacker][0] < g_grenmin || g_grenmin == -1)
							{
								if ((TotalDamageDoneTA[attacker][0] < g_limit) && (TotalDamageDoneTA[attacker][victim] < g_teammate))
								{
									TotalDamageDoneTA[attacker][0] += 1;
									TotalDamageDoneTA[attacker][victim] += 1;
								}
								else
								{
									break;
								}
							}

							TotalGrenadeDamageTA[attacker][0] += 1;
							TotalGrenadeDamageTA[attacker][victim] += 1;
							damage--;
						}
					}

					if (damage > 0)
						SetEntityHealth(victim,(GetEventInt(event,"health") + damage));

					if (TotalDamageDoneTA[attacker][0] == g_limit)
					{
						if (g_limit >= 40 && GetConVarInt(FFban) != 0)
							BanPlayer(attacker, 0);

						if (GetConVarBool(FFnotify) && NotifyLimitReached[attacker] < 5)
							NotifyAdmins(attacker, 0);
					}
					else if (TotalDamageDoneTA[attacker][victim] == g_teammate)
					{
						if (g_teammate >= 30 && (GetConVarInt(FFban) == 2 || GetConVarInt(FFban) == -2))
							BanPlayer(attacker, 1);

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
	
	if (GetAdminFlag(id, Admin_Reservation)||GetAdminFlag(id, Admin_Generic)||GetAdminFlag(id, Admin_Kick)||GetAdminFlag(id, Admin_Ban)||GetAdminFlag(id, Admin_Slay)||GetAdminFlag(id, Admin_Root))
		return true;
	else
	return false;
}

NotifyAdmins(client, reason)
{
	decl String:sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName));

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
			GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
			LogToFile(fileFFLog, "[%s] \"%s\" has reached the Friendly-Fire Limit: %i HP (Team)", steamID, sName, g_limit);
		}
	}
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
			GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
			LogToFile(fileFFLog, "[%s] \"%s\" has reached the Friendly-Fire Limit: %i HP (Teammate)", steamID, sName, g_teammate);
		}
	}
}

BanPlayer(client, reason)
{
	if(IsClientConnected(client) && IsClientInGame(client) && !CheckAdmin(client))
	{
		decl String:sName[MAX_NAME_LENGTH];
		decl String:steamID[MAX_NAME_LENGTH];
		GetClientName(client, sName, sizeof(sName));
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));

		new timesBanned;
		if (NotifyLimitReached[client] < 2)
			timesBanned = CheckRecentBans(steamID);
			
		new nBansAllowed = GetConVarInt(FFconsecutivebans);
		if (timesBanned >= nBansAllowed)
		{
			if (GetConVarBool(FFlog))
			{
				if (reason == 0)
					LogToFile(fileFFLog, "[%s] \"%s\" was permanently banned(%i) [Team FF %iHP]", steamID, sName, timesBanned, g_limit);
				else
					LogToFile(fileFFLog, "[%s] \"%s\" was permanently banned(%i) [Teammate FF %iHP]", steamID, sName, timesBanned, g_teammate);
			}
			PrintToChatAll("\x04[SM]\x01 %s was Permanently Banned(%i) for Friendly Fire", sName, timesBanned);
			NotifyLimitReached[client] = 5;

			if (GetConVarInt(FFban) < 0)
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
				if (GetConVarBool(FFlog))
				{
					if (reason == 0)
						LogToFile(fileFFLog, "[%s] \"%s\" was banned for %d Minutes [Team FF %iHP]", steamID, sName, duration, g_limit);
					else
						LogToFile(fileFFLog, "[%s] \"%s\" was banned for %d Minutes [Teammate FF %iHP]", steamID, sName, duration, g_teammate);
				}
				PrintToChatAll("\x04[SM]\x01 %s was Banned %d Minutes for Friendly Fire", sName, duration);
				NotifyLimitReached[client] = 4;

				if (GetConVarInt(FFban) < 0)
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

				for (new i = 0; i <= g_maxClients; i++)
				{
					TotalDamageDoneTA[client][i] = 0;
					TotalGrenadeDamageTA[client][i] = 0;
				}
				return;
			}
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

CheckRecentBans(String:steamID[])
{
	new String:buffer[36];

	FormatTime(buffer, sizeof(buffer), "%j", GetTime());
	new currentDay = StringToInt(buffer);
	FormatTime(buffer, sizeof(buffer), "%Y", GetTime());
	new currentYear = StringToInt(buffer);


	KvRewind(kvBans);
	if (KvJumpToKey(kvBans, steamID))
	{
		new day[4];
		new year[4];
		new String:dates[8][5];
		KvGetString(kvBans, "bans", buffer, sizeof(buffer), "0-0-0-0-0-0-0-0");
		ExplodeString(buffer, "-", dates, 8, 5);
		for (new i = 0; i < 4; i++)
		{
			day[i] = StringToInt(dates[i*2]);
			year[i] = StringToInt(dates[(i*2) + 1]);
			
		}

		new timesBanned = 1;
		new expiration = GetConVarInt(FFbanexpire);
		if (expiration != 0)
		{
			new xDay = currentDay - expiration;
			new xYear = currentYear;
			while (xDay < 1)
			{
				xYear--;
				xDay += 365;
			}

			for (new i = 0; i < 4; i++)
			{
				if (year[i] > xYear)
					timesBanned++;
				else if (day[i] >= xDay)
					timesBanned++;
			}
		}

		new pointer = KvGetNum(kvBans, "pointer") + 1;
		if (pointer < 0 || pointer > 4)
			pointer = 0;

		day[pointer] = currentDay;
		year[pointer] = currentYear;

		Format(buffer, sizeof(buffer), "%i-%i-%i-%i-%i-%i-%i-%i", day[0], year[0], day[1], year[1], day[2], year[2], day[3], year[3]);
		KvSetString(kvBans, "bans", buffer);
		KvSetNum(kvBans, "pointer", pointer);

		KvRewind(kvBans);
		KeyValuesToFile(kvBans, fileFFVault);

		return timesBanned;
	}
	else
	{
		KvJumpToKey(kvBans, steamID, true);
		Format(buffer, sizeof(buffer), "%i-%i-0-0-0-0-0-0", currentDay, currentYear);
		KvSetString(kvBans, "bans", buffer);
		KvSetNum(kvBans, "pointer", 0);

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