#pragma semicolon 1
#include <sourcemod>
#include <colors>

new Handle:cvar_AssistEnable, Handle:cvar_AssistSI, Handle:cvar_AssistWitch;
new bool:g_bAssistEnable, g_iAssistSI, bool:g_bAssistWitch, zClassTank;
new DamageSI[33][33], DamageWitch[33][2048];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (strcmp(sGameName, "left4dead", false) == 0) zClassTank = 5;
	else if (strcmp(sGameName, "left4dead2", false) == 0) zClassTank = 8;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	cvar_AssistEnable = CreateConVar("sm_assist_enable", "1", "Enables this plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AssistSI = CreateConVar("sm_assist_si", "0", "Show SI damage (0: only tank, 1: all infected except tank, 2: all infected)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_AssistWitch = CreateConVar("sm_assist_witch", "1", "Show witch damage & cr0wn", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(cvar_AssistSI, ConVarChanged_Cvars);
	HookConVarChange(cvar_AssistWitch, ConVarChanged_Cvars);
	HookConVarChange(cvar_AssistEnable, ConVarChanged_Cvars);
	g_bAssistEnable = GetConVarBool(cvar_AssistEnable);
	g_iAssistSI = GetConVarInt(cvar_AssistSI);
	g_bAssistWitch = GetConVarBool(cvar_AssistWitch);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("witch_killed", Event_WitchKilled);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundEnd);
	HookEvent("witch_harasser_set", Event_WitchHarasserSet);
	
	AutoExecConfig(true, "l4d_assist");
	
	LoadTranslations("l4d_assist.phrases");
}

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bAssistEnable = GetConVarBool(cvar_AssistEnable);
	g_iAssistSI = GetConVarInt(cvar_AssistSI);
	g_bAssistWitch = GetConVarBool(cvar_AssistWitch);
}

public Event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (g_bAssistEnable)
	{  
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client > 0 && GetClientTeam(client) == 3) ClearDmg(client);
	}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bAssistEnable)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (attacker > 0 && victim > 0 && victim != attacker)
		{
			new iAttackerTeam = GetClientTeam(attacker);
			new iVictimTeam = GetClientTeam(victim);
			if (iAttackerTeam == 2 && iVictimTeam == 3 && iAttackerTeam != iVictimTeam)
			{
				new class = GetEntProp(victim, Prop_Send, "m_zombieClass");
				switch(g_iAssistSI)
				{
					case 0:
					{
						if (class != zClassTank) return Plugin_Handled;
					}
					case 1:
					{
						if (class == zClassTank) return Plugin_Handled;
					}
				}
				
				new DamageHealth = GetEventInt(event, "dmg_health");
				if (DamageHealth < 1024) DamageSI[attacker][victim] += DamageHealth;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bAssistEnable)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (victim > 0 && GetClientTeam(victim) == 3)
		{
			new class = GetEntProp(victim, Prop_Send, "m_zombieClass");
			switch(g_iAssistSI)
			{
				case 0:
				{
					if (class != zClassTank)
					{
						ClearDmg(victim);
						return Plugin_Handled;
					}
				}
				case 1:
				{
					if (class == zClassTank)
					{
						ClearDmg(victim);
						return Plugin_Handled;
					}
				}
			}
			
			new survivors, players[33][2];
			for (new i = 1; i <= 32; i++)
			{
				if (DamageSI[i][victim] <= 0 || !IsClientInGame(i) || GetClientTeam(i) != 2) continue;
				players[survivors][0] = i;
				players[survivors][1] = DamageSI[i][victim];
				survivors++;
			}
			
			if (survivors == 0) return Plugin_Handled;
			SortCustom2D(players, survivors, SortByDamage);
			new String:sMessage[256] = "";
			
			for (new i; i < survivors; i++)
			{
				new attacker = players[i][0];
				decl String:sTempMessage[64];
				Format(sTempMessage, sizeof(sTempMessage), "%t", "ASSIST_STRING", (i > 0 ? ", " : ""), attacker, DamageSI[attacker][victim]);
				StrCat(sMessage, sizeof(sMessage), sTempMessage);
				DamageSI[attacker][victim] = 0;
			}
			
			CPrintToChatAll("%t", "TANK_KILLED", victim, sMessage);
		}
		else ClearDmg(victim);
	}
	return Plugin_Continue;
}

public SortByDamage(x[], y[], const array[][], Handle:hndl)
{
	if (x[1] > y[1]) return -1;
	else if (x[1] == y[1]) return 0;
	return 1;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ClearDmgAll();
}

ClearDmg(victim)
{
	if (g_bAssistEnable)
	{
		for (new i = 1; i <= 32; i++)
		{
			if (victim >= 33) return;
			DamageSI[i][victim] = 0;
		}
	}
}

ClearDmgAll()
{
	if (g_bAssistEnable)
	{
		for (new i = 1; i <= 32; i++)
		{
			decl x;
			for (x = 1; x <= 32; x++)
			{
				DamageSI[i][x] = 0;
			}
			for (x = 33; x < 2048; x++)
			{
				DamageWitch[i][x] = 0;
			}
		}
	}
}

public Action:Event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		new witch = GetEventInt(event, "witchid");
		if (witch > 32) ClearDmg(witch);
	}
}

public Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		new witch = GetEventInt(event, "entityid");
		decl String:class[64];
		GetEdictClassname(witch, class, sizeof(class));
		if (!StrEqual(class, "witch", false)) return;
		
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (attacker > 0 && GetClientTeam(attacker) == 2)
		{
			new damage = GetEventInt(event, "amount");
			DamageWitch[attacker][witch] += damage;
		}
	}
}
public Event_WitchHarasserSet(Handle: event, const String: name[], bool: dontBroadcast)
{
new target = GetClientOfUserId(GetEventInt(event, "userid"));
if (IsValidClient(target) && GetClientTeam(target) == 2) CPrintToChatAll("%t", "WITCH_TARGET", target);
}
 
stock bool:IsValidClient(client)
{
if (client < 1) return false;
if (client > 32) return false;
if (!IsClientInGame(client)) return false;
return true;
}
 

public Action:Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		new witch = GetEventInt(event, "witchid");
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		if (attacker > 0 && GetClientTeam(attacker) == 2)
		{
			if (GetEventBool(event, "oneshot"))
			{
				CPrintToChatAll("%t", "WITCH_CROWNED", attacker);
				ClearDmg(witch);
			}
			else
			{
				new survivors, players[33][2];
				for (new i = 1; i <= 32; i++)
				{
					if (DamageWitch[i][witch] <= 0 || !IsClientInGame(i) || GetClientTeam(i) != 2) continue;
					players[survivors][0] = i;
					players[survivors][1] = DamageWitch[i][witch];
					survivors++;
				}
				
				if (survivors == 0) return Plugin_Handled;
				SortCustom2D(players, survivors, SortByDamage);
				new String:sMessage[256] = "";
				
				for (new i; i < survivors; i++)
				{
					new client = players[i][0];
					decl String:sTempMessage[64];
					Format(sTempMessage, sizeof(sTempMessage), "%t", "ASSIST_STRING", (i > 0 ? ", " : ""), client, DamageWitch[client][witch]);
					StrCat(sMessage, sizeof(sMessage), sTempMessage);
					DamageWitch[client][witch] = 0;
				}
				
				CPrintToChatAll("%t", "WITCH_KILLED", sMessage);
			}
		}
		else ClearDmg(witch);
	}
	return Plugin_Continue;
}

public OnEntityDestroyed(entity) //escaped or burned
{
	if (g_bAssistEnable && g_bAssistWitch)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			new String:class[64];
			GetEdictClassname(entity, class, sizeof(class));
			if (StrEqual(class, "witch")) ClearDmg(entity);
		}
	}
}