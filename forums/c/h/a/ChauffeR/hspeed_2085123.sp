#pragma semicolon 1 
#include <sourcemod>
#define PLUGIN_VERSION "1.1"
new Float:playerVelocity[3];
new Float:PlayerfSpeed;
new Handle:Hud;
new Handle:cEnabled = INVALID_HANDLE;
new Handle:cHudX = INVALID_HANDLE;
new Handle:cHudY = INVALID_HANDLE;
new Float:HudX;
new Float:HudY;

public Plugin:myinfo = 
{ 
	name = "Show Horizontal Speed", 
	author = "ChauffeR", 
	description = "Show the horizontal speed of the player with a configurable HUD", 
	version = PLUGIN_VERSION, 
	url = "http://hop.tf" 
} 

public OnPluginStart()
{
	CreateConVar("sm_hspeed_version", PLUGIN_VERSION, "Plugin Version of sm_hspeed", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	cEnabled = CreateConVar("sm_hspeed_enabled", "1", "Enable or disable the plugin");
	cHudX = CreateConVar("sm_hspeed_posx", "-1", "X hud position | -1 = center");
	cHudY = CreateConVar("sm_hspeed_posy", "0.89", "Y hud position | -1 = center");
	AutoExecConfig();
	Hud = CreateHudSynchronizer();
	HudX = GetConVarFloat(cHudX);
	HudY = GetConVarFloat(cHudY);
	HookConVarChange(cHudX, OnConVarChange);
	HookConVarChange(cHudY, OnConVarChange);
}

public OnMapStart()
{
	CreateTimer(0.2, ShowSpeed, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == cHudX)
		HudX = GetConVarFloat(cHudX);
	if(hConvar == cHudY)
		HudY = GetConVarFloat(cHudY);
}

public Action:ShowSpeed(Handle:timer)
{
	if(GetConVarInt(cEnabled))
	{
		for (new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", playerVelocity);
				PlayerfSpeed = SquareRoot(playerVelocity[0]*playerVelocity[0] + playerVelocity[1]*playerVelocity[1]);
				SetHudTextParams(HudX, HudY, 0.2, 255, 255, 255, 255);
				ShowSyncHudText(i, Hud, "%i", RoundToZero(PlayerfSpeed));
			}
		}
	}
}