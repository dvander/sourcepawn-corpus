#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
//#pragma newdecls required //This only causes issues, and I am in no mood to convert this mess to the new syntax right now.

#define PLUGIN_VERSION "1.0"

	// Normal -> \x01
	// --
	// Sky Green -> \x03
	// --
	// Orange -> \x04
	// --
	// Yellow Green -> \x05
	// --
	// %% -> %

ConVar SuicideCommandsEnabled;

public Plugin myinfo =
{
	name = "[L4D2] Suicide Commands", //TODO: Port to L4D1, and create an engine check so this only works with L4D1 and L4D2.
	author = "TotalChaos, BITFOR.NET", 			  //TODO: Merge L4D1 and L4D2 version into one?
	description = "Allows you to kill yourself when you're incapacitated. Commands: sm_kill, sm_killme, sm_killself, sm_kms, sm_suicide, sm_giveup.", 
	version = PLUGIN_VERSION, 
	//url = "" 
};

public void OnPluginStart() 
{ 
	RegConsoleCmd("sm_kill", KillClient); //The various commands, triggered in the console (sm_*), or in the chat (/*, !*).
	RegConsoleCmd("sm_killme", KillClient);
	RegConsoleCmd("sm_killself", KillClient);
	RegConsoleCmd("sm_kms", KillClient);
	RegConsoleCmd("sm_suicide", KillClient);
	RegConsoleCmd("sm_giveup", KillClient);
	HookEvent("player_incapacitated_start",Event_PlayerIncapacitatedStart); //Don't hook the non _start version because that apparently works for Tanks too.
	HookEvent("player_ledge_grab",Event_PlayerLedgeGrab); //When you start hanging on for dear life.
	
	SuicideCommandsEnabled = CreateConVar("sm_kill_enabled", "1", "If 0, the plugin's commands cannot be used and no messages will be displayed.");
} 

public void OnPluginEnd()
{
	UnhookEvent("player_incapacitated_start", Event_PlayerIncapacitatedStart);
	UnhookEvent("player_ledge_grab", Event_PlayerLedgeGrab); //Unhook the events. Don't want anything weird happening while the plugin's disabled, right?
}


public Action KillClient(int client, int args) //Was the command run? And by who?
{ 
	if (GetConVarBool(SuicideCommandsEnabled))
	{
		bool incap = GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1; //Is the client incapacitated?
		if (incap) //If so, continue.
		{
			SDKHooks_TakeDamage(client, client, client, 100000.0); //Kill the client who ran the command.
		}
		if (!incap) //If not, display a message.
		{
			PrintHintText(client, "Only available while incapacitated or ledge hanging");
			PrintToChat(client, "\x04[SUICIDE] \x01Only available while incapacitated or ledge hanging.");
		}
	}
	return Plugin_Handled; 
} 

public Action Event_PlayerIncapacitatedStart(Handle event, const char[] message, bool dontBroadcast)
{
	if (GetConVarBool(SuicideCommandsEnabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid")); //The incapped player.
		if (!IsFakeClient(client)) //Sending the message to a bot would be useless. It would throw an error, anyway.
		{
		PrintHintText(client, "Type !kill to respawn in a closet"); //Tell the player that they can kill themselves instead of waiting for their teammates.
		PrintToChat(client, "\x04[SUICIDE] \x05Type \x04!kill\x05 to respawn in a closet.");
		}
	}
	return Plugin_Continue; //Carry on.
}

public Action Event_PlayerLedgeGrab(Handle event, const char[] message, bool dontBroadcast)
{
	if (GetConVarBool(SuicideCommandsEnabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid")); //See above.
		if (!IsFakeClient(client))
		{
			PrintHintText(client, "Type !kill to respawn in a closet");
			PrintToChat(client, "\x04[SUICIDE] \x05Type \x04!kill\x05 to respawn in a closet.");
		}
	}
	return Plugin_Continue;
}