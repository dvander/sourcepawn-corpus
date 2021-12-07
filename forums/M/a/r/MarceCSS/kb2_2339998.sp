#include <sourcemod>

new Handle:Enabled
new Handle:Hknormal
new Handle:Hkheadshot
new Handle:Hkknife
new Handle:Hklimit
new Handle:Aknormal
new Handle:Akheadshot
new Handle:Akknife
new Handle:Aklimit

new String:weaponknife[64] = "knife";

public Plugin:myinfo = 
{
	name = "Kill Bonus (+Armor)",
	author = "Fredd - modified by TnTSCS - Modified by Irq []",
	description = "Gives someone Health and/or Armor on a kill",
	version = "1.1.2",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_kb_version", "1.1.2", "Kill Bonus Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	Enabled		=	CreateConVar("sm_kb_enabled",			"1", 	"Enables - Disables the Kill bonus plugin", FCVAR_NOTIFY);
	Hknormal		=	CreateConVar("sm_kb_health_normal",		"20",	"value # equals the amount of hp to add, when the someone kills someone", FCVAR_NOTIFY);
	Hkheadshot	=	CreateConVar("sm_kb_health_headshot",	"30", 	"value # equals the amount of hp to add, when attacker headshots", FCVAR_NOTIFY);
	Hkknife 		=	CreateConVar("sm_kb_health_knife",		"50",	"value # equals the amount of hp to add, when attacker knifes",FCVAR_NOTIFY);
	Hklimit		= 	CreateConVar("sm_kb_health_limit",		"100",	"value # equals the max hp that the attacker could get", FCVAR_NOTIFY);
	Aknormal		=	CreateConVar("sm_kb_armor_normal",		"10",	"value # equals the amount of armor to add, when the someone kills someone", FCVAR_NOTIFY);
	Akheadshot	=	CreateConVar("sm_kb_armor_headshot",		"20", 	"value # equals the amount of armor to add, when attacker headshots", FCVAR_NOTIFY);
	Akknife 		=	CreateConVar("sm_kb_armor_knife",		"30",	"value # equals the amount of armor to add, when attacker knifes",FCVAR_NOTIFY);
	Aklimit		= 	CreateConVar("sm_kb_armor_limit",		"100",	"value # equals the max armor that the attacker could get", FCVAR_NOTIFY);

	HookEvent("player_death", hookPlayerDie, EventHookMode_Post);
	}
public Action:hookPlayerDie(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id =  GetClientOfUserId(GetEventInt(event, "attacker"));

	if(id == 0)
		return Plugin_Continue;
	
	new bool:headshot = GetEventBool(event, "headshot");
	
	new hknif		= GetConVarInt(Hkknife);
	new hhs		= GetConVarInt(Hkheadshot);
	new hn 			= GetConVarInt(Hknormal);
	new hmax 		= GetConVarInt(Hklimit);
	new CurrentHp	= GetClientHealth(id);
	
	new aknif		= GetConVarInt(Akknife);
	new ahs		= GetConVarInt(Akheadshot);
	new an 			= GetConVarInt(Aknormal);
	new amax 		= GetConVarInt(Aklimit);
	new CurrentAr	= GetClientArmor(id);
	
	new tmpha		= 0;
	
	if(GetConVarInt(Enabled) == 0)
		return Plugin_Continue;
	
	if((CurrentHp == hmax) && (CurrentAr == amax))
		return Plugin_Continue;
	
	if(headshot)
	{
		if (hhs < 0) hhs = 0;
		if (ahs < 0) ahs = 0;
		if((CurrentHp + hhs) > hmax)
		{		
			tmpha = hmax;
		}
		else
		{
			tmpha = CurrentHp + hhs;
		}
		SetEntProp(id, Prop_Send, "m_iHealth", tmpha, 1);
		if((CurrentAr + ahs) > amax)
		{		
			tmpha = amax;
		}
		else
		{
			tmpha = CurrentAr + ahs;
		}
		SetEntProp(id, Prop_Send, "m_ArmorValue", tmpha, 1);
	}
	else
	{
		decl String:wname[64];
		GetEventString(event, "weapon", wname, sizeof(wname));
		
		if(StrEqual(wname, weaponknife, false))
		{
			if (hmax < 0) hmax = 0;
			if (amax < 0) amax = 0;
			if((CurrentHp + hknif) > hmax)
			{		
				tmpha = hmax;
			}
			else
			{
				tmpha = CurrentHp + hknif;
			}
			SetEntProp(id, Prop_Send, "m_iHealth", tmpha, 1);
			if((CurrentAr + aknif) > amax)
			{		
				tmpha = amax;
			}
			else
			{
				tmpha = CurrentAr + aknif;
			}
			SetEntProp(id, Prop_Send, "m_ArmorValue", tmpha, 1);
			return Plugin_Continue;
		}
		
		if (hn < 0) hn = 0;
		if (an < 0) an = 0;
		if((CurrentHp + hn) > hmax)
		{		
			tmpha = hmax;
		}
		else
		{
			tmpha = CurrentHp + hn;
		}
		SetEntProp(id, Prop_Send, "m_iHealth", tmpha, 1);
		if((CurrentAr + an) > amax)
		{		
			tmpha = amax;
		}
		else
		{
			tmpha = CurrentAr + an;
		}
		SetEntProp(id, Prop_Send, "m_ArmorValue", tmpha, 1);
	}	
	return Plugin_Continue;	
}