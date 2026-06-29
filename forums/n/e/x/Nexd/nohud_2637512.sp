#include <sourcemod>

#define PLUGIN_NEV	"nohud"
#define PLUGIN_LERIAS	"https://forums.alliedmods.net/showthread.php?t=314019"
#define PLUGIN_AUTHOR	"Nexd"
#define PLUGIN_VERSION	"1.0"

#define HIDEHUD    ( 1<<2 )

public Plugin myinfo = 
{
	name = PLUGIN_NEV,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_LERIAS,
	version = PLUGIN_VERSION
};

public void OnPluginStart()
{
	HookEvent("player_spawn", spawn); 
}

public spawn(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
    new userid = GetEventInt(event, "userid"); 
    CreateTimer(0.0, hide_hp, userid); 
} 

public Action:hide_hp(Handle:timer, any:userid) 
{ 
    new client = GetClientOfUserId(userid); 
    if(client != 0 && IsClientInGame(client)) 
    { 
        SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD")|HIDEHUD);
    } 
}