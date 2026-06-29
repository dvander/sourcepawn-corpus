#define PLUGIN_VERSION "1.5.2"

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY

new Float:initialPosition[32][3];
new Handle:FatalPounceDistance = INVALID_HANDLE;
new Handle:FatalPouncePenaltyTime = INVALID_HANDLE; // For delay
new Handle:BonusDmgTimer[MAXPLAYERS+1];
new Handle:h_ApplyToIncapped;
new Handle:h_BonusDmgHard;
new Handle:h_BonusDmgTemp;
new Handle:hPenaltyTimer = INVALID_HANDLE;
new BonusDmgHard;
new Float:BonusDmgTemp;
new Dmg[MAXPLAYERS+1];
new DmgTemp[MAXPLAYERS+1];
new bhpPenalty;

new bool:ApplyToIncapped;
new bool:Pounced[MAXPLAYERS+1];
new bool:IsPenaltyOn[MAXPLAYERS+1] = false; // For delay
new propinfoburn;

public Plugin:myinfo = 
{
	name = "Brutal Hunter Pounce",
	author = "Olj",
	description = "Makes Farther Hunter Pounces To Be Brutal.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("lunge_pounce", OnLungePounce, EventHookMode_Pre);
	HookEvent("pounce_stopped", OnPounceStopped);
	HookEvent("ability_use", OnAbilityUse);
	HookEvent("round_end", OnRoundEnd);
	
	FatalPounceDistance = CreateConVar("brutal_hunter_pounce_fatal_distance", "1750", "Distance To Be Considered As Brutal HunterPounce", CVAR_FLAGS);
	FatalPouncePenaltyTime = CreateConVar("brutal_hunter_pounce_fatal_penalty_time", "60", "Penalty Time For Brutal Hunter Pounce", CVAR_FLAGS);
	h_ApplyToIncapped = CreateConVar("brutal_hunter_pounce_bonusdmg_incapped", "0", "Enable/Disable Bonus Damage To Incapacitated", CVAR_FLAGS);
	h_BonusDmgHard = CreateConVar("brutal_hunter_pounce_bonusdmg_hardhp", "5", "Bonus Damage Applied", CVAR_FLAGS);
	h_BonusDmgTemp = CreateConVar("brutal_hunter_pounce_bonusdmg_temphp", "2.5", "Nonus Damage Applied To Temporary", CVAR_FLAGS);
	
	BonusDmgHard = GetConVarInt(h_BonusDmgHard);
	BonusDmgTemp = GetConVarFloat(h_BonusDmgTemp);
	ApplyToIncapped = GetConVarBool(h_ApplyToIncapped);
	
	HookConVarChange(h_ApplyToIncapped, ApplyToIncappedChanged);
	HookConVarChange(h_BonusDmgHard, DmgHardChanged);
	HookConVarChange(h_BonusDmgTemp, DmgTempChanged);
	
	AutoExecConfig(true, "brutal_hunter_pounce");
	
	CreateConVar("brutal_hunter_pounce_version", PLUGIN_VERSION, "Brutal Hunter Pounce Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	propinfoburn = FindSendPropInfo("CTerrorPlayer", "m_burnPercent");
	bhpPenalty = GetConVarInt(FatalPouncePenaltyTime);
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
	
public OnAbilityUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	if (user == 0)
	{
		return;
	}
	GetClientAbsOrigin(user, initialPosition[user]);
	
	// Added this so hunters can jump farther than the usual pounce distance.
	// Only change vecVelocity[2] if you want your pounce distance to be
	// the farthest.
	decl String:pounceAbility[24];
	GetEventString(event, "ability", pounceAbility, 24);
	
	if(GetClientTeam(user) == 3 && !IsFakeClient(user) && GetEntProp(user, Prop_Send, "m_zombieClass") == 3)
	{
		if(StrEqual(pounceAbility, "ability_lunge", false) == true)
		{
			CreateTimer(0.1, CustomVelocityDelay, user);
		}
	}
}

public Action:CustomVelocityDelay(Handle:timer, any:user)
{
	KillTimer(timer);
	if (!IsServerProcessing())
	{
		return Plugin_Stop;
	}
	
	decl Float:vecVelocity[3];
	GetEntPropVector(user, Prop_Data, "m_vecVelocity", vecVelocity);
	vecVelocity[0] *= 1.6;
	vecVelocity[1] *= 1.6;
	vecVelocity[2] *= 1.8;
	TeleportEntity(user, NULL_VECTOR, NULL_VECTOR, vecVelocity);
	
	return Plugin_Stop;
}

public Action:OnLungePounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:pouncePosition[3];
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientAbsOrigin(attacker, pouncePosition);
	new distance = RoundToNearest(GetVectorDistance(initialPosition[attacker], pouncePosition));
	
	if (distance >= GetConVarInt(FatalPounceDistance))
	{
		if(IsPenaltyOn[attacker] == false)
		{
			IsPenaltyOn[attacker] = true;
			CreateTimer(62.0, PenaltyResetTimer, attacker);
			new victim = GetClientOfUserId(GetEventInt(event, "victim"));
			decl String:attacker_name[MAX_NAME_LENGTH];
			decl String:victim_name[MAX_NAME_LENGTH];
			GetClientName(attacker, attacker_name, MAX_NAME_LENGTH);
			GetClientName(victim, victim_name, MAX_NAME_LENGTH);
			PrintToChatAll("\03%s \x01Brutally Pounced \x03%s \x01From Deadly Distance! \x04[%d Units]\x01", attacker_name, victim_name, distance);
			ForcePlayerSuicide(victim);
			
			// Add the timer delay and notify brutal pouncer when will he/she can brutal pounce
			// someone again.
			if(hPenaltyTimer == INVALID_HANDLE)
			{
				hPenaltyTimer = CreateTimer(1.0, BHPounceTimer, attacker, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				BHPounceTimer(hPenaltyTimer, attacker);
			}
		}
		return Plugin_Continue;
	}
	
	if (IsPlayerBurning(attacker))
	{
		new Handle:pack;
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));
		Pounced[victim] = true;
		Dmg[attacker] = 0;
		DmgTemp[attacker] = 0;
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
	
	if (!IsValidClient(victim) || !IsValidClient(attacker))
	{
		if (BonusDmgTimer[victim] != INVALID_HANDLE)
		{
			KillTimer(BonusDmgTimer[victim]);	
			BonusDmgTimer[victim] = INVALID_HANDLE;
			new TotalDmg = (Dmg[attacker] * BonusDmgHard) + (DmgTemp[attacker] * GetConVarInt(h_BonusDmgTemp));
			decl String:attackername[MAX_NAME_LENGTH];
			decl String:victimname[MAX_NAME_LENGTH];
			GetClientName(attacker, attackername, MAX_NAME_LENGTH);
			GetClientName(victim, victimname, MAX_NAME_LENGTH);
			
			PrintToChatAll("\x03%s\x01 Did \x04%i\x01 Bonus Damage To \x03%s!", attackername, TotalDmg, victimname);
			return Plugin_Handled;
		}
	}
	
	if (Pounced[victim] == false && BonusDmgTimer[victim] != INVALID_HANDLE)
	{
		KillTimer(BonusDmgTimer[victim]);	
		BonusDmgTimer[victim] = INVALID_HANDLE;
		new TotalDmg = (Dmg[attacker] * BonusDmgHard) + (DmgTemp[attacker] * GetConVarInt(h_BonusDmgTemp));
		decl String:attackername[MAX_NAME_LENGTH];
		decl String:victimname[MAX_NAME_LENGTH];
		GetClientName(attacker, attackername, MAX_NAME_LENGTH);
		GetClientName(victim, victimname, MAX_NAME_LENGTH);
		
		PrintToChatAll("\x03%s\x01 Did \x04%i\x01 Bonus Damage To \x03%s!", attackername, TotalDmg, victimname);
		return Plugin_Handled;
	}
	
	if (IsIncapped(victim) && !ApplyToIncapped && BonusDmgTimer[victim] != INVALID_HANDLE)
	{
		KillTimer(BonusDmgTimer[victim]);	
		BonusDmgTimer[victim] = INVALID_HANDLE;
		new TotalDmg = (Dmg[attacker] * BonusDmgHard) + (DmgTemp[attacker] * GetConVarInt(h_BonusDmgTemp));
		decl String:attackername[MAX_NAME_LENGTH];
		decl String:victimname[MAX_NAME_LENGTH];
		GetClientName(attacker, attackername, MAX_NAME_LENGTH);
		GetClientName(victim, victimname, MAX_NAME_LENGTH);
		
		PrintToChatAll("\x03%s\x01 Did \x04%i\x01 Bonus Damage To \x03%s!", attackername, TotalDmg, victimname);
		return Plugin_Handled;
	}
	
	if (!IsPlayerBurning(attacker) && BonusDmgTimer[victim] != INVALID_HANDLE)
	{
		KillTimer(BonusDmgTimer[victim]);	
		BonusDmgTimer[victim] = INVALID_HANDLE;
		new TotalDmg = (Dmg[attacker] * BonusDmgHard) + (DmgTemp[attacker] * GetConVarInt(h_BonusDmgTemp));
		decl String:attackername[MAX_NAME_LENGTH];
		decl String:victimname[MAX_NAME_LENGTH];
		GetClientName(attacker, attackername, MAX_NAME_LENGTH);
		GetClientName(victim, victimname, MAX_NAME_LENGTH);
		
		PrintToChatAll("\x03%s\x01 Did \x04%i\x01 Bonus Damage To \x03%s!", attackername, TotalDmg, victimname);
		return Plugin_Handled;	
	}
	
	new HP = GetEntProp(victim, Prop_Data, "m_iHealth");
	if (HP > BonusDmgHard) 
	{
		SetEntProp(victim, Prop_Send, "m_iHealth", (HP - BonusDmgHard));
		Dmg[attacker] += 1;
	}
	
	if (HP <= 1 && tempHP > 1)
	{
		if (BonusDmgTemp < tempHP)
		{
			SetEntPropFloat(victim, Prop_Send, "m_healthBuffer", (tempHP - BonusDmgTemp));
			DmgTemp[attacker] += 1;
		}
	}
	return Plugin_Continue;
}

public OnPounceStopped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	Pounced[victim] = false;
}

public Action:BHPounceTimer(Handle:timer, any:hunter)
{
	if(timer == hPenaltyTimer)
	{
		if(bhpPenalty > 0)
		{
			// Notify the time before brutal pouncer can brutal pounce someone again.
			PrintHintText(hunter, "Wait For %d Seconds To Do Another Brutal Pounce!", bhpPenalty);
			bhpPenalty--;
			return Plugin_Continue;
		}
		
		// If the timer has stopped, notify brutal pouncer that he/she can
		// brutal pounce someone again.
		PrintToChat(hunter, "\x04Again, You Can Do Another\x03 Brutal Pounce!");
	}
	
	return Plugin_Stop;
}

public Action:PenaltyResetTimer(Handle:timer, any:hunter)
{
	// Reset the penalty time delay every brutal pounce
	// a player makes.
	IsPenaltyOn[hunter] = false;
	
	if(hPenaltyTimer != INVALID_HANDLE)
	{
		CloseHandle(hPenaltyTimer);
		hPenaltyTimer = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public OnMapEnd()
{
	hPenaltyTimer = INVALID_HANDLE;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	hPenaltyTimer = INVALID_HANDLE;
}

bool:IsPlayerBurning(client)
{
	if (!IsValidClient(client))
	{
		return false;
	}
	new Float:isburning = GetEntDataFloat(client, propinfoburn);
	if (isburning > 0)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool:IsIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0)
	{
		return true;
	}
	return false;
}

public IsValidClient(client)
{
	if (client == 0 || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return false;
	}
	
	return true;
}

