/* Plugin Template generated by Pawn Studio */
// Fixed, if attacker have 1600$ and hurt enemy, it gain 16000$ immediatelly
// Added admin only option
// Added semicolons and some code touch-ups
// Added option to ignore self damage/kills
// Added missed option to ignore self kills in death event, modified minus money from 305 to 300
// Added so only one team can get money

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:MnPerHit = INVALID_HANDLE;
new Handle:MnPerKill = INVALID_HANDLE;
new Handle:MnPerHs = INVALID_HANDLE;
new Handle:MnAdminOnly = INVALID_HANDLE;
new Handle:SelfKill = INVALID_HANDLE;
new Handle:TeamKill = INVALID_HANDLE;
new Handle:KnifeKill = INVALID_HANDLE;
new Handle:Grenade = INVALID_HANDLE;

new g_iAccount = 0;

public Plugin:myinfo = 
{
	name = "Damage Money",
	author = "Fredd, Bacardi, TnTSCS",
	description = "",
	version = "1.5.1a",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("damage_money_version", "1.0", "Damage Money Version");
	
	MnPerHit		=	CreateConVar("money_per_hit", "5", "Amount of money per hit\n0=Disabled\n>0=Amount to give", _, true, 0.0);
	MnPerKill		=	CreateConVar("money_per_kill", "100", "Amount of money per kill", _, true, 0.0);
	MnPerHs		= 	CreateConVar("money_per_headshot", "50", "Amount of money per headshot\n0=Disabled\n>0=Amount to give", _, true, 0.0);
	MnAdminOnly	= 	CreateConVar("money_admin_only", "0", "Only admins can receive these extra cash\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0);
	SelfKill		=	CreateConVar("money_per_selfkill", "0", "Give money on self kills?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0);
	TeamKill		=	CreateConVar("money_per_team", "0", "Only allow defined team to receive money\n0=Disabled\n2=Terrorist\n3=CT", _, true, 0.0, true, 3.0);
	KnifeKill		=	CreateConVar("money_per_knifekill", "0", "Amount of money to give on knife kills\n0=Disabled\n>0=Amount to give", _, true, 0.0);
	Grenade			=	CreateConVar("money_per_nadekill", "0", "Amount of money to give on grenade kills\n0=Disabled\n>0=Amount to give", _, true, 0.0);
	
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	if (g_iAccount <= 0)
	{
		SetFailState("Unable to hook m_iAccount");
	}
	
	HookEvent("player_hurt", DamageEvent);
	HookEvent("player_death", DeathEvent, EventHookMode_Pre);
}

public DamageEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(MnPerHit) <= 0)
	{
		return;
	}
	
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!IsValidPlayer(iAttacker) || (iVictim == iAttacker && !GetConVarBool(SelfKill)) || 
		(GetConVarInt(TeamKill) > 1 && GetClientTeam(iAttacker) != GetConVarInt(TeamKill)) ||
		(GetConVarInt(MnAdminOnly) == 1 && !CheckCommandAccess(iAttacker, "damage_money", ADMFLAG_SLAY)))
	{
		return;
	}
	
	new fMoney = GetMoney(iAttacker) + GetConVarInt(MnPerHit);
	
	fMoney >= 16000 ? SetMoney(iAttacker, 16000) : SetMoney(iAttacker, fMoney);
}
public Action:DeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new xAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new xVictim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsValidPlayer(xAttacker) || (xVictim == xAttacker && !GetConVarBool(SelfKill)))
	{
		return Plugin_Continue;
	}
	
	new fMoney = GetMoney(xAttacker) - 300;
	
	if (GetConVarInt(TeamKill) > 1 && GetClientTeam(xAttacker) != GetConVarInt(TeamKill) ||
		(GetConVarInt(MnAdminOnly) == 1 && !CheckCommandAccess(xAttacker, "damage_money", ADMFLAG_SLAY)))
	{ // Either this was a team kill and team kill rewareds
		fMoney <= 0 ? SetMoney(xAttacker, 0) : SetMoney(xAttacker, fMoney);
		return Plugin_Continue;
	}
	
	new String:weaponName[80];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	
	if (GetEventBool(event, "headshot") && GetConVarInt(MnPerHs) > 0)
	{ // If the attacker got a headshot, set money to HeadShot money value
		fMoney += GetConVarInt(MnPerHs);
	}
	else if (GetConVarInt(KnifeKill) > 0 && StrEqual(weaponName, "knife", false))
	{ // If weapon used was a knife, and KnifeKill is greater than 0, set money to KnifeKill money value
		fMoney += GetConVarInt(KnifeKill);
	}
	else if (GetConVarInt(Grenade) > 0 && StrEqual(weaponName, "hegrenade", false))
	{ // If weapon used was an hegrenade and Grenade is greater than 0, set money to Grenade money value
		fMoney += GetConVarInt(Grenade);
	}
	else
	{ // Otherwise, just set money to MnPerKill value
		fMoney += GetConVarInt(MnPerKill);
	}
	
	// If amount of reward money is greater than or equal to 16000, set to 16000, otherwise, set to value of reward money
	fMoney >= 16000 ? SetMoney(xAttacker, 16000) : SetMoney(xAttacker, fMoney);
	
	return Plugin_Continue;
}

GetMoney(client)
{
	return GetEntData(client, g_iAccount);
	//return GetEntProp(client, Prop_Send, "m_iAccount");
}

SetMoney(client, amount)
{
	SetEntData(client, g_iAccount, amount);
	//SetEntProp(client, Prop_Send, "m_iAccount", amount);
}

bool:IsValidPlayer(client)
{
	if (!IsClientConnected(client) || client <= 0 || client > MaxClients)
	{
		return false;
	}
	
	return IsClientInGame(client);
}