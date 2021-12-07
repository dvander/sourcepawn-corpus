#pragma semicolon 1
#include <tf2_stocks>
#include <sdkhooks>
#include <cw3-attributes>

#define PLUGIN_VERSION "2.1"
#define SLOTS_MAX               7

public Plugin:myinfo = {
    name = "Custom Weapons 3: YoNer's Attributes",
    author = "YoNer, code repurposed from basic-attributes plugin by MasterOfTheXP and TriggerCommands plugin by Chase",
    description = "Custom attributes for the Custom Weapons 3 plugin.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/member.php?u=251196"
};

/* *** Attributes In This Plugin ***
	-> "trigger command"
       "<command>"
		Upon hitting a player (any team) the selected command (512 chars max) will be executed on the server.
		By default the plugin will replace all instances of the word "{target}" with the target
		player that was hit 
		(I.E. If player "TommyGunn" was hit 'sm_slay {target}' will be executed as 
		'sm_slay "TommyGunn"' on the server)
		

*/

// Attribute values
new bool:Attributed[MAXPLAYERS + 1][SLOTS_MAX + 1];
new bool:TriggerCommand[MAXPLAYERS + 1][SLOTS_MAX + 1];
new String:TriggerCommandText[MAXPLAYERS + 1][SLOTS_MAX + 1][512];

// Plugin start

public OnPluginStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		OnClientPutInServer(i);
	}
}

// Sdkhooks

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

// Attribute processing
public Action:CW3_OnAddAttribute(slot, client, const String:attrib[], const String:plugin[], const String:value[], bool:whileActive)
{
	if (!StrEqual(plugin, "yoners")) return Plugin_Continue;

	new Action:action;
	

	if (StrEqual(attrib, "trigger command"))
	{

		new String:commandtext[1][512];
		strcopy(commandtext[0], sizeof(commandtext[]), value);
		TriggerCommandText[client][slot] = commandtext[0];
		TriggerCommand[client][slot] = true;
	
		action = Plugin_Handled;
	}

	if (!Attributed[client][slot]) Attributed[client][slot] = bool:action;
	
	return action;
}

// Damage Hooks 
public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)

{
	if (attacker <= 0 || attacker > MaxClients) return Plugin_Continue;
	new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");    
	new slot = GetClientSlot(attacker);
	if(weapon > 0 && IsValidEdict(weapon)) 							
	{
		slot = GetWeaponSlot(attacker, weapon); 
	} else 
		{
		if (inflictor > 0 && (inflictor > 0 || inflictor <= MaxClients) && IsValidEdict(inflictor)) // If the inflictor id is over 0 and it's not a client AND it's a valid edict,
		{
			slot = GetWeaponSlot(attacker, inflictor); // Get the slot from the inflictor, as it might be a sentry gun.
		}
	}
	
	if (slot == -1) return Plugin_Continue;
	if (!Attributed[attacker][slot]) return Plugin_Continue;
	
	
	if (TriggerCommand[attacker][slot])
	{
		//Get the command to modify 
		decl String:command[512];
		strcopy(command, sizeof(command), TriggerCommandText[attacker][slot]);

		//Get the targets id
		decl String:id[32];
		Format(id, sizeof(id), "#%d", GetClientUserId(victim));
		
		//replace {target} with the targets id
		ReplaceString(command, sizeof(command), "{target}", id, false);
	 
		//Commmand output debugging line
		//PrintToConsole(attacker,command);
	
		//issue command
		ServerCommand("%s", command);
	}
		
	
	return Plugin_Continue;
}

// Variable resets
public CW3_OnWeaponRemoved(slot, client)
{ 
	Attributed[client][slot] = false;
	TriggerCommand[client][slot] = false;
	TriggerCommandText[client][slot][0] =  '\0';
	
}

stock GetClientSlot(client)
{
	if(!IsClientInGame(client)) return -1;
	if(!IsPlayerAlive(client)) return -1;
	
	new slot = GetWeaponSlot(client, GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon"));
	return slot;
}

stock GetWeaponSlot(client, weapon)
{
	if(client <= 0 || client > MaxClients) return -1;
	
	for(new i = 0; i < SLOTS_MAX; i++)
	{
		if(weapon == GetPlayerWeaponSlot(client, i))
		{
			return i;
		}
	}
	return -1;
}
