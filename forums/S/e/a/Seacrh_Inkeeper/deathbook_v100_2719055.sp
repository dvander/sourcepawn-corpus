#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>


Handle cvBookTime = INVALID_HANDLE;
Handle cvUnusualBook = INVALID_HANDLE;

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo = {
   name = "Deathbook",
   author = "Created by Увеселитель",
   description = "Lets players to drop spellbooks on death",
   version = PLUGIN_VERSION,
   url = "https://forums.alliedmods.net/showthread.php?p=2719055"
}

public OnPluginStart()
{
	CreateConVar("sm_deathbook_version", PLUGIN_VERSION,
	"The version of the Deathbook plugin.", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED);
	cvBookTime = CreateConVar("sm_spellbook_time", "15.0", "time before spellbook is removed (seconds)", 0, true, 0.0, true, 60.0);
	cvUnusualBook = CreateConVar("sm_unusualbook", "0.0", "chance of dropping unusual spellbook", 0, true, 0.0, true, 1.0);
	HookEvent("player_death", DropSpellbook);	
}

public Action DropSpellbook(Handle event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	char parameters[64];
	GetEventString(event, "death_flags", parameters, 64);

	if (client <= 0 || client >= MaxClients || attacker <=0 || attacker >= MaxClients) return;
	
	if ((TF2_GetPlayerClass(client) == TFClass_Spy && (StrContains(parameters, "32") != -1))) return; //fake death by deadringer
	
	if (!(CheckCommandAccess(client, "sm_spellbook_override", 0))) return;

	float pos[3];
	GetClientAbsOrigin(client, pos);

	new ent = CreateEntityByName("tf_spell_pickup");
	if (IsValidEntity(ent))
	{	
		if (CheckCommandAccess(client, "sm_unusualbook_override", 0))
		{
			float bookchance = GetConVarFloat(cvUnusualBook);
			float rndchance = GetRandomFloat(0.00, 0.99);
			
			if (rndchance < bookchance) DispatchKeyValue(ent, "Tier", "1");
		}
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);		
		
		HookSingleEntityOutput(ent, "OnPlayerTouch", PlayerPickedUp, true);
		
		float booktime = GetConVarFloat(cvBookTime);
		if (booktime >= 1.0) CreateTimer(booktime, SpellTimeOut, ent);
	}
	
}

public Action SpellTimeOut(Handle timer, any item)
{
	if(IsValidEntity(item))
	{
		RemoveEdict(item);		
	}
}

public void OnEntityCreated(int iEntity, const char[] strClassname)
{
    if (StrEqual(strClassname, "tf_spell_pickup")) SDKHook(iEntity, SDKHook_Spawn, OnBookSpawned);
}

public void OnBookSpawned(int iEntity)
{
    SDKHook(iEntity, SDKHook_StartTouch, OnPickup);
    SDKHook(iEntity, SDKHook_Touch, OnPickup);	
}

public Action OnPickup(int iEntity, int iClient)
{
	if((iClient > 0) && (iClient < MaxClients))
	{
		static char strClassname[32];
		GetEntityClassname(iEntity, strClassname, sizeof(strClassname));
		if (!(CheckCommandAccess(iClient, "sm_bookpickup_override", 0))) return Plugin_Handled;
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public PlayerPickedUp(const char[] output, caller, activator, float delay)
{
	float pos[3];
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);	
	RemoveEdict(caller);
}