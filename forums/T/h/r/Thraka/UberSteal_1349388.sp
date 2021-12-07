#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define VERSION "1.2.2t"

static Handle:hEnabled;
static Handle:hOverload;

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
	hEnabled = CreateConVar("sm_ubersteal", "1.0", "Amount of Uber you steal. This is a percent. 2.0 for double, 0.5 for half, etc...");
	hOverload = CreateConVar("sm_uberoverload", "0", "Allow Uberstealing past 100% Ubercharge.");
   
	//Events
	HookEvent("player_death", EventDeath);
   
	//Follow up cvar
	CreateConVar("ubersteal_version", VERSION, "Version of UberSteal", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public EventDeath(Handle:Event, const String:Name[], bool:Broadcast )
{
	new victim = GetClientOfUserId(GetEventInt(Event, "userid"));
	if(TF2_GetPlayerClass(victim) == TF2_GetClass("medic"))
	{
		new stealer = GetClientOfUserId(GetEventInt(Event, "attacker"));
		
		if (stealer == 0)
			return;
		
		if(TF2_GetPlayerClass(stealer) != TF2_GetClass("medic"))
		{
			stealer = GetClientOfUserId(GetEventInt(Event, "assister"));
	
			if(stealer == 0 || TF2_GetPlayerClass(stealer) != TF2_GetClass("medic"))
				return;
		}
		new Float:victimUber = TF2_GetPlayerUberLevel(victim);
		if(victimUber > 0.0)
		{
			new Float:stealerUber = TF2_GetPlayerUberLevel(stealer);
			victimUber *= GetConVarFloat(hEnabled);
			if(GetConVarBool(hOverload))
				TF2_SetPlayerUberLevel(stealer, stealerUber + victimUber);
			else
				(stealerUber + victimUber > 100.0)? TF2_SetPlayerUberLevel(stealer, 100.0):TF2_SetPlayerUberLevel(stealer, stealerUber + victimUber);
		}
	}
	return;
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