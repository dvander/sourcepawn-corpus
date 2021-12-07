#include <sourcemod>

new Handle:Enabled
new Handle:HsAdd
new Handle:HpAdd
new Handle:MaxHp

public Plugin:myinfo = 
{
	name = "Kill HP",
	author = "SparKinG",
	description = "Gives hp on a kill",
	version = "1.0",
}

public OnPluginStart()
{
	CreateConVar("sm_khp_version", "1.0", "Kill HP", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	Enabled	=	CreateConVar("sm_khp_enabled", 	"1", 	"Disable - 0 | Enable - 1", FCVAR_NOTIFY)
	HsAdd	=	CreateConVar("sm_khp_headshotkill", 	"15", 	"HP VALUE ON A HEADSHOT KILL", FCVAR_NOTIFY)
	HpAdd	=	CreateConVar("sm_khp_normalkill", 		"10",	"HP VALUE ON A NORMAL KILL", FCVAR_NOTIFY)
	MaxHp	= 	CreateConVar("sm_khp_maxhp",	"100",	"MAX HP VALUE", FCVAR_NOTIFY)
	
	HookEvent("player_death", hookPlayerDie, EventHookMode_Post)
}
public Action:hookPlayerDie(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetEventInt(event, "attacker")
	new id =  GetClientOfUserId(attacker)
	new bool:headshot = GetEventBool(event, "headshot")
	
	new Hs	= GetConVarInt(HsAdd)
	new Hp 	= GetConVarInt(HpAdd)
	new Max = GetConVarInt(MaxHp)
	new CurrentHp	= GetClientHealth(id)
	
	if(GetConVarInt(Enabled) == 0)
		return Plugin_Handled
	
	if(CurrentHp == Max)
		return Plugin_Handled
	
	
	if(headshot)
	{
		if((CurrentHp + Hs) > Max)
		{		
			SetEntProp(id, Prop_Send, "m_iHealth", Max, 1)
			
			PrintToChat(id, "You received 15 HP! - Headshot Kill", (Max - CurrentHp))
		} else {
			SetEntProp(id, Prop_Send, "m_iHealth", Hs + CurrentHp, 1)
			
			PrintToChat(id, "You received 15 HP! - Headshot Kill", Hs)
		}	
	
	} else if(!headshot)
	{	
		if((CurrentHp + Hp) > Max)
		{		
			SetEntProp(id, Prop_Send, "m_iHealth", Max, 1)
			
			PrintToChat(id, "You received 10 HP! - Normal Kill", (Max - CurrentHp))
		} else {
			SetEntProp(id, Prop_Send, "m_iHealth", Hp + CurrentHp, 1)
			
			PrintToChat(id, "You received 10 HP! - Normal Kill", Hp)
		}	
			
	}	
	return Plugin_Continue
	}

	
