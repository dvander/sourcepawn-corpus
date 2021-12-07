//Includes:
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3.0"

new bool:ent_remove_notblocked = true
new bool:onlyadmins = false
new Handle:CV_onlyadmins = INVALID_HANDLE
new bool:clientadminstate[MAXPLAYERS + 1]

public Plugin:myinfo = 
{
	name = "L4D Build enabler",
	author = "R-Hehl",
	description = "L4D Build Enabler",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
};
public OnPluginStart()
{
	CreateConVar("sm_buildenabler", PLUGIN_VERSION, "L4D Build Enabler", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("ent_remove", Command_ent_remove)
	RegConsoleCmd("prop_dynamic_create", Command_prop_dynamic_create)
	RegConsoleCmd("prop_physics_create", Command_prop_physics_create)
	RegConsoleCmd("ent_rotate", Command_ent_rotate)
	RegConsoleCmd("give", Command_give)
	
	SetCommandFlags("ent_remove",GetCommandFlags("ent_remove")^FCVAR_CHEAT)
	SetCommandFlags("prop_dynamic_create",GetCommandFlags("prop_dynamic_create")^FCVAR_CHEAT)
	SetCommandFlags("prop_physics_create",GetCommandFlags("prop_physics_create")^FCVAR_CHEAT)
	SetCommandFlags("ent_rotate",GetCommandFlags("ent_rotate")^FCVAR_CHEAT)
	SetCommandFlags("give",GetCommandFlags("give")^FCVAR_CHEAT)
	
	
	CV_onlyadmins = CreateConVar("sm_buildenabler_onlyadmin","1","0 = everybody can build and remove objects, 1 = only admins with the Cheat Flag");
	
	HookConVarChange(CV_onlyadmins,OnCVChangeonlyadmins)
}
public Action:Command_ent_remove(client, args)
{
	if (onlyadmins) /* Check if Admin Flag is Required */
		{
		if (!clientadminstate[client])
			{
			return Plugin_Handled
			}
		}
	if (ent_remove_notblocked)
		{
		CreateTimer(0.5, removeblock) /* I added a timer who alowes removing objects only every 0.5 sec without that i had server crashes if i spam this command */
		ent_remove_notblocked = false
		if (!(GetClientAimTarget(client,true) >= 0))
			{	
			new tmpvalue = GetClientAimTarget(client,false)
			if (tmpvalue >=0)
				{
				decl String:modelname[128];
				GetEntPropString(tmpvalue, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
				if (strcmp(modelname[0], "models/props_doors/checkpoint_door_02.mdl", false) != 0) /* Protects from removing the Checkpoint door 2 because it crashs the Server */
					{
					RemoveEdict(tmpvalue)
					}
				}
			}
		}
	return Plugin_Handled
}
public Action:removeblock(Handle:timer)
{
	ent_remove_notblocked = true
}
public OnCVChangeonlyadmins(Handle:convar, const String:oldValue[], const String:newValue[])
{
	onlyadmins = GetConVarBool(CV_onlyadmins)
}
public OnConfigsExecuted()
{
	onlyadmins = GetConVarBool(CV_onlyadmins)
}

public OnClientPostAdminCheck(client)
{
	if (GetAdminFlag(GetUserAdmin(client),Admin_Cheats,Access_Effective))
	{
		clientadminstate[client] = true
	}
	else
	{
		clientadminstate[client] = false
	}
}
public Action:Command_prop_dynamic_create(client, args)
{
	if (onlyadmins)
	{
	if (!clientadminstate[client])
	{
	return Plugin_Handled
	}
	}
	return Plugin_Continue
}
public Action:Command_prop_physics_create(client, args)
{
	if (onlyadmins)
	{
	if (!clientadminstate[client])
	{
	return Plugin_Handled
	}
	}
	return Plugin_Continue
}
public Action:Command_ent_rotate(client, args)
{
	if (onlyadmins)
	{
	if (!clientadminstate[client])
	{
	return Plugin_Handled
	}
	}
	return Plugin_Continue
}
public Action:Command_give(client, args)
{
	if (onlyadmins)
	{
	if (!clientadminstate[client])
	{
	return Plugin_Handled
	}
	}
	return Plugin_Continue
}




