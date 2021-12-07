#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define L4D2 Bonus Healing
#define PLUGIN_VERSION "1.31"

new bool:isHooked = false;
new bool:isSpawn = false;
new bool:isHPSet[MAXPLAYERS+1] = false;
new bool:isBot = false;
new bool:isMedkitAnnounce = false;
new bool:isPillsAnnounce = false;
new bool:isAdrenAnnounce = false;
new bool:isReviveAnnounce = false;
new bool:isAutoReviveAnnounce = false;
new bool:isAutoRevive = false;
new bool:isReviveTimeout[MAXPLAYERS+1] = false;

new Handle:cvarEnable;
new Handle:cvarSpawn;
new Handle:cvarBot;

new Handle:cvarSurvivorHP;
new Handle:cvarSurvivorIncapHP;
new Handle:cvarMedkitBonusHP;
new Handle:cvarMedkitBuffHP;
new Handle:cvarMedkitAnnounce;
new Handle:cvarPillsBonusHP;
new Handle:cvarPillsBuffHP;
new Handle:cvarPillsAnnounce;
new Handle:cvarAdrenBonusHP;
new Handle:cvarAdrenBuffHP;
new Handle:cvarAdrenAnnounce;
new Handle:cvarReviveeBonusHP;
new Handle:cvarReviveeBuffHP;
new Handle:cvarReviverBonusHP;
new Handle:cvarReviverBuffHP;
new Handle:cvarReviveAnnounce;
new Handle:cvarReviveBonus;
new Handle:cvarRevivePercent;
new Handle:cvarAutoRevive;
new Handle:cvarAutoReviveHP;
new Handle:cvarAutoReviveChance;
new Handle:cvarAutoReviveTimeout;
new Handle:cvarAutoReviveAnnounce;
new Handle:cvarHealerMedkitBonus;
new Handle:cvarHealerMedkitBuff;

new Handle:AutoReviveTimer[MAXPLAYERS +1] = INVALID_HANDLE;
new Handle:AutoReviveTimeout[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:ReviveSuccessTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:InitialSpawnTimer[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:SpawnTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

new Float:ReviveDuration;
new Float:RevivePercent;
new BufferHP = -1;
new HeartSound[MAXPLAYERS+1];

new String:modName[32];

public Plugin:myinfo = 
{
    name = "[L4D2] Bonus Healing",
    author = "Mortiegama",
    description = "Allows you to set a custom health value for survivors and gives bonus healing when using medkits/pills.",
    version = PLUGIN_VERSION,
    url = ""

	//Special Thanks:
	//ChinaGreenElvis - Autohelp
	//http://forums.alliedmods.net/showthread.php?t=170454
	//Used some code for Auto Revive
}

public OnPluginStart()
{
	CreateConVar("sm_bonushealing_version", PLUGIN_VERSION, "Bonus Healing Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarEnable = CreateConVar("sm_bonushealing_enable", "1", "Enables the Bonus Healing plugin (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarSpawn = CreateConVar("sm_bonushealing_spawn", "0", "Will set the HP for a Survivor anytime a new Survivor joins (Def 0)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarBot = CreateConVar("sm_bonushealing_bot", "1", "Will bots have their health adjusted (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarSurvivorHP = CreateConVar("sm_bonushealing_survivorhp", "150", "Max HP of the Survivor (Def 150)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSurvivorIncapHP = CreateConVar("sm_bonushealing_survivorhp", "500", "Max HP of the Survivor when incapped (Def 500)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarAutoRevive = CreateConVar("sm_bonushealing_autorevive", "1", "Will a player have a chance to revive if another player is incapped (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAutoReviveTimeout = CreateConVar("sm_bonushealing_autorevivetimeout", "30", "Amount of seconds to wait before allowing survivor to auto revive again (Def 30)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAutoReviveHP = CreateConVar("sm_bonushealing_autorevivehp", "50", "Amount of bonus HP granted after a player is autorevived (Def 50)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAutoReviveChance = CreateConVar("sm_bonushealing_autorevivechance", "20", "Chance that the Hunter pounce will incap Survivor (20 = 20%). (Def 20)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarMedkitBonusHP = CreateConVar("sm_bonushealing_medkitbonushp", "20", "Amount of bonus HP granted by the Medkit (Def 20)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarMedkitBuffHP = CreateConVar("sm_bonushealing_medkitbuffhp", "10", "Amount of bonus temporary HP granted by the Medkit (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarHealerMedkitBonus = CreateConVar("sm_bonushealing_healermedkitbonus", "10", "Amount of bonus HP granted for healing another person with the Medkit (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarHealerMedkitBuff = CreateConVar("sm_bonushealing_healermedkitbuff", "5", "Amount of bonus temporary HP granted for healing another person with the Medkit (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarPillsBonusHP = CreateConVar("sm_bonushealing_pillsbonushp", "5", "Amount of bonus HP granted by the Pills (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarPillsBuffHP = CreateConVar("sm_bonushealing_pillsbuffhp", "10", "Amount of bonus temporary HP granted by the Pills (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarAdrenBonusHP = CreateConVar("sm_bonushealing_adrenalinebonushp", "5", "Amount of bonus HP granted by the Adrenaline (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAdrenBuffHP = CreateConVar("sm_bonushealing_adrenalinebuffhp", "10", "Amount of bonus temporary HP granted by the Adrenaline (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarReviveeBonusHP = CreateConVar("sm_bonushealing_reviveebonushp", "10", "Amount of bonus HP granted to the Survivor that was revived (Def 10)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarReviveeBuffHP = CreateConVar("sm_bonushealing_reviveebuffhp", "15", "Amount of bonus temporary HP granted to the Survivor that was revived (Def 15)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarReviverBonusHP = CreateConVar("sm_bonushealing_reviverbonushp", "5", "Amount of bonus HP granted to the Survivor who did the reviving (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarReviverBuffHP = CreateConVar("sm_bonushealing_reviverbuffhp", "5", "Amount of bonus temporary HP granted to the Survivor who did the reviving (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarReviveBonus = CreateConVar("sm_bonushealing_revivebonus", "1", "Enables altering the revive speed (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarRevivePercent = CreateConVar("sm_bonushealing_revivepercent", "0.7", "Percent to reduce revive speed (Def 0.7)", FCVAR_PLUGIN, true, 0.0, false, _);
	ReviveDuration	= GetConVarFloat(FindConVar("survivor_revive_duration"));
	
	cvarMedkitAnnounce = CreateConVar("sm_bonushealing_medkitannounce", "1", "Will healing from a medkit be announced (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarPillsAnnounce = CreateConVar("sm_bonushealing_pillsannounce", "1", "Will healing from a pills be announced (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAdrenAnnounce = CreateConVar("sm_bonushealing_adrenannounce", "1", "Will healing from a adrenaline be announced (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarReviveAnnounce = CreateConVar("sm_bonushealing_reviveannounce", "1", "Will bonus healing for reviving be announced (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAutoReviveAnnounce = CreateConVar("sm_bonushealing_autoreviveannounce", "1", "Will functions of auto reviving be announced (Def 1)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "plugin.L4D2.BonusHealing");
	GetGameFolderName(modName, sizeof(modName));

	if (GetConVarInt(cvarEnable))
	{
		isHooked = true;
		LogMessage("[Bonus Healing] - Loaded");
	}

	if (GetConVarInt(cvarSpawn))
	{
		isSpawn = true;
	}
	
	if (GetConVarInt(cvarBot))
	{
		isBot = true;
	}
	
	if (GetConVarInt(cvarAutoRevive))
	{
		isAutoRevive = true;
	}

	if (GetConVarInt(cvarMedkitAnnounce))
	{
		isMedkitAnnounce = true;
	}

	if (GetConVarInt(cvarPillsAnnounce))
	{
		isPillsAnnounce = true;
	}
	
	if (GetConVarInt(cvarAdrenAnnounce))
	{
		isAdrenAnnounce = true;
	}
	
	if (GetConVarInt(cvarReviveAnnounce))
	{
		isReviveAnnounce = true;
	}
	
	if (GetConVarInt(cvarAutoReviveAnnounce))
	{
		isAutoReviveAnnounce = true;
	}
	
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("player_first_spawn", event_PlayerFirstSpawn);
	HookEvent("heal_success", event_HealSuccess);
	HookEvent("revive_success", event_ReviveSuccess);
	HookEvent("pills_used", event_PillsUsed);
	HookEvent("adrenaline_used", event_AdrenUsed);
	HookEvent("player_incapacitated", event_PlayerIncapped);	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	BufferHP = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	
	if (GetConVarInt(cvarReviveBonus))
	{
		RevivePercent = GetConVarFloat(cvarRevivePercent);
		SetConVarFloat(FindConVar("survivor_revive_duration"), ReviveDuration * RevivePercent, false, false);
	}
	
	new Float:IncapHP = GetConVarFloat(cvarSurvivorIncapHP);
	new Float:ReviveHP = GetConVarFloat(cvarAutoReviveHP);
	
	SetConVarFloat(FindConVar("survivor_incap_health"), IncapHP, false, false);
	SetConVarFloat(FindConVar("survivor_ledge_grab_health"), IncapHP, false, false);
	SetConVarFloat(FindConVar("survivor_revive_health"), ReviveHP, false, false);
}

public event_PlayerFirstSpawn (Handle:event, const String:name[], bool:dontBroadcast)
{
    new client=GetClientOfUserId(GetEventInt(event,"userid"));

	if (GetClientTeam(client) == 2 && isHooked)
	{
		InitialSpawnTimer[client] = CreateTimer(1.0, Timer_InitialSetHealth, client);
		isHPSet[client] = true;
	}
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && !isHPSet[client] && isHooked && isSpawn)
	{
		SpawnTimer[client] = CreateTimer(1.5, Timer_SetHealth, client);
		isHPSet[client] = true;
	}
}

public Action:Timer_InitialSetHealth(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		new sMaxHP = GetConVarInt(cvarSurvivorHP);
		SetEntProp(client, Prop_Send, "m_iHealth", sMaxHP, 1);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
	}
	
	if (InitialSpawnTimer[client] != INVALID_HANDLE)
	{
 		KillTimer(InitialSpawnTimer[client]);
		InitialSpawnTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public Action:Timer_SetHealth(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		new sMaxHP = GetConVarInt(cvarSurvivorHP);
		SetEntProp(client, Prop_Send, "m_iHealth", sMaxHP, 1);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
	}
	
	if (SpawnTimer[client] != INVALID_HANDLE)
	{
 		KillTimer(SpawnTimer[client]);
		SpawnTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"subject"));
	new healer = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && isHooked)
	{
		StopBeat(client);
		new sHP = GetClientHealth(client);
		new Float:sBuff = GetEntDataFloat(client, BufferHP);
		new sMaxHP = GetConVarInt(cvarSurvivorHP);
		new sBonusHP = GetConVarInt(cvarMedkitBonusHP);
		new sBuffHP = GetConVarInt(cvarMedkitBuffHP);

		if ((sBonusHP + sBuffHP + sHP) <= sMaxHP) 
		{
    		SetEntProp(client, Prop_Send, "m_iHealth", sBonusHP + sHP, 1);
			SetEntDataFloat(client, BufferHP, sBuff + sBuffHP, true);
			if(isMedkitAnnounce){PrintHintText(client, "You were healed for an extra %i HP with %i Buffed HP.", sBonusHP, sBuffHP);}
		}

		else if(isMedkitAnnounce){PrintHintText(client, "Bonus healing has failed, it exceeds your max HP.");}
	}

	if (IsValidClient(healer) && GetClientTeam(healer) == 2 && isHooked)
	{
		if (client == healer) return;

		new hHP = GetClientHealth(healer);
		new Float:hBuff = GetEntDataFloat(healer, BufferHP);
		new hMaxHP = GetConVarInt(cvarSurvivorHP);
		new hBonusHP = GetConVarInt(cvarHealerMedkitBonus);
		new hBuffHP = GetConVarInt(cvarHealerMedkitBuff);

		if ((hBonusHP + hBuffHP + hHP) <= hMaxHP) 
		{
    		SetEntProp(healer, Prop_Send, "m_iHealth", hBonusHP + hHP, 1);
			SetEntDataFloat(healer, BufferHP, hBuff + hBuffHP, true);
			if (isMedkitAnnounce){PrintHintText(healer, "You received an extra %i HP and %i Buffed HP for healing %n.", hBonusHP, hBuffHP, client);}
		}

		else if(isMedkitAnnounce){PrintHintText(healer, "Bonus healing has failed, it exceeds your max HP.");}
	}
}

public event_PillsUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"subject"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && isHooked)
	{
		new sHP = GetClientHealth(client);
		new Float:sBuff = GetEntDataFloat(client, BufferHP);
		new sMaxHP = GetConVarInt(cvarSurvivorHP);
		new sBonusHP = GetConVarInt(cvarPillsBonusHP);
		new sBuffHP = GetConVarInt(cvarPillsBuffHP);

		if ((sBonusHP + sBuffHP + sHP) <= sMaxHP) 
		{
    		SetEntProp(client, Prop_Send, "m_iHealth", sBonusHP + sHP, 1);
			SetEntDataFloat(client, BufferHP, sBuff + sBuffHP, true);
			if (isPillsAnnounce){PrintHintText(client, "You were healed for an extra %i HP with %i Buffed HP.", sBonusHP, sBuffHP);}
		}

		else if(isPillsAnnounce){PrintHintText(client, "Bonus healing has failed, it exceeds your max HP.");}
	}
}


public event_AdrenUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (IsValidClient(client) && GetClientTeam(client) == 2 && isHooked)
	{
		new sHP = GetClientHealth(client);
		new Float:sBuff = GetEntDataFloat(client, BufferHP);
		new sMaxHP = GetConVarInt(cvarSurvivorHP);
		new sBonusHP = GetConVarInt(cvarAdrenBonusHP);
		new sBuffHP = GetConVarInt(cvarAdrenBuffHP);

		if ((sBonusHP + sBuffHP + sHP) <= sMaxHP) 
		{
    		SetEntProp(client, Prop_Send, "m_iHealth", sBonusHP + sHP, 1);
			SetEntDataFloat(client, BufferHP, sBuff + sBuffHP, true);
			if (isAdrenAnnounce){PrintHintText(client, "You were healed for an extra %i HP with %i Buffed HP.", sBonusHP, sBuffHP);}
		}

		else if(isPillsAnnounce){PrintHintText(client, "Bonus healing has failed, it exceeds your max HP.");}
	}
}

public event_PlayerIncapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (isAutoRevive && IsValidClient(client) && GetClientTeam(client) == 2)
	{
		AutoReviveTimer[client] = CreateTimer(0.1, AutoRevive, client);
	}
}

public event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"subject"));
	new reviver = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (AutoReviveTimer[client] != INVALID_HANDLE)
	{
		KillTimer(AutoReviveTimer[client]);
		AutoReviveTimer[client] = INVALID_HANDLE;
	}

	ReviveSuccessTimer[client] = CreateTimer(0.1, ReviveSuccess, client);

	if (IsValidClient(reviver) && GetClientTeam(reviver) == 2 && isHooked)
	{
		if (client == reviver){return;}
		new rHP = GetClientHealth(reviver);
		new Float:rBuff = GetEntDataFloat(reviver, BufferHP);
		new rMaxHP = GetConVarInt(cvarSurvivorHP);
		new rBonusHP = GetConVarInt(cvarReviverBonusHP);
		new rBuffHP = GetConVarInt(cvarReviverBuffHP);

		if ((rBonusHP + rBuffHP + rHP) <= rMaxHP) 
		{
    		SetEntProp(reviver, Prop_Send, "m_iHealth", rBonusHP + rHP, 1);
			SetEntDataFloat(reviver, BufferHP, rBuff + rBuffHP, true);
			if (isReviveAnnounce){PrintHintText(reviver, "You received %i HP and %i Buffed HP for reviving %n.", rBonusHP, rBuffHP, client);}
		}

		else if(isReviveAnnounce){PrintHintText(reviver, "Bonus healing has failed, it exceeds your max HP.");}
	}
}

public Action:AutoRevive(Handle:timer, any:client)
{
	if (!isReviveTimeout[client])
	{
		//PrintToChatAll("No timeout, continue revive.");
		PerformRevive(client);
			
		if (AutoReviveTimer[client] != INVALID_HANDLE)
		{
			KillTimer(AutoReviveTimer[client]);
			AutoReviveTimer[client] = INVALID_HANDLE;
		}
		
		return;
	}
		
	if (isReviveTimeout[client] && IsPlayerAlive(client))
	{
		if (AutoReviveTimer[client] != INVALID_HANDLE)
		{
			KillTimer(AutoReviveTimer[client]);
			AutoReviveTimer[client] = INVALID_HANDLE;
		}
		
		AutoReviveTimer[client] = CreateTimer(1.0, AutoRevive, client);
	}
}

PerformRevive(client)
{
	new AutoReviveChance = GetRandomInt(0, 99);
	new AutoRevivePercent = (GetConVarInt(cvarAutoReviveChance));
				
	if ((AutoReviveChance < AutoRevivePercent))
	{
		new revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
		new ReviveHP = GetConVarInt(FindConVar("survivor_revive_health"));

		SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
		SetEntProp(client, Prop_Send, "m_iHealth", ReviveHP, 1);
		SetEntProp(client, Prop_Send, "m_currentReviveCount", (revivecount + 1));
		if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
		{
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
			EmitSoundToClient(client, "player/heartbeatloop.wav");
			HeartSound[client] = 1;
		}
		AutoReviveTimeout[client] = CreateTimer(float(GetConVarInt(cvarAutoReviveTimeout)), AutoReviveTimeoutTimer, client);
		new Countdown = GetConVarInt(cvarAutoReviveTimeout);
		isReviveTimeout[client] = true;
		PrintToServer("Player has been revived");
		if (isAutoReviveAnnounce){PrintHintText(client, "You have revived yourself, you can revive again in %i seconds.", Countdown);}
	}
}

public Action:AutoReviveTimeoutTimer(Handle:timer, any:client)
{
	isReviveTimeout[client] = false;
	if (isAutoReviveAnnounce){PrintHintText(client, "You will be able to revive again.");}
	
	if (AutoReviveTimeout[client] != INVALID_HANDLE)
	{
		KillTimer(AutoReviveTimeout[client]);
		AutoReviveTimeout[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public Action:ReviveSuccess(Handle:timer, any:client)
{
	if (IsValidClient(client) && GetClientTeam(client) == 2 && isHooked)
	{
		new sHP = GetClientHealth(client);
		new Float:sBuff = GetEntDataFloat(client, BufferHP);
		new sMaxHP = GetConVarInt(cvarSurvivorHP);
		new sBonusHP = GetConVarInt(cvarReviveeBonusHP);
		new sBuffHP = GetConVarInt(cvarReviveeBuffHP);

		if ((sBonusHP + sBuffHP + sHP) <= sMaxHP) 
		{
    		SetEntProp(client, Prop_Send, "m_iHealth", sBonusHP + sHP, 1);
			SetEntDataFloat(client, BufferHP, sBuff + sBuffHP, true);
			if(isReviveAnnounce){PrintHintText(client, "You were revived and received %i HP with %i Buffed HP.", sBonusHP, sBuffHP);}
		}

		else if(isReviveAnnounce){PrintHintText(client, "Bonus healing has failed, it exceeds your max HP.");}
	}

	if (ReviveSuccessTimer[client] != INVALID_HANDLE)
	{
		KillTimer(ReviveSuccessTimer[client]);
		ReviveSuccessTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public IsValidClient(client)
{
	if (client == 0)
		return false;

	if (!IsClientInGame(client))
		return false;
		
	if (IsFakeClient(client) && !isBot)
		return false;

	if (!IsPlayerAlive(client))
		return false;

	return true;
}

StopBeat(client)
{
	if (HeartSound[client])
	{
		StopSound(client, SNDCHAN_AUTO, "player/heartbeatloop.wav");
		HeartSound[client] = 0;
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		Reset(client);
	}
}

public Event_PlayerTransitioned (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		Reset(client);
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new client=1; client<=MaxClients; client++)
	{
		if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
			Reset(client);
		}
	}
}

public OnMapEnd()
{
    for (new client=1; client<=MaxClients; client++)
	{
		if (IsValidClient(client) && GetClientTeam(client) == 2)
		{
			Reset(client);
		}
	}
}

Reset(client)
{
	if (IsValidClient(client))
	{
		isHPSet[client] = false;
	}
	
	if (SpawnTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(SpawnTimer[client]);
		SpawnTimer[client] = INVALID_HANDLE;
	}
	
	if (AutoReviveTimeout[client] != INVALID_HANDLE)
	{
		CloseHandle(AutoReviveTimeout[client]);
		AutoReviveTimeout[client] = INVALID_HANDLE;
	}

	if (AutoReviveTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(AutoReviveTimer[client]);
		AutoReviveTimer[client] = INVALID_HANDLE;
	}
	
	if (ReviveSuccessTimer[client] != INVALID_HANDLE)
	{	
		CloseHandle(ReviveSuccessTimer[client]);
		ReviveSuccessTimer[client] = INVALID_HANDLE;
	}
	
	isReviveTimeout[client] = false;
	StopBeat(client);
}