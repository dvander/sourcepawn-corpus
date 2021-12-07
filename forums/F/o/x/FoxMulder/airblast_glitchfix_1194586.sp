/*
 * Pyro Airblast Fix Exploit  
 *
 * Plugin ask prevents Pyros from lagging other players when they perform the
 * Pyro Airblast glitch.
 * 
 * How does a Pyro perfrom this glitch?
 * 1. Make sure you have the Regular Flamethrower out.
 * 2. Hold Down Primary fire and VERY QUICKLY compression blast.
 * 3. If it worked, your ammo will decrease but there will be no fire particles from your gun. Make sure you are still holding down Primary Fire to make it work.
 * The effect will stop when you run out of ammo. 
 * 
 * Version 1.0
 * - Initial release 
 *
 * Version 1.0.1
 * -Added check on the weapon that the Pyro is holding
 *  making sure that it is the Flamethrower
 * 
 * Version 1.0.2
 * -Corrected late load detection
 * 
 * Version 1.0.3
 * -Reverted changes made in 1.0.1 The extra checks were unneccesarry
 * www.rtdgaming.com
 *
 */
 
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.3"

new Handle:c_Enabled   = INVALID_HANDLE;

new bool:prevButtonAttack2[MAXPLAYERS] = false;
new bool:lateLoaded = false;

public Plugin:myinfo = 
{
	name = "[TF2] Airblast Glitch Fix",
	author = "Fox",
	description = "Prevent's Pyro Airblast glitch",
	version = PLUGIN_VERSION,
	url = "http://www.rtdgaming.com"
}

public OnPluginStart()
{
	CreateConVar("sm_airblast_glitchfix_version", PLUGIN_VERSION, "[TF2] Airblast Glitch Fix", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_Enabled   = CreateConVar("sm_airblast_glitchfix_enable",    "1",        "<0/1> Enable Airblast Glitch Fix");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}

// if the plugin was loaded late we have a bunch of initialization that needs to be done
public APLRes:AskPluginLoad2(Handle:hPlugin, bool:isAfterMapLoaded, String:error[], err_max)
{	
	lateLoaded = isAfterMapLoaded;
}

public OnConfigsExecuted()
{	
	
	/******************
	 * On late load   *
	 ******************/
	if (lateLoaded)
	{
		for(new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i))
			{
				SDKHook(i,	SDKHook_PreThink, 	OnPreThink);
			}
		}
		
		lateLoaded = false;
	}
}

public OnPreThink(client)
{
	if(!GetConVarInt(c_Enabled))
		return;
	
	if(TF2_GetPlayerClass(client) != TFClass_Pyro)
		return;
	
	new iButtons = GetClientButtons(client);
	
	//Glitch detected
	if(prevButtonAttack2[client] && iButtons & IN_ATTACK && !(iButtons & IN_ATTACK2))
	{
		iButtons &= ~IN_ATTACK;
		SetEntProp(client, Prop_Data, "m_nButtons", iButtons);
		//PrintToChat(client, "Glitch detected!");
	}
	
	if(iButtons & IN_ATTACK && iButtons & IN_ATTACK2)
		prevButtonAttack2[client] = true;
	
	if(!(iButtons & IN_ATTACK2))
		prevButtonAttack2[client] = false;
}