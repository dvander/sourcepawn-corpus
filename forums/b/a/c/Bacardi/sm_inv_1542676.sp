#include <zombiereloaded>
#include <sdkhooks>

new Handle:cvar_inv_time = INVALID_HANDLE;
new Float:inv_time;

new Handle:players_timer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new bool:used[MAXPLAYERS+1] = {false, ...};
new bool:disapear[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo =
{
	name = "Temporary Invisible",
	description = "Makes player invisible for a while"
};

public OnPluginStart()
{
	RegAdminCmd("sm_inv", admcmd_inv, ADMFLAG_SLAY, "Make yourself invisible for a while only once");

	cvar_inv_time = CreateConVar("sm_inv_time", "10", "Set time how long player can be invisible", 0, true, 0.0);
	inv_time = GetConVarFloat(cvar_inv_time);
	HookConVarChange(cvar_inv_time, CvarChanged);

	HookEvent("player_spawn", spawn);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		OnClientPutInServer(i);
	}
}

public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	inv_time = GetConVarFloat(cvar_inv_time);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	SDKHook(client, SDKHook_WeaponSwitchPost, WeaponSwitchPost);
}

public OnPostThinkPost(client)
{
	disapear[client] ? SetEntProp(client, Prop_Send, "m_iAddonBits", 0):0;
}

public WeaponSwitchPost(client, weapon)
{
	if(disapear[client])
	{
		SetEntityRenderMode(weapon, RenderMode:RENDER_TRANSCOLOR);
		SetEntityRenderColor(weapon, 255, 255, 255, 0);
	}
	else
	{
		SetEntityRenderMode(weapon, RenderMode:RENDER_NORMAL);
	}
}

public Action:admcmd_inv(client, args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] Can't use this command from server input!");
		return Plugin_Handled;
	}

	if(GetClientTeam(client) < 2)
	{
		ReplyToCommand(client, "[SM] Spectators can't use this command!");
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] Dead players can't use this command!");
		return Plugin_Handled;
	}

	// zombie
	if(ZR_IsClientZombie(client))
	{
		ReplyToCommand(client, "[SM] Zombie's can't use this command!");
		return Plugin_Handled;
	}

	if(inv_time == 0.0)
	{
		ReplyToCommand(client, "[SM] This command have disabled for now!");
		return Plugin_Handled;
	}

	if(used[client])
	{
		ReplyToCommand(client, "[SM] You already used this!");
		return Plugin_Handled;
	}

	// If some reason timer still exist, kill it before continue
	if(players_timer[client] != INVALID_HANDLE)
	{
		KillTimer(players_timer[client]);
		players_timer[client] = INVALID_HANDLE;
	}

	used[client] = true;

	players_timer[client] = CreateTimer(inv_time, make_visible, client);

	// make invisible
	SetEntityRenderMode(client, RenderMode:RENDER_NONE);
	disapear[client] = true;
	new activeweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if(IsValidEntity(activeweapon))
	{
		SetEntityRenderMode(activeweapon, RenderMode:RENDER_TRANSCOLOR);
		SetEntityRenderColor(activeweapon, 255, 255, 255, 0);
	}
	

	PrintToChat(client, "\x01[SM] \x05You are now invisible %0.0f sec! Hihihihi....", inv_time);

	return Plugin_Handled;
}


public Action:make_visible(Handle:timer, any:client)
{
	players_timer[client] = INVALID_HANDLE;
	disapear[client] = false;

	// Make player visible
	if(IsClientInGame(client))
	{
		SetEntityRenderMode(client, RenderMode:RENDER_NORMAL);

		if(IsPlayerAlive(client))
		{
			PrintToChat(client, "\x01[SM] \x04You are visible again!");

			new activeweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(activeweapon))
			{
				SetEntityRenderMode(activeweapon, RenderMode:RENDER_NORMAL);
			}
		}
	}
}

public spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	used[client] = false;
	disapear[client] = false;

	if(GetClientTeam(client) > 1)
	{
		SetEntityRenderMode(client, RenderMode:RENDER_NORMAL);

		if(players_timer[client] != INVALID_HANDLE)
		{
			KillTimer(players_timer[client]);
			players_timer[client] = INVALID_HANDLE;
		}

		new activeweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(activeweapon))
		{
			SetEntityRenderMode(activeweapon, RenderMode:RENDER_NORMAL);
		}
	}
}

public OnClientDisconnect(client)
{
	used[client] = false;
	disapear[client] = false;

	if(players_timer[client] != INVALID_HANDLE)
	{
		KillTimer(players_timer[client]);
		players_timer[client] = INVALID_HANDLE;
	}
}