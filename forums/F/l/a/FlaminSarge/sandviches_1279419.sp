#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new pCooldown[MAXPLAYERS+1];
new Handle:cEnable;

#define PLUGIN_NAME              "Unlimited Sandvich"
#define PLUGIN_DESC              "Revival of the Picnics"
#define PLUGIN_AUTHOR            "noodleboy347"
#define PLUGIN_VERSION           "1.2"
#define PLUGIN_CONTACT           "http://www.frozencubes.com"

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
}

public OnPluginStart()
{
	cEnable = CreateConVar("sm_sandvich_enable", "1", "Allow unlimited sandviches");
	CreateConVar("sm_sandvich_version", PLUGIN_VERSION, "Unlimited Sandvich version", FCVAR_NOTIFY);
	RegConsoleCmd("taunt", Command_Taunt);
}

public Action:Command_Taunt(client, args)
{	
	if (client == 0)
	{
		ReplyToCommand(client, "[TF2] Command is in-game only.");
		return Plugin_Handled;
	}
	if(cEnable)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && !pCooldown[client])
		{
			new weaponEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new String:pWeapon[64];
			GetEdictClassname(weaponEnt, pWeapon, sizeof(pWeapon));
			
			if(StrEqual(pWeapon, "tf_weapon_lunchbox", false))
			{
				CreateTimer(4.13, Timer_Cooldown, any:client);
				pCooldown[client] = true;
				CreateTimer(4.4, Timer_Cooldown2, any:client);
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) 
{
	if(cEnable)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && buttons & IN_ATTACK && !pCooldown[client])
		{
			new weaponEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new String:pWeapon[64];
			GetEdictClassname(weaponEnt, pWeapon, sizeof(pWeapon));
			
			if(StrEqual(pWeapon, "tf_weapon_lunchbox", false))
			{
				CreateTimer(4.13, Timer_Cooldown, any:client);
				pCooldown[client] = true;
				CreateTimer(4.4, Timer_Cooldown2, any:client);
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Cooldown(Handle:timer, any:client)
{
	FakeClientCommandEx(client, "use tf_weapon_fists");
}
public Action:Timer_Cooldown2(Handle:timer, any:client)
{
	FakeClientCommandEx(client, "use tf_weapon_lunchbox");
	pCooldown[client] = false;
}