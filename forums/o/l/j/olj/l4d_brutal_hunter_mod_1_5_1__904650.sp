#define PLUGIN_VERSION "1.5.1"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
new Float:initialPosition[32][3];
new Handle:FatalPounceDistance = INVALID_HANDLE;
new Handle:BonusDmgTimer[MAXPLAYERS+1];
new Handle:h_ApplyToIncapped;
new Handle:h_BonusDmgHard;
new Handle:h_BonusDmgTemp;
new BonusDmgHard;
new Float:BonusDmgTemp;
new Dmg[MAXPLAYERS+1];

new bool:ApplyToIncapped;
new bool:Pounced[MAXPLAYERS+1];
new propinfoburn;

public Plugin:myinfo = 
{
	name = "Brutal Hunter Mod",
	author = "Olj",
	description = "...",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("lunge_pounce", Pounce, EventHookMode_Pre);
	HookEvent("pounce_stopped", PounceStop);
	HookEvent("ability_use",AbilityUse);
	FatalPounceDistance = CreateConVar("l4d_hunter_fatal_distance", "1000", "Survivors will never get up after being pounced from this distance.", CVAR_FLAGS);
	h_ApplyToIncapped = CreateConVar("l4d_hunter_bonusdmg_applytoincapped", "0", "Should we apply bonus damage to incapped survivors?", CVAR_FLAGS);
	h_BonusDmgHard = CreateConVar("l4d_hunter_bonusdmg_hardhp", "1", "Bonus damage to hardhp and incapped hp.", CVAR_FLAGS);
	h_BonusDmgTemp = CreateConVar("l4d_hunter_bonusdmg_temphp", "1.0", "Bonus damage to temp. hp.", CVAR_FLAGS);
	BonusDmgHard = GetConVarInt(h_BonusDmgHard);
	BonusDmgTemp = GetConVarFloat(h_BonusDmgTemp);
	ApplyToIncapped = GetConVarBool(h_ApplyToIncapped);
	HookConVarChange(h_ApplyToIncapped, ApplyToIncappedChanged);
	HookConVarChange(h_BonusDmgHard, DmgHardChanged);
	HookConVarChange(h_BonusDmgTemp, DmgTempChanged);
	AutoExecConfig(true, "l4d_brutal_hunter_mod");
	CreateConVar("l4d_bh_mod_version", PLUGIN_VERSION, "Version of Brutal Hunter Mod plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	propinfoburn = FindSendPropInfo("CTerrorPlayer", "m_burnPercent");
}

public ApplyToIncappedChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		ApplyToIncapped = GetConVarBool(h_ApplyToIncapped);
	}

public DmgHardChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		BonusDmgHard = GetConVarInt(h_BonusDmgHard);
	}
	
public DmgTempChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		BonusDmgTemp = GetConVarFloat(h_BonusDmgTemp);
	}
	
public AbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientAbsOrigin(user,initialPosition[user]);
}


public Action:Pounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("\x05Pounce Event");
	new Float:pouncePosition[3];
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientAbsOrigin(attacker,pouncePosition);
	new distance = RoundToNearest(GetVectorDistance(initialPosition[attacker], pouncePosition));
	//PrintToChatAll("%i", distance);
	if (distance>=GetConVarInt(FatalPounceDistance))
		{
			new victim = GetClientOfUserId(GetEventInt(event, "victim"));
			decl String:attacker_name[MAX_NAME_LENGTH];
			decl String:victim_name[MAX_NAME_LENGTH];
			GetClientName(attacker, attacker_name, MAX_NAME_LENGTH);
			GetClientName(victim, victim_name, MAX_NAME_LENGTH);
			PrintToChatAll("\03%s \x01was brutally pounced by \x03%s \x01from deadly distance and got his spine broken.", victim_name, attacker_name);
			ForcePlayerSuicide(victim);
			return Plugin_Continue;
		}
	if (IsPlayerBurning(attacker))
		{
			new Handle:pack;
			new victim = GetClientOfUserId(GetEventInt(event, "victim"));
			Pounced[victim] = true;
			Dmg[attacker]=0;
			BonusDmgTimer[victim] = CreateDataTimer(0.7, BonusDmgTimerFunction, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			WritePackCell(pack, attacker);
			WritePackCell(pack, victim);
			return Plugin_Continue;
		}
	return Plugin_Continue;
}

public Action:BonusDmgTimerFunction(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new attacker = ReadPackCell(pack);
	new victim = ReadPackCell(pack);
	
	new Float:tempHP = GetEntPropFloat(victim, Prop_Send, "m_healthBuffer");
	
	if (!IsValidClient(victim)||!IsValidClient(attacker))
		{
			if (BonusDmgTimer[victim] != INVALID_HANDLE)
				{
					KillTimer(BonusDmgTimer[victim]);	
					BonusDmgTimer[victim] = INVALID_HANDLE;
					decl String:attackername[MAX_NAME_LENGTH];
					decl String:victimname[MAX_NAME_LENGTH];
					GetClientName(attacker, attackername, MAX_NAME_LENGTH);
					GetClientName(victim, victimname, MAX_NAME_LENGTH);
					//PrintToChatAll("\x04Killed Timer : NOT VALID CLIENT");
					PrintToChatAll("\x03%s\x01 has done \x04%i\x01 bonus damage to \x03%s.", attackername, Dmg[attacker], victimname);
					return Plugin_Handled;
				}
		}
	if ((Pounced[victim]==false)&&(BonusDmgTimer[victim] != INVALID_HANDLE))
		{
			KillTimer(BonusDmgTimer[victim]);	
			BonusDmgTimer[victim] = INVALID_HANDLE;
			decl String:attackername[MAX_NAME_LENGTH];
			decl String:victimname[MAX_NAME_LENGTH];
			GetClientName(attacker, attackername, MAX_NAME_LENGTH);
			GetClientName(victim, victimname, MAX_NAME_LENGTH);
			//PrintToChatAll("\x04Killed Timer: Pounce stopped by someone");
			PrintToChatAll("\x03%s\x01 has done \x04%i\x01 bonus damage to \x03%s.", attackername, Dmg[attacker], victimname);
			return Plugin_Handled;
		}
	if ((IsIncapped(victim))&&(!ApplyToIncapped)&&(BonusDmgTimer[victim] != INVALID_HANDLE))
		{
			KillTimer(BonusDmgTimer[victim]);	
			BonusDmgTimer[victim] = INVALID_HANDLE;
			decl String:attackername[MAX_NAME_LENGTH];
			decl String:victimname[MAX_NAME_LENGTH];
			GetClientName(attacker, attackername, MAX_NAME_LENGTH);
			GetClientName(victim, victimname, MAX_NAME_LENGTH);
			//PrintToChatAll("\x04Killed Timer: Not apply to incapped");
			PrintToChatAll("\x03%s\x01 has done \x04%i\x01 bonus damage to \x03%s.", attackername, Dmg[attacker], victimname);
			return Plugin_Handled;
		}
	
	if ((!IsPlayerBurning(attacker))&&(BonusDmgTimer[victim] != INVALID_HANDLE))
		{
			KillTimer(BonusDmgTimer[victim]);	
			BonusDmgTimer[victim] = INVALID_HANDLE;
			decl String:attackername[MAX_NAME_LENGTH];
			decl String:victimname[MAX_NAME_LENGTH];
			GetClientName(attacker, attackername, MAX_NAME_LENGTH);
			GetClientName(victim, victimname, MAX_NAME_LENGTH);
			//PrintToChatAll("\x04Killed Timer: Not burning anymore");
			PrintToChatAll("\x03%s\x01 has done \x04%i\x01 bonus damage to \x03%s.", attackername, Dmg[attacker], victimname);
			return Plugin_Handled;	
		}
		
	
	new HP = GetEntProp(victim, Prop_Data, "m_iHealth");
	if (HP>BonusDmgHard) SetEntProp(victim, Prop_Send, "m_iHealth", (HP-BonusDmgHard));
	//PrintToChatAll("tempHP %i", tempHP);
	//PrintToChatAll("HP %i", HP);
	if ((HP<=1) && (tempHP>1))
		{
			//new Float:damagefloat = 1.0;
			if (BonusDmgTemp<tempHP)
				{
					SetEntPropFloat(victim, Prop_Send, "m_healthBuffer", (tempHP - BonusDmgTemp));
					//PrintToChatAll("tempHP %f, new temp HP %f", tempHP, tempHP - damagefloat);
				}
		}
	Dmg[attacker] += 1;
	return Plugin_Continue;
}

public PounceStop(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	//PrintToChatAll("\x05Pounce Stop Event");
	Pounced[victim] = false;
	//if (BonusDmgTimer[victim]==INVALID_HANDLE) return;
	//if (BonusDmgTimer[victim] != INVALID_HANDLE) KillTimer(BonusDmgTimer[victim]);	
}

bool:IsPlayerBurning(client)
{
	if (!IsValidClient(client)) return false;
	new Float:isburning = GetEntDataFloat(client, propinfoburn);
	if (isburning>0) return true;
	
	else return false;
}

bool:IsIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated")!=0)
		return true;
	return false;
}

public IsValidClient (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	if (!IsPlayerAlive(client))
		return false;
	return true;
}