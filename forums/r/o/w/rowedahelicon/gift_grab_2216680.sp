#pragma semicolon 1
     
#include <sourcemod>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <morecolors>
#define REQUIRE_PLUGIN

#define PLUGIN_PREFIX 		"{unusual}[Gift]{default}"
#define PLUGIN_VERSION 		"1.0"
#define PLUGIN_TAG			"GiftGrab"
#define WORLD 0

new LastUsed[MAXPLAYERS+1];
new bool:g_GiftTime[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "Gift Grabber",
	author = "Rowedahelicon",
	description = "Gives a client the ability to go Ghost in order to grab their Halloween gift without interfering with the game.",
	version = PLUGIN_VERSION
}
public OnPluginStart()
    {
		RegConsoleCmd("sm_g", Toggle_Gift);
		RegConsoleCmd("sm_mygift", Toggle_Gift);
		RegConsoleCmd("sm_grabgift", Toggle_Gift);
		RegConsoleCmd("sm_grab", Toggle_Gift);
    }
public OnMapStart()
    {
		PrecacheModel("models/props_halloween/ghost_no_hat.mdl");
		PrecacheSound("vo/halloween_boo1.wav");
		PrecacheSound("vo/halloween_boo2.wav");
		PrecacheSound("vo/halloween_boo3.wav");
		PrecacheSound("vo/halloween_boo4.wav");
		PrecacheSound("vo/halloween_boo5.wav");
		PrecacheSound("vo/halloween_boo6.wav");
		PrecacheSound("vo/halloween_boo7.wav");
    }
public Action:Toggle_Gift(client, args)
	{
		new currentTime = GetTime(); 
		if (currentTime - LastUsed[client] < 5){ CPrintToChat(client, "%s You just used this command, please wait a few seconds!", PLUGIN_PREFIX ); return Plugin_Handled; }

		LastUsed[client] = currentTime; 
	
		if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)){
			TF2_RemoveCondition(client, TFCond_DisguisedAsDispenser);
			TF2_RemoveCondition(client, TFCond_HalloweenGhostMode);
			ServerCommand("sm_slay \"%N\"", client);
			CPrintToChat(client, "%s You are no longer a ghost, enjoy your present!", PLUGIN_PREFIX );
			g_GiftTime[client] = false;
			return Plugin_Handled;
		}else{
			TF2_AddCondition(client, TFCond_HalloweenGhostMode);
			TF2_AddCondition(client, TFCond_DisguisedAsDispenser);
			g_GiftTime[client] = true;
			CPrintToChat(client, "%s You are now a ghost, go find your gift! You'll be back to normal in 1 minute or use !g to disable it when you're done!", PLUGIN_PREFIX);
			CreateTimer(60.0, Timer_EndGrab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Handled;
			}
	}
public Action:Timer_EndGrab(Handle:hTimer, any:iClientId)
	{
		new iClient = GetClientOfUserId(iClientId);
		if(!IsValidClient(iClient))
		return;
		
		if(g_GiftTime[iClient]){
		TF2_RemoveCondition(iClient, TFCond_DisguisedAsDispenser);
		TF2_RemoveCondition(iClient, TFCond_HalloweenGhostMode);
		ServerCommand("sm_slay \"%N\"", iClient);
		CPrintToChat(iClient, "%s You are no longer a ghost, enjoy your present!", PLUGIN_PREFIX );
		g_GiftTime[iClient] = false;
		}
	}
stock bool:IsValidClient(iClient)
	{
		if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
		return false;
		return true;
	}