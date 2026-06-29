#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define VERSION "1.0"

static Handle:hFactor;

public Plugin:myinfo =
{
	name = "UberSteal",
	author = "Jaro Vanderheijden",
	description = "If a Medic kills or assists in killing another Medic, he gets that Medic's Ubercharge added to his own.",
	version = VERSION,
	url = ""
};

public OnPluginStart()
{
	//Cvars
	hFactor = CreateConVar("sm_ubersteal", "1.0", "Enable/Disable UberSteal. 0 = off, 1 = 100% steal, 0.5 = 50% steal");
   
	//Events
	HookEvent("player_death", EventDeath);
   
	//Follow up cvar
	CreateConVar("ubersteal_version", VERSION, "Version of UberSteal", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public EventDeath(Handle:Event, const String:Name[], bool:Broadcast )
{
	if(GetConVarFloat(hFactor) > 0)
	{
		new victim = GetClientOfUserId(GetEventInt(Event, "userid"));
		if(TF2_GetPlayerClass(victim) == TF2_GetClass("medic"))
		{
			new stealer = GetClientOfUserId(GetEventInt(Event, "attacker"));
			if(TF2_GetPlayerClass(stealer) != TF2_GetClass("medic"))
			{
				stealer = GetClientOfUserId(GetEventInt(Event, "assister"));
				if(TF2_GetPlayerClass(stealer) != TF2_GetClass("medic"))
					return Plugin_Continue;
			}
			new Float:victimUber = TF2_GetPlayerUberLevel(victim);
			if(victimUber > 0.0)
			{
				new Float:stealerUber = TF2_GetPlayerUberLevel(stealer);
				victimUber*=GetConVarFloat(hFactor);
				stealerUber + victimUber > 100.0 ?  TF2_SetPlayerUberLevel(stealer, 100.0) : TF2_SetPlayerUberLevel(stealer, stealerUber + victimUber);
			}
		}
	}
	return Plugin_Continue;
}

public Float:TF2_GetPlayerUberLevel(Client) {
	new index = GetPlayerWeaponSlot(Client, 1);
	if (index > 0) 
	{
		new String:classname[64];
		GetEntityNetClass(index, classname, sizeof(classname));
		if(StrEqual(classname, "CWeaponMedigun"))
			return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100.0;
	}
	return 0.0;
}

public TF2_SetPlayerUberLevel(Client, Float:uberlevel)
{
	new index = GetPlayerWeaponSlot(Client, 1);
	if(index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}