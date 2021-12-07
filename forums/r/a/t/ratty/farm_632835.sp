#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1a"

public Plugin:myinfo =
{
	name = "TF2 Medic Farming",
	author = "R-Hehl",
	description = "TF2 Medic Farming",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
}

public OnPluginStart()
{

	CreateConVar("sm_tf2_farm_version", PLUGIN_VERSION, "TF2 Medic Farming", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("charge", Command_medup);
	RegConsoleCmd("health", Command_health);
	RegConsoleCmd("godmode", Command_god);
	RegConsoleCmd("mortal", Command_ungod);
	HookEvent("player_spawn", Event_PlayerSpawn);

}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	{
	        CreateTimer(0.25, Timer_PlayerDefDelay, client);
	}
}

public Action:Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	{
	        CreateTimer(0.25, Timer_PlayerDefDelay, client);
	}
}


public Action:Command_medup(client, args)
{
	if (GetEntProp(client, Prop_Send, "m_iClass") == 5)
		TF_SetUberLevel(client, 100);
	else
		ReplyToCommand(client, "[SM] You must be a medic to use this command.");
}


public Action:Command_health(client, args)
	SetEntityHealth(client, 1);
	stock TF_SetUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}



public Action:Timer_PlayerDefDelay(Handle:timer, any:client)
{
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
		PrintToChat(client,"\x01\x04God mode on. Say !mortal if you want to be killable.")
		if (GetEntProp(client, Prop_Send, "m_iClass") == 5)
		{
		if (GetClientTeam(client)==3)
		{
			PrintToChat(client,"\x01\x04Do not be a blue medic.");
			ChangeClientTeam(client, 2);
		}

                TF_SetUberLevel(client, 99);
		}
        }
}


// godmode

public Action:Command_god(client, args)
{
      SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
      PrintToChat(client,"\x01\x04God mode on")
}

public Action:Command_ungod(client, args)
{
       SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
       PrintToChat(client,"\x01\x04God mode off")
}
