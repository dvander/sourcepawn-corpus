/*

Example:
"ability1"
    {
        "name" "ff2_customhud"
        "arg0" "0"          // No effect
        "arg1" "path/to/screen/overlay"   	// Path to screenoverlay
        "arg2" "0"  	// Reserved, always set to 0
        "plugin_name" "ff2_customhud"
    }
	
*/
#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
 
#pragma newdecls required

// Hud Element hiding flags (possibly outdated)
#define  	HIDEHUD_WEAPONSELECTION        ( 1<<0 )    // Hide ammo count & weapon selection
#define	    HIDEHUD_FLASHLIGHT            ( 1<<1 )
#define	    HIDEHUD_ALL                    ( 1<<2 )
#define 	HIDEHUD_HEALTH                ( 1<<3 )    // Hide health & armor / suit battery
#define     HIDEHUD_PLAYERDEAD            ( 1<<4 )    // Hide when local player's dead
#define     HIDEHUD_NEEDSUIT            ( 1<<5 )    // Hide when the local player doesn't have the HEV suit
#define     HIDEHUD_MISCSTATUS            ( 1<<6 )    // Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define     HIDEHUD_CHAT                ( 1<<7 )    // Hide all communication elements (saytext, voice icon, etc)
#define     HIDEHUD_CROSSHAIR            ( 1<<8 )    // Hide crosshairs
#define     HIDEHUD_VEHICLE_CROSSHAIR    ( 1<<9 )    // Hide vehicle crosshair
#define     HIDEHUD_INVEHICLE            ( 1<<10 )
#define     HIDEHUD_BONUS_PROGRESS        ( 1<<11 )    // Hide bonus progress display (for bonus map challenges)


char ABILITY_NAME[]="ff2_customhud";

//int i_backupFlags[MAXPLAYERS+1]={0, ...};

public Plugin myinfo=
{
    name = "Freak Fortress 2: Custom Hud",
    description = "Title is self-explanatory",
    author = "Naydef",
    version = "1.0"
}

public void OnPluginStart2()
{
    HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action FF2_OnAbility2(int iIndex, const char[] pluginName, const char[] abilityName, int iStatus)
{   
    return Plugin_Continue;
}

public void Event_RoundStart(Event hEvent, const char[] sName, bool bDontBroadcast)
{
    for(int i=0; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && FF2_GetBossIndex(i)!=-1)
		{
			if(FF2_HasAbility(FF2_GetBossIndex(i), this_plugin_name, ABILITY_NAME))
			{
				char buffer[128];
				FF2_GetAbilityArgumentString(FF2_GetBossIndex(i), this_plugin_name, ABILITY_NAME, 1, buffer, sizeof(buffer));
				if(buffer[0]=='\0')
				{
					Debug("Custom hud buffer is empty(buffer[0]=='\0')! | ");
					LogError("[Freak Fortress 2: Custom Hud] Custom hud buffer is empty(buffer[0]=='\0')!");
				}
				DoOverlay(i, buffer);
				Client_SetHideHud(i, Client_GetHideHud(i)|HIDEHUD_HEALTH);
			}
		}
	}
}

void DoOverlay(int client, const char[] overlay)
{
	int flags=GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", flags);
}

stock bool IsValidClient(int client) // Checks if a client is valid
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}

stock int Client_SetHideHud(int client, int flags)
{
    SetEntProp(client, Prop_Send, "m_iHideHUD", flags);
}

stock int Client_GetHideHud(int client)
{
    return GetEntProp(client, Prop_Send, "m_iHideHUD");
}