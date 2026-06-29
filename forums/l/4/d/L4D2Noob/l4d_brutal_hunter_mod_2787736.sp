#define PLUGIN_VERSION "1.5.7"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define CVAR_FLAGS FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY
float initialPosition[32][3];
Handle FatalPounceDistance = INVALID_HANDLE;
Handle BonusDmgTimer[MAXPLAYERS + 1];
Handle h_ApplyToIncapped;
Handle h_BonusDmgHard;
Handle h_BonusDmgTemp;
int BonusDmgHard;
float BonusDmgTemp;
int Dmg[MAXPLAYERS + 1];
int DmgTemp[MAXPLAYERS + 1];

bool ApplyToIncapped;
bool Pounced[MAXPLAYERS + 1];
int propinfoburn;

public void OnPluginStart()
{
	HookEvent("lunge_pounce", Pounce, EventHookMode_Pre);
	HookEvent("pounce_stopped", PounceStop);
	HookEvent("ability_use", AbilityUse);
	FatalPounceDistance = CreateConVar("l4d_hunter_fatal_distance", "1000", "Необходимая дистанция", CVAR_FLAGS);
	h_ApplyToIncapped = CreateConVar("l4d_hunter_bonusdmg_applytoincapped", "1", "Должны ли мы применять бонусный урон к выжившим с ограниченными возможностями?", CVAR_FLAGS);
	h_BonusDmgHard = CreateConVar("l4d_hunter_bonusdmg_hardhp", "1", "Дополнительный урон.", CVAR_FLAGS);
	h_BonusDmgTemp = CreateConVar("l4d_hunter_bonusdmg_temphp", "2.0", "Количество дополнительного урона", CVAR_FLAGS);
	BonusDmgHard = GetConVarInt(h_BonusDmgHard);
	BonusDmgTemp = GetConVarFloat(h_BonusDmgTemp);
	ApplyToIncapped = GetConVarBool(h_ApplyToIncapped);
	HookConVarChange(h_ApplyToIncapped, ApplyToIncappedChanged);
	HookConVarChange(h_BonusDmgHard, DmgHardChanged);
	HookConVarChange(h_BonusDmgTemp, DmgTempChanged);
	AutoExecConfig(true, "l4d_brutal_hunter_mod");
	CreateConVar("l4d_bh_mod_version", PLUGIN_VERSION, "Версия плагина", FCVAR_NONE | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	propinfoburn = FindSendPropInfo("CTerrorPlayer", "m_burnPercent");
}

public void ApplyToIncappedChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	ApplyToIncapped = GetConVarBool(h_ApplyToIncapped);
}

public void DmgHardChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	BonusDmgHard = GetConVarInt(h_BonusDmgHard);
}

public void DmgTempChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	BonusDmgTemp = GetConVarFloat(h_BonusDmgTemp);
}

public void AbilityUse(Handle event, const char[] name, bool dontBroadcast)
{
	int user = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientAbsOrigin(user, initialPosition[user]);
}


public Action Pounce(Handle event, const char[] name, bool dontBroadcast)
{
	//PrintToChatAll("\x05Pounce Event");
	float pouncePosition[3];
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientAbsOrigin(attacker, pouncePosition);
	int distance = RoundToNearest(GetVectorDistance(initialPosition[attacker], pouncePosition));
	//PrintToChatAll("%i", distance);
	if (distance >= GetConVarInt(FatalPounceDistance))
	{
		int victim = GetClientOfUserId(GetEventInt(event, "victim"));
		char attacker_name[MAX_NAME_LENGTH];
		char victim_name[MAX_NAME_LENGTH];
		GetClientName(attacker, attacker_name, MAX_NAME_LENGTH);
		GetClientName(victim, victim_name, MAX_NAME_LENGTH);
		PrintToChatAll("\03%s \x01погиб, потому что \x03%s \x01прыгнул на него со смертельной дистанции.", victim_name, attacker_name);
		ForcePlayerSuicide(victim);
		return Plugin_Continue;
	}
	if (IsPlayerBurning(attacker))
	{
		Handle pack;
		int victim = GetClientOfUserId(GetEventInt(event, "victim"));
		Pounced[victim] = true;
		Dmg[attacker] = 0;
		DmgTemp[attacker] = 0;
		BonusDmgTimer[victim] = CreateDataTimer(0.7, BonusDmgTimerFunction, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		WritePackCell(pack, attacker);
		WritePackCell(pack, victim);
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action BonusDmgTimerFunction(Handle timer, Handle pack)
{
	ResetPack(pack);
	int attacker = ReadPackCell(pack);
	int victim = ReadPackCell(pack);
	
	float tempHP = GetEntPropFloat(victim, Prop_Send, "m_healthBuffer");
	
	if (!IsValidClient(victim) || !IsValidClient(attacker))
	{
		if (BonusDmgTimer[victim] != INVALID_HANDLE)
		{
			KillTimer(BonusDmgTimer[victim]);
			BonusDmgTimer[victim] = INVALID_HANDLE;
			int TotalDmg = (Dmg[attacker] * BonusDmgHard) + (DmgTemp[attacker] * GetConVarInt(h_BonusDmgTemp));
			char attackername[MAX_NAME_LENGTH];
			char victimname[MAX_NAME_LENGTH];
			GetClientName(attacker, attackername, 32);
			GetClientName(victim, victimname, MAX_NAME_LENGTH);
			//PrintToChatAll("\x04Killed Timer : NOT VALID CLIENT");
			PrintToChatAll("\x03%s\x01 нанес \x04%i\x01 дополнительный урон игроку \x03%s.", attackername, TotalDmg, victimname);
			return Plugin_Handled;
		}
	}
	if ((Pounced[victim] == false) && (BonusDmgTimer[victim] != INVALID_HANDLE))
	{
		KillTimer(BonusDmgTimer[victim]);
		BonusDmgTimer[victim] = INVALID_HANDLE;
		int TotalDmg = (Dmg[attacker] * BonusDmgHard) + (DmgTemp[attacker] * GetConVarInt(h_BonusDmgTemp));
		char attackername[MAX_NAME_LENGTH];
		char victimname[MAX_NAME_LENGTH];
		GetClientName(attacker, attackername, MAX_NAME_LENGTH);
		GetClientName(victim, victimname, MAX_NAME_LENGTH);
		//PrintToChatAll("\x04Killed Timer: Pounce stopped by someone");
		PrintToChatAll("\x03%s\x01 нанес \x04%i\x01 дополнительный урон игроку \x03%s.", attackername, TotalDmg, victimname);
		return Plugin_Handled;
	}
	if ((IsIncapped(victim)) && (!ApplyToIncapped) && (BonusDmgTimer[victim] != INVALID_HANDLE))
	{
		KillTimer(BonusDmgTimer[victim]);
		BonusDmgTimer[victim] = INVALID_HANDLE;
		int TotalDmg = (Dmg[attacker] * BonusDmgHard) + (DmgTemp[attacker] * GetConVarInt(h_BonusDmgTemp));
		char attackername[MAX_NAME_LENGTH];
		char victimname[MAX_NAME_LENGTH];
		GetClientName(attacker, attackername, MAX_NAME_LENGTH);
		GetClientName(victim, victimname, MAX_NAME_LENGTH);
		//PrintToChatAll("\x04Killed Timer: Not apply to incapped");
		PrintToChatAll("\x03%s\x01 нанес \x04%i\x01 дополнительный урон \x03%s.", attackername, TotalDmg, victimname);
		return Plugin_Handled;
	}
	
	if ((!IsPlayerBurning(attacker)) && (BonusDmgTimer[victim] != INVALID_HANDLE))
	{
		KillTimer(BonusDmgTimer[victim]);
		BonusDmgTimer[victim] = INVALID_HANDLE;
		int TotalDmg = (Dmg[attacker] * BonusDmgHard) + (DmgTemp[attacker] * GetConVarInt(h_BonusDmgTemp));
		char attackername[MAX_NAME_LENGTH];
		char victimname[MAX_NAME_LENGTH];
		GetClientName(attacker, attackername, MAX_NAME_LENGTH);
		GetClientName(victim, victimname, MAX_NAME_LENGTH);
		//PrintToChatAll("\x04Killed Timer: Not burning anymore");
		PrintToChatAll("\x03%s\x01 нанес \x04%i\x01 дополнительный урон \x03%s.", attackername, TotalDmg, victimname);
		return Plugin_Handled;
	}
	
	
	int HP = GetEntProp(victim, Prop_Data, "m_iHealth");
	if (HP > BonusDmgHard)
	{
		SetEntProp(victim, Prop_Send, "m_iHealth", (HP - BonusDmgHard));
		Dmg[attacker] += 1;
	}
	//PrintToChatAll("tempHP %i", tempHP);
	//PrintToChatAll("HP %i", HP);
	if ((HP <= 1) && (tempHP > 1))
	{
		//new Float:damagefloat = 1.0;
		if (BonusDmgTemp < tempHP)
		{
			SetEntPropFloat(victim, Prop_Send, "m_healthBuffer", (tempHP - BonusDmgTemp));
			DmgTemp[attacker] += 1;
			//PrintToChatAll("tempHP %f, new temp HP %f", tempHP, tempHP - damagefloat);
		}
	}
	return Plugin_Continue;
}

public void PounceStop(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	//PrintToChatAll("\x05Pounce Stop Event");
	Pounced[victim] = false;
	//if (BonusDmgTimer[victim]==INVALID_HANDLE) return;
	//if (BonusDmgTimer[victim] != INVALID_HANDLE) KillTimer(BonusDmgTimer[victim]);	
}

bool IsPlayerBurning(int client)
{
	if (!IsValidClient(client))return false;
	float isburning = GetEntDataFloat(client, propinfoburn);
	if (isburning > 0)return true;
	
	else return false;
}

bool IsIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0)
		return true;
	return false;
}

public bool IsValidClient(int client)
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