#pragma semicolon 1;

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2"
 
new Handle:ct_enabled = INVALID_HANDLE;
new Handle:ct_chance = INVALID_HANDLE;
 
public Plugin:myinfo =
{
	name = "Class Thief",
	author = "Hello",
	description = "When you kill someone, you become their class",
	version = PLUGIN_VERSION,
};

public OnPluginStart()
{
   HookEvent("player_death", Event_PlayerDeath);
   
   ct_enabled = CreateConVar("ct_enabled", "true", "Active by Default");
   ct_chance = CreateConVar("ct_chance", "100", "100% by Default");
   AutoExecConfig(true, "class_thief");
   
   RegAdminCmd("sm_ct_enable",Command_enable,ADMFLAG_SLAY,"Enable class theft");
   RegAdminCmd("sm_ct_disable",Command_disable,ADMFLAG_SLAY,"Disable class theft");
   RegAdminCmd("sm_ct_chance",Chance_set,ADMFLAG_SLAY,"Change chance of theft");
}
 
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(ct_enabled && (ct_chance > GetRandomInt(0,99)))
	{
   new victim_id = GetEventInt(event, "userid");
   new attacker_id = GetEventInt(event, "attacker");
 
   new victim = GetClientOfUserId(victim_id);
   new attacker = GetClientOfUserId(attacker_id);
   
   
   new oldHealth = GetClientHealth(attacker);
   TF2_RegeneratePlayer(attacker);
   new oldMaxHealth = GetClientHealth(attacker);
   
   TF2_SetPlayerClass(attacker,TFClassType:TF2_GetPlayerClass(victim),0,0);
   TF2_RegeneratePlayer(attacker);
   
   new newMaxHealth = GetClientHealth(attacker);

   new float:newHealth = (float(oldHealth) * float(newMaxHealth)) / float(oldMaxHealth);

   new convertedHealth = RoundFloat(newHealth);
   //if (convertedHealth < 1) {convertedHealth = 1;}

   SetEntityHealth(attacker, convertedHealth);
}
}

public Action:Command_enable(client, args)
{
	ct_enabled=true;
	ReplyToCommand(client,"Class Theft Enabled");
}

public Action:Command_disable(client, args)
{
	ct_enabled=false;
	ReplyToCommand(client,"Class Theft Disabled");
}

public Action:Chance_set(client, args)
{
	new String:arg[128];
	new String:full[256];
 
	GetCmdArgString(full, sizeof(full));
	if((StringToInt(full)>=0)&&(StringToInt(full)<=100))
	{
	ct_chance=StringToInt(full);
	PrintToServer("Theft chance set to %s", full);
    }
	else
	{
	PrintToServer("Invalid number, must be between 0 and 100");	
	}
}