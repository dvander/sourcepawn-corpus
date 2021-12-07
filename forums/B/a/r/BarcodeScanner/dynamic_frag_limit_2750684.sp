//#define REQUIRED   dunno if this is right
#include <sourcemod>
#include <sdktools>
#include <morecolors>

public Plugin myinfo =
{
    name = "Dynamic frag limit",
    author = "barcodescanner#6775",
    description = "Changes frag limit based on player count and set settings. Check this plugins convars",
    version = "1.3.2",
    url = "none" // 
}
static int players = 0;
int playersB = 0;
//int playerBuffer = 0; for future feature
ConVar maxfrags;
ConVar PluginEnabled = null;
ConVar Fragmultiplyer = null;
ConVar tv_on = null;
ConVar PlayerCap = null;
ConVar OldFrags;
ConVar SecondstoDisable = null;
int tick = 0;
int second = 0;


public void OnPluginStart()
{
 	OldFrags = FindConVar("mp_fraglimit")
 	maxfrags = FindConVar("mp_fraglimit");
 	PluginEnabled = CreateConVar("sm_dynamicfrags_enabled", "1", "(0/1) turns dynamic frag limit on or off");
 	Fragmultiplyer = CreateConVar("sm_dynamicfrags_multiplyer", "3", "( >= 1) how much to add to the frag limit per player (players * this value)");
 	tv_on = CreateConVar("sm_dynamicfrags_tv_on", "0", "(0/1) only exists because i couldnt get it to work of reading tv_enabled. turn on if you are using Sourcetv")
 	PlayerCap = CreateConVar("sm_dynamicfrags_playercap","8","( >= 1) stop adding frags when more tham the set ammount of players join")
 	SecondstoDisable = CreateConVar("sm_dynamicfrags_timecutoff", "500", "( >= 1, set above mp_timelimit to disable )Stop adding to frag limit after this ammount of time in seconds, Doesnt account for the Wainting for players time")
}

public void OnClientConnected(int client)
{
    if (PluginEnabled.IntValue == 1)
    {
      players++     
      if (second <= SecondstoDisable.IntValue)
      {
      	playersB = players
      	CPrintToChatAll("{gold}[SM Dynamic Frags] {green}Added %i {olive}to frags needed to win", Fragmultiplyer.IntValue) 
      }
      else if(SecondstoDisable.IntValue == 0)
       {
      	playersB = players
      	CPrintToChatAll("{gold}[SM Dynamic Frags] {green}Added %i {olive}to frags needed to win", Fragmultiplyer.IntValue) 
      }
    }

}
public void OnClientDisconnect(int client)
{
    if (PluginEnabled.IntValue == 1)
    {
		players--
 		if (second <= SecondstoDisable.IntValue)
 		{
 			playersB = players
 			CPrintToChatAll("{gold}[SM Dynamic Frags] {red}Removed  %i {olive}from frags needed to win", Fragmultiplyer.IntValue)
 		}
 		else if(SecondstoDisable.IntValue == 0)
 		{
 			playersB = players
 			CPrintToChatAll("{gold}[SM Dynamic Frags] {red}Removed  %i {olive}from frags needed to win", Fragmultiplyer.IntValue)
 		}
  
    }
}// find player count

public void OnGameFrame()
{
	++tick
	if (tick >= 67)
	{
		tick = 0
		second++
	}
	
	
		
	if (PluginEnabled.IntValue > 1)
	{
		PluginEnabled.IntValue = 1
	}
	if (PluginEnabled.IntValue < 0)
	{
		PluginEnabled.IntValue = 0
	} // sets the enabled convar to a 'valid' value
	

	if (PluginEnabled.IntValue == 1)
		{
			int newfraglimit = maxfrags.IntValue
			if (playersB <= PlayerCap.IntValue)
			{
				newfraglimit = playersB * Fragmultiplyer.IntValue
				if (tv_on.IntValue >= 1)
				{
					newfraglimit = newfraglimit - Fragmultiplyer.IntValue
				}
			}
			if (playersB > PlayerCap.IntValue)
			{
				newfraglimit = OldFrags.IntValue
			}

			maxfrags.IntValue = newfraglimit
		}
}

public void OnMapStart()
{
	tick = 0
	second = 0
}
public void OnMapEnd()
{
	tick = 0
	second = 0
}

