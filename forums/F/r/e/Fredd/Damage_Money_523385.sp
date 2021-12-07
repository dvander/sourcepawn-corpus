/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

new Handle:MnPerHit
new Handle:MnPerKill
new Handle:MnPerHs

new g_iAccount

public Plugin:myinfo = 
{
	name = "Damage Money",
	author = "Fredd",
	description = "",
	version = "1.0",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("damage_money_version", "1.0", "Damage Money Version")
	
	MnPerHit	=	CreateConVar("money_per_hit", "5", "Amount of money per hit")
	MnPerKill	=	CreateConVar("money_per_kill", "100", "Amount of money per kill")
	MnPerHs		= 	CreateConVar("money_per_headshot", "50", "Amount of money per headshot")
	
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount")
	
	
	HookEvent("player_hurt", DamageEvent, EventHookMode_Post)
	HookEvent("player_death", DeathEvent, EventHookMode_Post)
}
public Action:DamageEvent(Handle:event, const String:name[], bool:dontBroadcast){
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	
	new fMoney = (GetMoney(iAttacker) + GetConVarInt(MnPerHit))
	
	if(GetMoney(iAttacker) == 1600 || fMoney > 16000)
	{	
		SetMoney(iAttacker, 16000)
		
		return Plugin_Handled
	}	
	SetMoney(iAttacker, fMoney)
	
	return Plugin_Continue;}
public Action:DeathEvent(Handle:event, const String:name[], bool:dontBroadcast){
	new xAttacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new Hs = GetEventBool(event, "headshot")
	
	new fMoney = (GetMoney(xAttacker) + GetConVarInt(MnPerKill) - 305)
	new HsMoney = (fMoney + GetConVarInt(MnPerHs))
	
	if(GetMoney(xAttacker) == 16000 || fMoney > 16000)
	{
		SetMoney(xAttacker, 16000)
		
		return Plugin_Handled
	}	
	SetMoney(xAttacker, fMoney)
	
	if(Hs)
	{	
		if(HsMoney > 16000)
		{
			SetMoney(xAttacker, 16000)
			
			return Plugin_Handled
		}		
		SetMoney(xAttacker, HsMoney)
	}
	return Plugin_Continue;}
public GetMoney(client)
{
	if(g_iAccount != -1)
	{
		return GetEntData(client, g_iAccount);
	}
	return 0;
}
public SetMoney(client, amount)
{
	if(g_iAccount != -1)
	{
		SetEntData(client, g_iAccount, amount);
	}
}

