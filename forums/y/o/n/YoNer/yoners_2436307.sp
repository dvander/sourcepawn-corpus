#pragma semicolon 1
#include <tf2_stocks>
#include <sdkhooks>
#include <customweaponstf>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = {
    name = "Custom Weapons: YoNer's Attributes",
    author = "YoNer, code repurposed from basic-attributes plugin by MasterOfTheXP and TriggerCommands plugin by Chase",
    description = "Custom attributes for the Custom Weapons plugin.",
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
new bool:HasAttribute[2049];
new bool:TriggerCommand[2049];
new String:TriggerCommandText[2049][512];

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
public Action:CustomWeaponsTF_OnAddAttribute(weapon, client, const String:attrib[], const String:plugin[], const String:value[])
{
	if (!StrEqual(plugin, "yoners")) return Plugin_Continue;

	new Action:action;
	

	if (StrEqual(attrib, "trigger command"))
	{

		new String:commandtext[1][512];
		strcopy(commandtext[0], sizeof(commandtext[]), value);
		TriggerCommandText[weapon] = commandtext[0];
		TriggerCommand[weapon] = true;
	
		action = Plugin_Handled;
	}

	if (!HasAttribute[weapon]) HasAttribute[weapon] = bool:action;
	
	return action;
}

// Damage Hooks 
public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (attacker <= 0 || attacker > MaxClients) return Plugin_Continue;
	new weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");     
	if (weapon == -1) return Plugin_Continue;								
	if (!HasAttribute[weapon]) return Plugin_Continue;
	

	if (TriggerCommand[weapon])
	{
		//Get the command to modify 
		decl String:command[512];
		strcopy(command, sizeof(command), TriggerCommandText[weapon]);

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
public OnEntityDestroyed(Ent)
{ 
	if (Ent <= 0 || Ent > 2048) return;
	HasAttribute[Ent] = false;
	TriggerCommand[Ent] = false;
	TriggerCommandText[Ent][0] =  '\0';
	
}

stock SetAmmo_Weapon(weapon, newAmmo)
{
	new owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(owner, iAmmoTable+iOffset, newAmmo, 4, true);
}