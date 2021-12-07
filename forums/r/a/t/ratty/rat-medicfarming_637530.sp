#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.1a-ratty"

new bool:nobluemeds = true;

public Plugin:myinfo =
{
	name = "TF2 Medic Achivement Farming",
	author = "Ratty / (based on plugin from R-Hehl)",
	description = "TF2 Medic Achievement Farming",
	version = PLUGIN_VERSION,
	url = "http://nom-nom-nom.us"
}

public OnPluginStart()
{

	CreateConVar("sm_tf2_farm_version", PLUGIN_VERSION, "TF2 Medic Farming", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("charge", Command_medup);
	RegConsoleCmd("health", Command_health);
	RegConsoleCmd("godmode", Command_god);
	RegConsoleCmd("mortal", Command_ungod);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("achievement_earned",LogAchievement);

	RegAdminCmd( "sm_nobluemeds",    Nobluemeds_On,      ADMFLAG_CHEATS, "No blue medics" );
	RegAdminCmd( "sm_bluemeds",    Nobluemeds_Off,      ADMFLAG_CHEATS, "Yes blue medics" );
	RegAdminCmd( "sm_botdisguise",    Botspiesdisguise,      ADMFLAG_CHEATS, "Bot spies disguise as red sniper" );
}

stock TF_SetUberLevel(client, uberlevel)
{
        new index = GetPlayerWeaponSlot(client, 1);
        if (index > 0)
                SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}


public Action:Botspiesdisguise( client, args )
{
        new maxplayers = GetMaxClients();

        for (new i = 1; i <= maxplayers; i++)
        {
                if (IsClientInGame(i) && GetEntProp(client, Prop_Send, "m_iClass") == 8 && GetClientTeam(client)==3)
                {
		        TF2_DisguisePlayer(i,TFTeam:2,TFClassType:2);
                }
        }

	return Plugin_Handled;
}

public Action:Nobluemeds_On( client, args )
{
	nobluemeds = true;
	return Plugin_Handled;
}

public Action:Nobluemeds_Off( client, args )
{
	nobluemeds = false;
	return Plugin_Handled;
}

public LogAchievement(Handle:event,const String:name[],bool:dontBroadcast) {

decl String:pname[64];
decl String:steamid[64];

new client = GetEventInt(event, "player");
GetClientAuthString(client, steamid, sizeof(steamid));
GetClientName(client, pname, sizeof(pname));

new achievement = GetEventInt(event, "achievement");

LogMessage("\tachievement\t%s\t%d\t%s",steamid,achievement,pname);
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	TF2_RespawnPlayer(client);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {

    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if ( IsFakeClient(client) ) {
      CreateTimer(1.0, Timer_Respawn, client);
    }
    SetEventInt(event, "revenge", 1);
    return Plugin_Continue;
}


public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	{
	        CreateTimer(0.01, Timer_PlayerDefDelay, client);
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

	return Plugin_Handled;
}

public Action:Command_health(client, args)
{
	SetEntityHealth(client, 1);
	return Plugin_Handled;
}

public Action:Timer_PlayerDefDelay(Handle:timer, any:client)
{
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
		PrintToChat(client,"\x01\x04God mode on. Say !mortal if you want to be killable.")

		if (GetEntProp(client, Prop_Send, "m_iClass") == 5)
		{


		if (GetClientTeam(client)==3 && nobluemeds == true)
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
