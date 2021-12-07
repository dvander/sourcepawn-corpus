#include <sourcemod>
#include <cstrike>
//CT
new Handle:h_Red = INVALID_HANDLE;
new Handle:h_Green = INVALID_HANDLE;
new Handle:h_Blue = INVALID_HANDLE;
new Handle:h_Alpha = INVALID_HANDLE;
//T
new Handle:h_RedT = INVALID_HANDLE;
new Handle:h_GreenT = INVALID_HANDLE;
new Handle:h_BlueT = INVALID_HANDLE;
new Handle:h_AlphaT = INVALID_HANDLE;
#define PLUGIN_VERSION "1";
public Plugin:myinfo =
{
	name = "Team_Colors",
	author = "ShadowDragon",
	description = "Change Team Colors",
	version = "PLUGIN_VERSION",
	url = "digital-laser.net"
};

public OnPluginStart()
{
	//convar
	h_Red = CreateConVar("sm_Red", "255", "255 = strong 0 = non");
	h_Green = CreateConVar("sm_Green", "255", "255 = strong 0 = non");
	h_Blue = CreateConVar("sm_Blue", "255", "255 = strong 0 = non");
	h_Alpha = CreateConVar("sm_Alpha", "255", "255 = strong 0 = non");
	
	h_RedT = CreateConVar("sm_RedT", "255", "255 = strong 0 = non");
	h_GreenT = CreateConVar("sm_GreenT", "255", "255 = strong 0 = non");
	h_BlueT = CreateConVar("sm_BlueT", "255", "255 = strong 0 = non");
	h_AlphaT = CreateConVar("sm_AlphaT", "255", "255 = strong 0 = non");
	
	HookEvent("player_spawn",SpawnEvent);
}



public Action:SpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	//spawn color
	if (GetClientTeam(client) == CS_TEAM_CT)
	{		
		new Red = GetConVarInt(h_Red);
		new Green = GetConVarInt(h_Green);
		new Blue = GetConVarInt(h_Blue);
		new Alpha = GetConVarInt(h_Alpha);
		SetEntityRenderColor(client, Red, Green, Blue, Alpha);	
	}
		
	if (GetClientTeam(client) == CS_TEAM_T)
	{
		new RedT = GetConVarInt(h_RedT);
		new GreenT = GetConVarInt(h_GreenT);
		new BlueT = GetConVarInt(h_BlueT);
		new AlphaT = GetConVarInt(h_AlphaT);
		SetEntityRenderColor(client, RedT, GreenT, BlueT, AlphaT);	
	}
		

}
	
	
	
	
	
