#include <sourcemod>

#define PLUGIN_VERSION	"1.0.0"

new Handle:BMEnabled;
new Handle:BMDebug;
new Handle:BMMode;
new Handle:AmountPerHP;
new Handle:AmountPerKill;
new Handle:BonusPerHeadshot;
new Handle:SelfInflictedPenalty;
new Handle:SuicidePenalty;
new Handle:GlobalHPModifier;
new Handle:GlobalKillModifier;
new Handle:BalanceRatio;
new Handle:EchoToChat;

new iAccount;

public Plugin:myinfo = 
{
	name = "Blood Money",
	author = "Jean-Sebastien Carle",
	description = "Attackers gain money at the expense of their victims.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	CreateConVar("bm_version", PLUGIN_VERSION, "Blood Money Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	BMEnabled				=	CreateConVar("bm_enabled", "1", "Enable plugin");
	BMDebug					=	CreateConVar("bm_debug", "0", "Enable debugging output");
	BMMode					=	CreateConVar("bm_mode", "3", "Active mode");
	AmountPerHP				=	CreateConVar("bm_hpamount", "5", "Amount of money per HP of damage");
	AmountPerKill			=	CreateConVar("bm_killamount", "500", "Amount of money per kill");
	BonusPerHeadshot		= 	CreateConVar("bm_headshotbonus", "500", "Bonus amount per headshot");
	SelfInflictedPenalty	=	CreateConVar("bm_selfinflictedpenalty", "-10", "Penalty amount per HP of self-inflicted damage");
	SuicidePenalty			=	CreateConVar("bm_suicidepenalty", "-1000", "Penalty amount for a suicide");
	GlobalHPModifier		=	CreateConVar("bm_globalhpmodifier", "0", "Amount of money for both parties per HP of damage");
	GlobalKillModifier		=	CreateConVar("bm_globalkillmodifier", "0", "Amount of money for both parties per kill");
	BalanceRatio			= 	CreateConVar("bm_balanceratio", "0.5", "Balance ratio (1.0 = Attacker / 0.5 = Shared / 0.0 = Victim)", 0, true, 0.0, true, 1.0);
	EchoToChat				=	CreateConVar("bm_echotochat", "2", "Echo to chat");

	AutoExecConfig(true, "plugin.bloodmoney", "sourcemod");
	
	iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

}

public OnConfigsExecuted()
{
	PrintToServer("[Blood Money] Plugin loaded.");
	HookConVarChange(BMEnabled, OnConvarChanged);
	if (GetConVarInt(BMEnabled) == 1)
	{
		if (GetConVarInt(BMMode) == 1 || GetConVarInt(BMMode) == 3) HookEvent("player_hurt", DamageEvent, EventHookMode_Post);
		if (GetConVarInt(BMMode) == 2 || GetConVarInt(BMMode) == 3) HookEvent("player_death", DeathEvent, EventHookMode_Post);
	}
}

public OnConvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    static iNewVal = 0;

    if (convar == BMEnabled)
    {
        iNewVal = StringToInt(newValue);
        if (StringToInt(oldValue) != iNewVal)
            if (iNewVal > 0) {
				if (GetConVarInt(BMMode) == 1 || GetConVarInt(BMMode) == 3) HookEvent("player_hurt", DamageEvent, EventHookMode_Post);
				if (GetConVarInt(BMMode) == 2 || GetConVarInt(BMMode) == 3) HookEvent("player_death", DeathEvent, EventHookMode_Post);
            } else {
				if (GetConVarInt(BMMode) == 1 || GetConVarInt(BMMode) == 3) UnhookEvent("player_hurt", DamageEvent, EventHookMode_Post);
				if (GetConVarInt(BMMode) == 2 || GetConVarInt(BMMode) == 3) UnhookEvent("player_death", DeathEvent, EventHookMode_Post);
            }
    }
}

public OnPluginEnd()
{
	UnhookConVarChange(BMEnabled, OnConvarChanged);
}


public Action:DamageEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(BMMode) != 1 && GetConVarInt(BMMode) != 3) return Plugin_Continue;		
	
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	new iDamage = GetEventInt(event, "dmg_health");
	new String:attackerName[40];
	new String:victimName[40];
	GetClientName(iAttacker, attackerName, sizeof(attackerName));
	GetClientName(iVictim, victimName, sizeof(victimName));
	
	new fAttackerMoney = ConstrainToMoneyBounds(RoundToNearest(float(GetMoney(iAttacker)) + (float(GetConVarInt(AmountPerHP) * iDamage) * ((0 + GetConVarFloat(BalanceRatio)) * 2))) + (GetConVarInt(GlobalHPModifier) * iDamage));
	new fVictimMoney = ConstrainToMoneyBounds(RoundToNearest(float(GetMoney(iVictim)) - (float(GetConVarInt(AmountPerHP) * iDamage) * ((1 - GetConVarFloat(BalanceRatio)) * 2))) + (GetConVarInt(GlobalHPModifier) * iDamage));
	
	if (iAttacker == iVictim)
		fVictimMoney = ConstrainToMoneyBounds(fVictimMoney + (GetConVarInt(SelfInflictedPenalty) * iDamage));
	
	new fAttackerDiff = fAttackerMoney - GetMoney(iAttacker);
	new fVictimDiff = fVictimMoney - GetMoney(iVictim);

	if (GetConVarInt(BMDebug) == 1)
		PrintToServer("[Blood Money] HP: %s [%d / %d / %d] / %s [%d / %d / %d]", attackerName, GetMoney(iAttacker), fAttackerMoney, fAttackerDiff, victimName, GetMoney(iVictim), fVictimMoney, fVictimDiff);

	if (GetConVarInt(EchoToChat) == 1 || GetConVarInt(EchoToChat) == 3)
		if (iAttacker == iVictim) {
			if (fVictimDiff > 0) 
				PrintToChatAll("\x04[Blood Money] $%d was given to %s for hurting himself.", fVictimDiff, victimName);
			else if (fVictimDiff < 0)
				PrintToChatAll("\x01[Blood Money] $%d was taken away from %s for hurting himself.", fVictimDiff * -1, victimName);
		} else {
			if (fAttackerDiff > 0)
				PrintToChatAll("\x04[Blood Money] $%d was given to %s for attacking %s.", fAttackerDiff, attackerName, victimName);
			else if (fAttackerDiff < 0)
				PrintToChatAll("\x01[Blood Money] $%d was taken away from %s for attacking %s.", fAttackerDiff * -1, attackerName, victimName);
			if (fVictimDiff > 0)
				PrintToChatAll("\x04[Blood Money] %s was a victim of %s and received $%d.", victimName, attackerName, fVictimDiff);
			else if (fVictimDiff < 0)
				PrintToChatAll("\x01[Blood Money] %s was a victim of %s and lost $%d.", victimName, attackerName, fVictimDiff * -1);
		}	
	
	if (iAttacker == iVictim)
		SetMoney(iVictim, fVictimMoney);
	else {
		SetMoney(iAttacker, fAttackerMoney);
		SetMoney(iVictim, fVictimMoney);	}
	
	return Plugin_Continue;
}

public Action:DeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(BMMode) != 2 && GetConVarInt(BMMode) != 3) return Plugin_Continue;		
	
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	new isHeadshot = GetEventBool(event, "headshot");
	new String:attackerName[40];
	new String:victimName[40];
	GetClientName(iAttacker, attackerName, sizeof(attackerName));
	GetClientName(iVictim, victimName, sizeof(victimName));
	
	new fAttackerMoney = ConstrainToMoneyBounds(RoundToNearest(float(GetMoney(iAttacker)) + (float(GetConVarInt(AmountPerKill)) * ((0 + GetConVarFloat(BalanceRatio)) * 2))) + GetConVarInt(GlobalKillModifier));
	new fVictimMoney = ConstrainToMoneyBounds(RoundToNearest(float(GetMoney(iVictim)) - (float(GetConVarInt(AmountPerKill)) * ((1 - GetConVarFloat(BalanceRatio)) * 2))) + GetConVarInt(GlobalKillModifier));
	new fAttackerHeadshotBonus = ConstrainToMoneyBounds(RoundToNearest(float(fAttackerMoney) + (float(GetConVarInt(BonusPerHeadshot)) * ((0 + GetConVarFloat(BalanceRatio)) * 2))));
	new fVictimHeadshotBonus = ConstrainToMoneyBounds(RoundToNearest(float(fVictimMoney) - (float(GetConVarInt(BonusPerHeadshot)) * ((1 - GetConVarFloat(BalanceRatio)) * 2))));
	
	if (iAttacker == iVictim)
		fVictimMoney = ConstrainToMoneyBounds(fVictimMoney + GetConVarInt(SuicidePenalty));
	
	new fAttackerDiff = fAttackerMoney - GetMoney(iAttacker);
	new fVictimDiff = fVictimMoney - GetMoney(iVictim);
	new fAttackerHeadshotDiff = fAttackerHeadshotBonus - fAttackerMoney;
	new fVictimHeadshotDiff = fVictimHeadshotBonus - fVictimMoney;
	
	if (GetConVarInt(BMDebug) == 1) {
		PrintToServer("[Blood Money] Kill: %s [%d / %d / %d] / %s [%d / %d / %d]", attackerName, GetMoney(iAttacker), fAttackerMoney, fAttackerDiff, victimName, GetMoney(iVictim), fVictimMoney, fVictimDiff);
		PrintToServer("[Blood Money] Headshot: %s [%d / %d / %d] / %s [%d / %d / %d]", attackerName, GetMoney(iAttacker), fAttackerHeadshotBonus, fAttackerHeadshotDiff, victimName, GetMoney(iVictim), fVictimHeadshotBonus, fVictimHeadshotDiff);
	}

	if (GetConVarInt(EchoToChat) == 2 || GetConVarInt(EchoToChat) == 3) {
		if (isHeadshot) {
			if (iAttacker == iVictim) {
				if (fVictimDiff > 0)
					PrintToChatAll("\x04[Blood Money] $%d with a $%d headshot bonus was given to %s for killing himself.", fVictimDiff, fVictimHeadshotDiff, victimName);
				else if (fVictimDiff < 0)
					PrintToChatAll("\x01[Blood Money] $%d with a $%d headshot bonus was taken away from %s for killing himself.", fVictimDiff * -1, fVictimHeadshotDiff * -1, victimName);
			} else {
				if (fAttackerDiff > 0)
					PrintToChatAll("\x04[Blood Money] $%d with a $%d headshot bonus was given to %s for killing %s.", fAttackerDiff, fAttackerHeadshotDiff, attackerName, victimName);
				else if (fAttackerDiff < 0)
					PrintToChatAll("\x01[Blood Money] $%d with a $%d headshot bonus was taken away from %s for killing %s.", fAttackerDiff * -1, fAttackerHeadshotDiff * -1, attackerName, victimName);
				if (fVictimDiff > 0)
					PrintToChatAll("\x04[Blood Money] %s was killed by %s and received $%d with a $%d headshot bonus.", victimName, attackerName, fVictimDiff, fVictimHeadshotDiff);
				else if (fVictimDiff < 0)
					PrintToChatAll("\x01[Blood Money] %s was killed by %s and lost $%d with a $%d headshot bonus.", victimName, attackerName, fVictimDiff * -1, fVictimHeadshotDiff * -1);
			}
		} else {
			if (iAttacker == iVictim) {
				if (fVictimDiff > 0) 
					PrintToChatAll("\x04[Blood Money] $%d was given to %s for killing himself.", fVictimDiff, victimName);
				else if (fVictimDiff < 0)
					PrintToChatAll("\x01[Blood Money] $%d was taken away from %s for killing himself.", fVictimDiff * -1, victimName);
			} else {
				if (fAttackerDiff > 0)
					PrintToChatAll("\x04[Blood Money] $%d was given to %s for killing %s.", fAttackerDiff, attackerName, victimName);
				else if (fAttackerDiff < 0)
					PrintToChatAll("\x01[Blood Money] $%d was taken away from %s for killing %s.", fAttackerDiff * -1, attackerName, victimName);
				if (fVictimDiff > 0)
					PrintToChatAll("\x04[Blood Money] %s was killed by %s and received $%d.", victimName, attackerName, fVictimDiff);
				else if (fVictimDiff < 0)
					PrintToChatAll("\x01[Blood Money] %s was killed by %s and lost $%d.", victimName, attackerName, fVictimDiff * -1);
			}
		}
	}
	
	if (iAttacker == iVictim) {
		if (isHeadshot)
			SetMoney(iVictim, fVictimHeadshotBonus);
		else
			SetMoney(iVictim, fVictimMoney);
	} else {
		if (isHeadshot) {
			SetMoney(iAttacker, fAttackerHeadshotBonus);
			SetMoney(iVictim, fVictimHeadshotBonus);
		} else {
			SetMoney(iAttacker, fAttackerMoney);
			SetMoney(iVictim, fVictimMoney);
		}
	}

	return Plugin_Continue;
}

public GetMoney(client)
{
	if (iAccount != -1)
		return GetEntData(client, iAccount);
	
	return 0;
}

public SetMoney(client, amount)
{
	if (iAccount != -1)
		SetEntData(client, iAccount, amount);
}

public ConstrainToMoneyBounds(amount)
{
	new iReturn;
	
	if (amount <= 0) 
		iReturn = 0;
	else if (amount >= 16000)
		iReturn = 16000;
	else
		iReturn = amount;
	
	return iReturn;
}
