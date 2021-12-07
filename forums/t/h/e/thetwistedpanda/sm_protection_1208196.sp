#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#pragma semicolon 1

#define PLUGIN_VERSION "3.6.2"
#define PLUGIN_PREFIX "\x04Protection: \x03"
#define CONSOLE_PREFIX "Protection: "

new g_iTeam[MAXPLAYERS + 1];
new bool:g_bAlive[MAXPLAYERS + 1];
new bool:g_bProtected[MAXPLAYERS + 1];
new Handle:g_hTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

new g_iFalling, g_iEnding, g_iNotify, g_iColors[2][2][6], g_iPunish, g_iValue;
new bool:g_bEnabled, bool:g_bDecay, bool:g_bShooting, bool:g_bPreColor, bool:g_bPostColor, bool:g_bEnding, bool:g_bLateLoad, bool:g_bDelayed, bool:g_bEnabledT, bool:g_bEnabledCT;
new Float:g_fTime, Float:g_fCounter, Float:g_fDuration, Float:g_fFrequency, Float:g_fStrength, Float:g_fFreeze, Float:g_fMaximum;

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hTime = INVALID_HANDLE;
new Handle:g_hEnabledT = INVALID_HANDLE;
new Handle:g_hEnabledCT = INVALID_HANDLE;
new Handle:g_hDecay = INVALID_HANDLE;
new Handle:g_hMaximum = INVALID_HANDLE;
new Handle:g_hFalling = INVALID_HANDLE;
new Handle:g_hEnding = INVALID_HANDLE;
new Handle:g_hShooting = INVALID_HANDLE;
new Handle:g_hPreColor = INVALID_HANDLE;
new Handle:g_hPreTColor = INVALID_HANDLE;
new Handle:g_hPreCTColor = INVALID_HANDLE;
new Handle:g_hPostColor = INVALID_HANDLE;
new Handle:g_hPostTColor = INVALID_HANDLE;
new Handle:g_hPostCTColor = INVALID_HANDLE;
new Handle:g_hNotify = INVALID_HANDLE;
new Handle:g_hPunish = INVALID_HANDLE;
new Handle:g_hValue = INVALID_HANDLE;
new Handle:g_hDelayed = INVALID_HANDLE;
new Handle:g_hFreeze = INVALID_HANDLE;
new Handle:g_hTimerFreeze = INVALID_HANDLE;
new Handle:g_hTimerDecay = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Player Protection",
	author = "Twisted|Panda",
	description = "A spawn protection plugin that provides just about every feature desired.",
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
	CreateConVar("sm_protection_version", PLUGIN_VERSION, "Player Protection Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hEnabled = CreateConVar("sm_protection_enable", "1", "If enabled, players will spawn with \"protection\" protecting them for sm_protection_duration seconds.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hEnabledT = CreateConVar("sm_protection_enable_t", "1", "If enabled, players on the Terrorist team will receive protection.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hEnabledCT = CreateConVar("sm_protection_enable_ct", "1", "If enabled, players on the Counter-Terrorist team will receive protection.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hTime = CreateConVar("sm_protection_duration", "7", "The number of seconds players will receive protection for upon spawning. (-1.0 = Team Duration, 0 = Disabled, # = Seconds)", FCVAR_NONE, true, -1.0);
	g_hDecay = CreateConVar("sm_protection_decay", "1", "If enabled, the total duration of protection will decrease until reaching zero, disabling protection for the round.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hMaximum = CreateConVar("sm_protection_maximum", "30.0", "The total number of seconds sm_protection_decay will operate for before disabling protection.", FCVAR_NONE, true, 0.0);
	g_hFalling = CreateConVar("sm_protection_falling", "1", "Determines how players are protected from falling damage. (-2 = All Fall Damage, -1 = All Fall Damage (w/ Protect), 0 = No Protection, 1 = Non-Fatal Fall Damage (w/ Protect), 2 = Non-Fatal Fall Damage)", FCVAR_NONE, true, -2.0, true, 2.0);
	g_hEnding = CreateConVar("sm_protection_ending", "-1", "Determines how players are protected after the round ends. (-1 = Protection From Everything, 0 = No Protection, 1 = Protection From Players)", FCVAR_NONE, true, -1.0, true, 1.0);
	g_hShooting = CreateConVar("sm_protection_shooting", "1", "If enabled, protection will be disabled early should the player fire their weapon.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hPreColor = CreateConVar("sm_protection_pre", "1", "If enabled, players will receive the defined settings while under protection.");
	g_hPreTColor = CreateConVar("sm_protection_pre_t", "4 0 180 0 0 255", "Combination for Terrorists under protection: Fx Render Red Green Blue Alpha");
	g_hPreCTColor = CreateConVar("sm_protection_pre_ct", "4 0 0 0 180 255", "Combination for Counter-Terrorists under protection: Fx Render Red Green Blue Alpha");
	g_hPostColor = CreateConVar("sm_protection_post", "1", "If enabled, players will receive the defined settings after spawn protection expires.");
	g_hPostTColor = CreateConVar("sm_protection_post_t", "0 0 255 255 255 255", "Combination for Terrorists after protection: Fx Render Red Green Blue Alpha");
	g_hPostCTColor = CreateConVar("sm_protection_post_ct", "0 0 255 255 255 255", "Combination for Counter-Terrorists after protection: Fx Render Red Green Blue Alpha");
	g_hNotify = CreateConVar("sm_protection_notify", "-1", "Determines printing functionality. (-1 = Hint Message, 0 = No Message, 1 = Chat Message)", FCVAR_NONE, true, -1.0, true, 1.0);
	g_hPunish = CreateConVar("sm_protection_punish", "1", "Determines punishment functionality. (-1 = Slay Player, 0 = No Action, 1 = Lose Health)", FCVAR_NONE, true, -1.0, true, 1.0);
	g_hValue = CreateConVar("sm_protection_punish_value", "25", "The amount of health lost, if sm_protection_punish is equal to 1.", FCVAR_NONE, true, 0.0);
	g_hDelayed = CreateConVar("sm_protection_freeze_time", "1", "If enabled, spawn protection and decay are put off until mp_freezetime expires.", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sm_protection");

	HookConVarChange(g_hEnabled, OnSettingsChange);
	HookConVarChange(g_hTime, OnSettingsChange);
	HookConVarChange(g_hEnabledT, OnSettingsChange);
	HookConVarChange(g_hEnabledCT, OnSettingsChange);
	HookConVarChange(g_hDecay, OnSettingsChange);
	HookConVarChange(g_hMaximum, OnSettingsChange);
	HookConVarChange(g_hFalling, OnSettingsChange);
	HookConVarChange(g_hEnding, OnSettingsChange);
	HookConVarChange(g_hShooting, OnSettingsChange);
	HookConVarChange(g_hPreColor, OnSettingsChange);
	HookConVarChange(g_hPreTColor, OnSettingsChange);
	HookConVarChange(g_hPreCTColor, OnSettingsChange);
	HookConVarChange(g_hPostColor, OnSettingsChange);
	HookConVarChange(g_hPostTColor, OnSettingsChange);
	HookConVarChange(g_hPostCTColor, OnSettingsChange);
	HookConVarChange(g_hNotify, OnSettingsChange);
	HookConVarChange(g_hPunish, OnSettingsChange);
	HookConVarChange(g_hValue, OnSettingsChange);
	HookConVarChange(g_hDelayed, OnSettingsChange);

	g_hFreeze = FindConVar("mp_freezetime");
	HookConVarChange(g_hFreeze, OnSettingsChange);

	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("weapon_fire", Event_OnWeaponFire);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_freeze_end", Event_OnFreezeEnd, EventHookMode_PostNoCopy);
}

public OnPluginEnd()
{
	for(new i = 1; i <= MaxClients; i++)
		if(g_bProtected[i])
			Void_DisableProtection(i);
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		Void_ResetProtection();

		if(g_bLateLoad)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				g_bProtected[i] = false;

				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i) ? true : false;
					
					SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
				}
			}
			
			g_bLateLoad = false;
		}
	}
}

public OnMapEnd()
{
	if(g_hTimerDecay != INVALID_HANDLE && CloseHandle(g_hTimerDecay))
		g_hTimerDecay = INVALID_HANDLE;
			
	if(g_hTimerFreeze != INVALID_HANDLE && CloseHandle(g_hTimerFreeze))
		g_hTimerFreeze = INVALID_HANDLE;
		
	for(new i = 1; i <= MaxClients; i++)
		if(g_hTimer[i] != INVALID_HANDLE && CloseHandle(g_hTimer[i]))
			g_hTimer[i] = INVALID_HANDLE;
}

public OnMapStart()
{
	Void_SetDefaults();
}

public OnClientPutInServer(client)
{
	if(g_bEnabled)
	{
		SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iTeam[client] = 0;
		g_bAlive[client] = false;
		g_bProtected[client] = false;

		if(g_hTimer[client] != INVALID_HANDLE && CloseHandle(g_hTimer[client]))
			g_hTimer[client] = INVALID_HANDLE;
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = false;

		if(g_bDecay && (!g_bDelayed || g_bDelayed && !g_fFreeze))
			g_hTimerDecay = CreateTimer(g_fFrequency, Timer_DecayTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action:Event_OnFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		if(g_bDelayed && g_fFreeze)
		{
			g_fFreeze = 0.0;
			if(g_bDecay)
				g_hTimerDecay = CreateTimer(g_fFrequency, Timer_DecayTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(g_fTime)
						Void_EnableProtection(i);
					else
						Void_DisableProtection(i);
				}
			}
		}
	}
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bEnding = true;
		Void_ResetProtection();

		if(g_bDecay && g_hTimerDecay != INVALID_HANDLE && CloseHandle(g_hTimerDecay))
			g_hTimerDecay = INVALID_HANDLE;
		if(g_bDelayed && g_hTimerFreeze != INVALID_HANDLE && CloseHandle(g_hTimerFreeze))
			g_hTimerFreeze = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action:Event_OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled && g_bShooting)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
			
		if(g_bProtected[client])
		{
			if(g_hTimer[client] != INVALID_HANDLE)
				CloseHandle(g_hTimer[client]);

			Void_DisableProtection(client);
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;
			
		g_iTeam[client] = GetEventInt(event, "team");
		if(g_hTimer[client] != INVALID_HANDLE && CloseHandle(g_hTimer[client]))
			g_hTimer[client] = INVALID_HANDLE;

		if(g_iTeam[client] == CS_TEAM_SPECTATOR)
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
		if(g_bDelayed && g_fFreeze)
			return Plugin_Continue;

		if(g_fDuration && ((g_bEnabledT && g_iTeam[client] == CS_TEAM_T) || (g_bEnabledCT && g_iTeam[client] == CS_TEAM_CT)))
		{
			if(!g_bDecay || g_fStrength && g_fDuration >= g_fStrength)
				CreateTimer(0.1, Timer_EnableProtection, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);			
		}
		else
			g_hTimer[client] = CreateTimer(0.1, Timer_DisableProtection, client, TIMER_FLAG_NO_MAPCHANGE);
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
		if(g_hTimer[client] != INVALID_HANDLE && CloseHandle(g_hTimer[client]))
			g_hTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

public Action:Timer_EnableProtection(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
		Void_EnableProtection(client);
}

public Action:Timer_DisableProtection(Handle:timer, any:client)
{
	if(IsClientInGame(client))
		Void_DisableProtection(client);
	else
		g_hTimer[client] = INVALID_HANDLE;
}

public Action:Timer_DecayTimer(Handle:timer)
{
	if(g_fCounter < g_fMaximum)
	{
		g_fCounter += g_fFrequency;
		g_fDuration -= g_fStrength;
		return Plugin_Continue;
	}

	g_hTimerDecay = INVALID_HANDLE;
	return Plugin_Stop;
}

Void_EnableProtection(client)
{
	if(g_iTeam[client] >= 2 && g_bAlive[client])
	{
		g_bProtected[client] = true;
		if(g_bPreColor)
			Void_DoEntityRender(client, g_iColors[g_iTeam[client] - 2][0]);

		switch(g_iNotify)
		{
			case -1:
				PrintHintText(client, "%sYou have %.1f seconds of Spawn Protection!", CONSOLE_PREFIX, g_fDuration);
			case 1:
				PrintToChat(client, "%sYou have %.1f seconds of Spawn Protection!", PLUGIN_PREFIX, g_fDuration);
		}

		g_hTimer[client] = CreateTimer(g_fDuration, Timer_DisableProtection, client);
	}
}

Void_DisableProtection(client)
{
	g_bProtected[client] = false;
	g_hTimer[client] = INVALID_HANDLE;

	if(g_iTeam[client] >= 2 && g_bAlive[client])
	{
		if(g_bPostColor)
			Void_DoEntityRender(client, g_iColors[g_iTeam[client] - 2][1]);
	
		if(g_fTime)
		{
			switch(g_iNotify)
			{
					case -1:
					PrintHintText(client, "%sYour Spawn Protection has expired!", CONSOLE_PREFIX);
				case 1:
					PrintToChat(client, "%sYour Spawn Protection has expired!", PLUGIN_PREFIX);
			}
		}
	}
}

Void_ResetProtection()
{
	g_fCounter = 0.0;
	g_fDuration = g_fTime;
	g_fStrength = (g_fDuration / 10);
	g_fFrequency = (g_fMaximum / 10);
	g_fFreeze = GetConVarFloat(g_hFreeze);
}

Void_DoEntityRender(index, array[])
{
	if(array[0] != -1)
		SetEntityRenderFx(index, RenderFx:array[0]);

	if(array[1] != -1)
		SetEntityRenderMode(index, RenderMode:array[1]);

	if(array[2] != -1 && array[3] != -1  && array[4] != -1 && array[5] != -1)
		SetEntityRenderColor(index, array[2], array[3], array[4], array[5]);
}

public Action:Hook_OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!g_bEnabled)
		return Plugin_Continue;

	if(0 < client <= MaxClients)
	{
		if(g_bEnding)
		{
			switch(g_iEnding)
			{
				case -1:
				{
					damage = 0.0;
					return Plugin_Changed;
				}
				case 1:
				{
					if(0 < attacker <= MaxClients)
					{
						damage = 0.0;
						return Plugin_Changed;
					}
				}
			}
		}
		else
		{
			switch(g_iFalling)
			{
				case -2:
				{
					if(!attacker && damagetype == 32)
					{
						damage = 0.0;
						return Plugin_Changed;
					}
				}
				case -1:
				{
					if(!g_bProtected[client])
						return Plugin_Continue;

					if(!attacker && damagetype == 32)
					{
						damage = 0.0;
						return Plugin_Changed;
					}
				}
				case 1:
				{
					if(!g_bProtected[client])
						return Plugin_Continue;

					if(!attacker && damagetype == 32 && damage <= GetEntProp(client, Prop_Data, "m_iHealth"))
					{
						damage = 0.0;
						return Plugin_Changed;
					}
				}
				case 2:
				{
					if(!attacker && damagetype == 32 && damage <= GetEntProp(client, Prop_Data, "m_iHealth"))
					{
						damage = 0.0;
						return Plugin_Changed;
					}
				}
			}
			
			if(g_bProtected[client])
			{
				if(0 < attacker <= MaxClients)
				{
					switch(g_iPunish)
					{
						case -1:
						{
							if(IsClientInGame(attacker) && g_bAlive[attacker] && g_iTeam[client] != g_iTeam[attacker])
							{
								ForcePlayerSuicide(attacker);
								switch(g_iNotify)
								{
									case -1:
										PrintHintText(attacker, "%sYou were slain for attacking %N while he/she had protection!", CONSOLE_PREFIX, client);
									case 1:
										PrintToChat(attacker, "%sYou were slain for attacking %N while he/she had protection!", PLUGIN_PREFIX, client);
								}
							}
						}
						case 1:
						{
							if(g_iValue && IsClientInGame(attacker) && g_bAlive[attacker] && g_iTeam[client] != g_iTeam[attacker])
							{
								new g_iHealth = GetClientHealth(attacker);
								g_iHealth -= g_iValue;
								if(g_iHealth > 0)
								{
									SetEntityHealth(attacker, g_iHealth);
									switch(g_iNotify)
									{
										case -1:
											PrintHintText(attacker, "%sYou lost %d health for attacking %N while he/she had protection!", CONSOLE_PREFIX, g_iValue, client);
										case 1:
											PrintToChat(attacker, "%sYou lost %d health for attacking %N while he/she had protection!", PLUGIN_PREFIX, g_iValue, client);
									}
								}
								else
								{
									ForcePlayerSuicide(attacker);
									switch(g_iNotify)
									{
										case -1:
											PrintHintText(attacker, "%sYou were slain for attacking %N while he/she had protection!", CONSOLE_PREFIX, client);
										case 1:
											PrintToChat(attacker, "%sYou were slain for attacking %N while he/she had protection!", PLUGIN_PREFIX, client);
									}
								}
							}
						}
					}

					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}

	return Plugin_Continue;
}

Void_SetDefaults()
{
	decl String:_sTemp[64], String:_sEffects[6][4];

	g_bEnabled = GetConVarInt(g_hEnabled) ? true : false;
	g_bDecay = GetConVarInt(g_hDecay) ? true : false;
	g_fMaximum = GetConVarFloat(g_hMaximum);
	g_iFalling = GetConVarInt(g_hFalling);
	g_iEnding = GetConVarInt(g_hEnding);
	g_bShooting = GetConVarInt(g_hShooting) ? true : false;
	g_bPreColor = GetConVarInt(g_hPreColor) ? true : false;
	g_fTime = GetConVarFloat(g_hTime);
	if(g_bPreColor)
	{
		for(new i = 0; i <= 1; i++)
		{
			switch(i)
			{
				case 0:
					GetConVarString(g_hPreTColor, _sTemp, sizeof(_sTemp));
				case 1:
					GetConVarString(g_hPreCTColor, _sTemp, sizeof(_sTemp));
			}
			ExplodeString(_sTemp, " ", _sEffects, 6, 4);
		
			for(new j = 0; j <= 5; j++)
				g_iColors[i][0][j] = StringToInt(_sEffects[j]);
		}
	}
	g_bPostColor = GetConVarInt(g_hPostColor) ? true : false;
	if(g_bPostColor)
	{
		for(new i = 0; i <= 1; i++)
		{
			switch(i)
			{
				case 0:
					GetConVarString(g_hPostTColor, _sTemp, sizeof(_sTemp));
				case 1:
					GetConVarString(g_hPostCTColor, _sTemp, sizeof(_sTemp));
			}
			ExplodeString(_sTemp, " ", _sEffects, 6, 4);
		
			for(new j = 0; j <= 5; j++)
				g_iColors[i][1][j] = StringToInt(_sEffects[j]);
		}
	}
	g_iNotify = GetConVarInt(g_hNotify);
	g_iPunish = GetConVarInt(g_hPunish);
	g_iValue = GetConVarInt(g_hValue);
	g_bDelayed = GetConVarInt(g_hDelayed) ? true : false;
	g_bEnabledT = GetConVarInt(g_hEnabledT) ? true : false;
	g_bEnabledCT = GetConVarInt(g_hEnabledCT) ? true : false;

	Void_ResetProtection();
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
	{
		g_bEnabled = StringToInt(newvalue) ? true : false;
		if(g_bEnabled && !StringToInt(oldvalue))
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				g_bProtected[i] = false;

				if(IsClientInGame(i))
				{
					g_iTeam[i] = GetClientTeam(i);
					g_bAlive[i] = IsPlayerAlive(i) ? true : false;
					
					SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
				}
			}
		}
	}
	else if(cvar == g_hTime)
		g_fTime = StringToFloat(newvalue);
	else if(cvar == g_hEnabledT)
		g_bEnabledT = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hEnabledCT)
		g_bEnabledCT = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hDecay)
	{
		if(g_hTimerDecay != INVALID_HANDLE && CloseHandle(g_hTimerDecay))
			g_hTimerDecay = INVALID_HANDLE;

		g_bDecay = StringToInt(newvalue) ? true : false;
		if(g_bDecay)
		{
			Void_ResetProtection();
			g_hTimerDecay = CreateTimer(g_fFrequency, Timer_DecayTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if(cvar == g_hMaximum)
		g_fMaximum = StringToFloat(newvalue);
	else if(cvar == g_hFalling)
		g_iFalling = StringToInt(newvalue);
	else if(cvar == g_hEnding)
		g_iEnding = StringToInt(newvalue);
	else if(cvar == g_hShooting)
		g_bShooting = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hPreColor)
		g_bPreColor = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hPostColor)
		g_bPostColor = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hPreTColor)
	{
		decl String:_sEffects1[6][4];
		ExplodeString(newvalue, " ", _sEffects1, 6, 4);
		for(new j = 0; j <= 5; j++)
			g_iColors[0][0][j] = StringToInt(_sEffects1[j]);
	}
	else if(cvar == g_hPreCTColor)
	{
		decl String:_sEffects2[6][4];
		ExplodeString(newvalue, " ", _sEffects2, 6, 4);
		for(new j = 0; j <= 5; j++)
			g_iColors[1][0][j] = StringToInt(_sEffects2[j]);
	}
	else if(cvar == g_hPostTColor)
	{
		decl String:_sEffects3[6][4];
		ExplodeString(newvalue, " ", _sEffects3, 6, 4);
		for(new j = 0; j <= 5; j++)
			g_iColors[0][1][j] = StringToInt(_sEffects3[j]);
	}
	else if(cvar == g_hPostCTColor)
	{
		decl String:_sEffects4[6][4];
		ExplodeString(newvalue, " ", _sEffects4, 6, 4);
		for(new j = 0; j <= 5; j++)
			g_iColors[1][1][j] = StringToInt(_sEffects4[j]);
	}
	else if(cvar == g_hNotify)
		g_iNotify = StringToInt(newvalue);
	else if(cvar == g_hPunish)
		g_iPunish = StringToInt(newvalue);
	else if(cvar == g_hValue)
		g_iValue = StringToInt(newvalue);
	else if(cvar == g_hFreeze)
		g_fFreeze = StringToFloat(newvalue);
	else if(cvar == g_hDelayed)
		g_bDelayed = StringToInt(newvalue) ? true : false;
}