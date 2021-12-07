#pragma semicolon 1

#include <sourcemod>
#include <war>
#include <tf2_stocks>

#define PLUGIN_VERSION			"1.0.0.0"

#define SOUND_INV_ON				"player/invulnerable_on.wav"
#define SOUND_INV_OFF			"player/invulnerable_off.wav"
#define SOUND_CRIT_ON			"weapons/weapon_crit_charged_on.wav"
#define SOUND_CRIT_OFF			"weapons/weapon_crit_charged_off.wav"

public Plugin:myinfo =
{
	name = "War",
	author = "Wazz",
	description = "The War plugin!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:sm_war_enable = INVALID_HANDLE;
new bool:g_bEnabled;

new Handle:sm_war_buffchance = INVALID_HANDLE;
new Float:g_fBuffChance;

new Handle:sm_war_bufftime = INVALID_HANDLE;
new Float:g_fBuffTime;

new Handle:g_hClientTimer[MAXPLAYERS + 1];
new ClientBuff:g_iClientBuff[MAXPLAYERS + 1];

public OnPluginStart()
{	
	sm_war_enable = CreateConVar("sm_war_enable", "1", "Enable (1) or disable (0) the War plugin.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_war_buffchance = CreateConVar("sm_war_buffchance", "25.0", "Chance (%) that you will recieve a buff upon killing another player.", 0, true, 0.0, true, 100.0);
	sm_war_bufftime = CreateConVar("sm_war_bufftime", "15.0", "Time in seconds that a player has a buff for.", 0, true, 0.0, true, 100.0);
	
	CreateConVar("sm_war_version", PLUGIN_VERSION, "War plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookConVarChange(sm_war_enable, cvHook_enableChanged);
	g_bEnabled = GetConVarBool(sm_war_enable);
	
	HookConVarChange(sm_war_buffchance, cvHook_buffChanceChanged);
	g_fBuffChance = GetConVarFloat(sm_war_buffchance);
	
	HookConVarChange(sm_war_bufftime, cvHook_buffTimeChanged);
	g_fBuffTime = GetConVarFloat(sm_war_bufftime);
	
	HookEvent("player_death", OnPlayerKilled, EventHookMode_Post);
}

public OnMapStart()
{
	PrecacheSound(SOUND_INV_ON, true);
	PrecacheSound(SOUND_INV_OFF, true);
	PrecacheSound(SOUND_CRIT_ON, true);
	PrecacheSound(SOUND_CRIT_OFF, true);
}

public OnClientDisconnect(Client)
{
	if (g_hClientTimer[Client] != INVALID_HANDLE)
	{
		KillTimer(g_hClientTimer[Client]);
		g_hClientTimer[Client] = INVALID_HANDLE;
	}
	
	g_iClientBuff[Client] = BUFF_None;
}

public cvHook_enableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bEnabled = StringToInt(newValue)==0?false:true;
}

public cvHook_buffChanceChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fBuffChance = StringToFloat(newValue);
}

public cvHook_buffTimeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fBuffTime = StringToFloat(newValue);
}

public Action:CanPlayerChooseClass(Client, TFClassType:class)
{
	if (!g_bEnabled)
	{
		return Plugin_Continue;
	}
	
	switch (TFTeam:GetClientTeam(Client))
	{
		case TFTeam_Red:
		{
			if (class != TFClass_DemoMan)
			{
				TF2_SetPlayerClass(Client, TFClass_DemoMan, true, true);
				CreateTimer(0.1, HideVGUIPanel, Client, TIMER_FLAG_NO_MAPCHANGE);
				
				return Plugin_Handled;
			}
		}
		
		case TFTeam_Blue:
		{
			if (class != TFClass_Soldier)
			{
				TF2_SetPlayerClass(Client, TFClass_Soldier, true, true);
				CreateTimer(0.1, HideVGUIPanel, Client, TIMER_FLAG_NO_MAPCHANGE);
				
				return Plugin_Handled;
			}			
		}
	}
	
	return Plugin_Continue;
}

public Action:HideVGUIPanel(Handle:timer, any:Client)
{
	if (IsClientInGame(Client))
	{
		ShowVGUIPanel(Client, TFTeam:GetClientTeam(Client)==TFTeam_Red?"class_red":"class_blue", _, false);
	}
	
	return Plugin_Handled;
}

public OnPlayerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
	{
		return;
	}

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (attacker == victim || attacker == 0)
	{
		return;
	}
	
	if (g_hClientTimer[attacker] != INVALID_HANDLE)
	{
		return;
	}
	
	new random = GetRandomInt(0, 100);
	
	new Float:powerplayBound = (g_fBuffChance / 9);
	new Float:uberBound = (g_fBuffChance / 9 * 4) + powerplayBound;
	
	if (0.0 < random <= powerplayBound)
	{
		SetPowerplayEnabled(attacker, true);
	
		g_iClientBuff[attacker] = BUFF_PowerPlay;
		g_hClientTimer[attacker] = CreateTimer(g_fBuffTime, RemoveBuff, attacker, TIMER_FLAG_NO_MAPCHANGE);
		
		VoiceCommand(attacker, 2, 1);
	}
	else if (powerplayBound < random <= uberBound)
	{
		AddCondition(attacker, COND_Ubered);
		
		new Float:vec[3];
		GetClientEyePosition(attacker, vec);
		EmitAmbientSound(SOUND_INV_ON, vec, attacker, SNDLEVEL_NORMAL);	
	
		g_iClientBuff[attacker] = BUFF_Ubered;
		g_hClientTimer[attacker] = CreateTimer(g_fBuffTime, RemoveBuff, attacker, TIMER_FLAG_NO_MAPCHANGE);
		
		VoiceCommand(attacker, 2, 1);
	}
	else if (uberBound < random <= g_fBuffChance)
	{
		AddCondition(attacker, COND_Kritzed);
		
		new Float:vec[3];
		GetClientEyePosition(attacker, vec);
		EmitAmbientSound(SOUND_CRIT_ON, vec, attacker, SNDLEVEL_NORMAL);	
		
		g_iClientBuff[attacker] = BUFF_Kritzed;
		g_hClientTimer[attacker] = CreateTimer(g_fBuffTime, RemoveBuff, attacker, TIMER_FLAG_NO_MAPCHANGE);
		
		VoiceCommand(attacker, 2, 1);
	}
}

public Action:RemoveBuff(Handle:timer, any:Client)
{
	new Float:vec[3];
	GetClientEyePosition(Client, vec);
	
	switch (g_iClientBuff[Client])
	{
		case BUFF_PowerPlay:
		{
			SetPowerplayEnabled(Client, false);		
		}
		case BUFF_Ubered:
		{
			RemoveCondition(Client, COND_Ubered);
			
			EmitAmbientSound(SOUND_INV_OFF, vec, Client, SNDLEVEL_NORMAL);
		}
		case BUFF_Kritzed:
		{
			RemoveCondition(Client, COND_Kritzed);
			
			EmitAmbientSound(SOUND_CRIT_ON, vec, Client, SNDLEVEL_NONE, SND_STOP|SND_STOPLOOPING);
			EmitAmbientSound(SOUND_CRIT_OFF, vec, Client, SNDLEVEL_NORMAL);
		}
	}
	
	g_iClientBuff[Client] = BUFF_None;
	
	g_hClientTimer[Client] = INVALID_HANDLE;
	return Plugin_Handled;
}