#pragma semicolon 1

#include <sourcemod>

new Handle:Enabled;
new Handle:HsAdd;
new Handle:HpAdd;
new Handle:MaxHp;
new Handle:KnifeAdd;
new String:weaponknife[64] = "knife";

public Plugin:myinfo = 
{
	name = "Kill Bonus",
	author = "Fredd - modified by TnTSCS",
	description = "Gives someone Hp on a kill",
	version = "1.1",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("kb_version", "1.1", "Kill Bonus Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	Enabled		=	CreateConVar("kb_enabled", 	"1", 	"Enables - Disables the Kill bonus plugin", FCVAR_NOTIFY);
	KnifeAdd 	=	CreateConVar("kb_knife",	"50",	"value # equals the amount of hp to add, when attacker knifes",FCVAR_NOTIFY);
	HsAdd		=	CreateConVar("kb_headshot", "30", 	"value #  equals the amount of hp to add, when attacker headshots", FCVAR_NOTIFY);
	HpAdd		=	CreateConVar("kb_hp", 		"20",	"value # equals the amount of hp to add, when the someone kills someone", FCVAR_NOTIFY);
	MaxHp		= 	CreateConVar("kb_maxhp",	"100",	"value # equals the max hp that the attacker could get", FCVAR_NOTIFY);
	
	HookEvent("player_death", hookPlayerDie, EventHookMode_Post);
}
public Action:hookPlayerDie(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id =  GetClientOfUserId(GetEventInt(event, "attacker"));

	if(id == 0)
		return Plugin_Continue;
	
	if(GetUserFlagBits(id) & ADMFLAG_RESERVATION)
	{
		new bool:headshot = GetEventBool(event, "headshot");
		
		new Knife 		= GetConVarInt(KnifeAdd);
		new Hs			= GetConVarInt(HsAdd);
		new Hp 			= GetConVarInt(HpAdd);
		new Max 		= GetConVarInt(MaxHp);
		new CurrentHp	= GetClientHealth(id);
		
		if(GetConVarInt(Enabled) == 0)
			return Plugin_Continue;
		
		if(CurrentHp == Max)
			return Plugin_Continue;
		
		if(headshot)
		{
			if((CurrentHp + Hs) > Max)
			{		
				SetEntProp(id, Prop_Send, "m_iHealth", Max, 1);
				
				PrintToChat(id, "You have been given %i hp, for getting a headshot kill", (Max - CurrentHp));
			} else {
				SetEntProp(id, Prop_Send, "m_iHealth", Hs + CurrentHp, 1);
				
				PrintToChat(id, "You have been given %i hp, for getting a headshot kill", Hs);
			}	
		
		} else if(!headshot)
		{
			decl String:wname[64];
			GetEventString(event, "weapon", wname, sizeof(wname));
			
			if(StrEqual(wname, weaponknife, false))
			{
				if((CurrentHp + Knife) > Max)
				{		
					SetEntProp(id, Prop_Send, "m_iHealth", Max, 1);
					
					PrintToChat(id, "You have been given %i hp, for getting a knife kill", (Max - CurrentHp));
				} else {
					SetEntProp(id, Prop_Send, "m_iHealth", Knife + CurrentHp, 1);
					
					PrintToChat(id, "You have been given %i hp, for getting a knife kill", Knife);
				}
				return Plugin_Continue;
			}
			
			if((CurrentHp + Hp) > Max)
			{		
				SetEntProp(id, Prop_Send, "m_iHealth", Max, 1);
				
				PrintToChat(id, "You have been given %i hp, for getting a kill", (Max - CurrentHp));
			} else {
				SetEntProp(id, Prop_Send, "m_iHealth", Hp + CurrentHp, 1);
				
				PrintToChat(id, "You have been given %i hp, for getting a kill", Hp);
			}	
				
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;	
}