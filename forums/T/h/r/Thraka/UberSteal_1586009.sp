#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define VERSION "1.2.3"

static Handle:hEnabled;
static Handle:hOverload;

new Float:Player_UberValue[MAXPLAYERS+1]

public Plugin:myinfo =
{
	name = "UberSteal",
	author = "Jaro Vanderheijden, Thraka",
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
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_spawn", PlayerSpawn);
   
	//Follow up cvar
	CreateConVar("ubersteal_version", VERSION, "Version of UberSteal", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public PlayerSpawn(Handle:Event, const String:Name[], bool:Broadcast )
{
	new client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Player_UberValue[client] = 0.0;
}

public PlayerHurt(Handle:Event, const String:Name[], bool:Broadcast )
{
	new victim = GetClientOfUserId(GetEventInt(Event, "userid"));
	Player_UberValue[victim] = 0.0;

	if(TF2_GetPlayerClass(victim) == TFClass_Medic)
	{
		Player_UberValue[victim] = TF2_GetPlayerUberLevel(victim);
	}
	return;
	
}


public EventDeath(Handle:Event, const String:Name[], bool:Broadcast )
{
	new victim = GetClientOfUserId(GetEventInt(Event, "userid"));
	if(TF2_GetPlayerClass(victim) == TFClass_Medic)
	{
		new stealer = GetClientOfUserId(GetEventInt(Event, "attacker"));
		
		if (stealer == 0)
			return;
		
		if(TF2_GetPlayerClass(stealer) != TFClass_Medic)
		{
			LogMessage("Looking for assist");
			stealer = GetClientOfUserId(GetEventInt(Event, "assister"));
	
			if(stealer == 0 || TF2_GetPlayerClass(stealer) != TFClass_Medic)
				return;
			else
				LogMessage("Assister is medic");
		}
		else
			LogMessage("Attacker is medic");
		
		new Float:victimUber = Player_UberValue[victim];
		LogMessage("Uber value of victim is %f", victimUber);
		if(victimUber > 0.0)
		{
			new Float:stealerUber = TF2_GetPlayerUberLevel(stealer);
			victimUber *= GetConVarFloat(hEnabled);
			if(GetConVarBool(hOverload))
				TF2_SetPlayerUberLevel(stealer, stealerUber + victimUber);
			else
				(stealerUber + victimUber > 1.0)? TF2_SetPlayerUberLevel(stealer, 1.0):TF2_SetPlayerUberLevel(stealer, stealerUber + victimUber);
				
			LogMessage("Set uber level");
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
		{
			new Float:value = GetEntPropFloat(index, Prop_Send, "m_flChargeLevel");
			return value;
		}
	}
	return 0.0;
}

public TF2_SetPlayerUberLevel(Client, Float:uberlevel)
{
	new index = GetPlayerWeaponSlot(Client, 1);
	if(index > 0)
	{
		
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel);
	}
}