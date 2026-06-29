#include <sourcemod>

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.1"

new bool:CanPlayerJump[MAXPLAYERS+1];
new Handle:h_ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE;

public OnPluginStart()
	CreateConVar("anti-jumpbug_version", PLUGIN_VERSION, "Current version of Anti-JumpBug", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);

public OnClientPostAdminCheck(client)
	CanPlayerJump[client] = true;

// As explained from http://forums.alliedmods.net/showpost.php?p=843875&postcount=1 on HOW TO HOOK +COMMANDS
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(CanPlayerJump[client] == false && buttons & IN_JUMP)
	{
		buttons &= ~IN_JUMP;
		return Plugin_Continue;
	}
		
	if(IsClientInGame(client) && h_ClientTimer[client] == INVALID_HANDLE && buttons & IN_JUMP && GetEntityFlags(client) & FL_ONGROUND)
	{
		CanPlayerJump[client] = false;
		h_ClientTimer[client] = CreateTimer(0.5, Timer_CanPlayerJump_Reset, client);
	}
	
	return Plugin_Continue;
}
public Action:Timer_CanPlayerJump_Reset(Handle:timer, any:client)
{
		CanPlayerJump[client] = true;
		h_ClientTimer[client] = INVALID_HANDLE;
}

public OnClientDisconnect(client)
{
	if(h_ClientTimer[client] != INVALID_HANDLE)
	{
		KillTimer(h_ClientTimer[client]);
		h_ClientTimer[client] = INVALID_HANDLE;
	}
}