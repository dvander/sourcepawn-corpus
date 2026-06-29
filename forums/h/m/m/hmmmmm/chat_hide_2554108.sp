#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define    HIDEHUD_WEAPONSELECTION              ( 1<<0  )  // Hide ammo count & weapon selection 
#define    HIDEHUD_FLASHLIGHT                   ( 1<<1  ) 
#define    HIDEHUD_CSGO_ALL                     ( 1<<2  )
#define    HIDEHUD_HEALTH                       ( 1<<3  )  // Hide health & armor / suit battery 
#define    HIDEHUD_CSGO_HEALTH_AND_CROSSHAIR    ( 1<<4  )  // Hide when local player's dead 
#define    HIDEHUD_NEEDSUIT                     ( 1<<5  )  // Hide when the local player doesn't have the HEV suit 
#define    HIDEHUD_MISCSTATUS                   ( 1<<6  )  // Hide miscellaneous status elements (trains, pickup history, death notices, etc) 
#define    HIDEHUD_CHAT                         ( 1<<7  )  // Hide all communication elements (saytext, voice icon, etc) 
#define    HIDEHUD_CROSSHAIR                    ( 1<<8  )  // Hide crosshairs 
#define    HIDEHUD_VEHICLE_CROSSHAIR            ( 1<<9  )  // Hide vehicle crosshair 
#define    HIDEHUD_INVEHICLE                    ( 1<<10 ) 
#define    HIDEHUD_BONUS_PROGRESS               ( 1<<11 )  // Hide bonus progress display (for bonus map challenges) 
#define	   HIDEHUD_CSGO_RADAR                   ( 1<<12 )

#define    HIDEHUD_BITCOUNT 12  


int		g_OldHUD[MAXPLAYERS + 1];
bool	g_bHidden[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Hide chat",
	author = "SlidyBat",
	description = "Enable/Disable chat for players",
	version = "1.0",
	url = "",
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_hidechat", command_togglehud);
}

public Action command_togglehud(int client, int args)
{
	g_bHidden[client] = !g_bHidden[client];
	
	if(g_bHidden[client])
	{
		g_OldHUD[client] = GetEntProp(client, Prop_Send, "m_iHideHUD");
		SetEntProp(client, Prop_Send, "m_iHideHUD", g_OldHUD[client] | HIDEHUD_CHAT); 
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_iHideHUD", g_OldHUD[client]);
	}
	
	ReplyToCommand(client, "[SM] Chat: %s", g_bHidden[client] ? "\x04Enabled" : "\x02Disabled");
	return Plugin_Handled;
}