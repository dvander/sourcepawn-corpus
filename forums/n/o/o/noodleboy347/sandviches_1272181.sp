#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new pCooldown[MAXPLAYERS+1];
new Handle:cEnable;

public Plugin:myinfo = 
{
	name = "Unlimited Sandvich",
	author = "noodleboy347",
	description = "Revival of the Picnics",
	version = "1.0",
	url = "http://www.frozencubes.com"
}

public OnPluginStart()
{
	cEnable = CreateConVar("sm_sandvich_enable", "1", "Allow unlimited sandviches");
	CreateConVar("sm_sandvich_version", "1.0", "Unlimited Sandvich version", FCVAR_NOTIFY);
	RegConsoleCmd("taunt", Command_Taunt);
}

public Action:Command_Taunt(client, args)
{	
	if(cEnable)
	{
		new weaponEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new String:pWeapon[64];
		GetEdictClassname(weaponEnt, pWeapon, sizeof(pWeapon));
		
		if(StrEqual(pWeapon, "tf_weapon_lunchbox", false))
		{
			CreateTimer(4.3, Timer_Cooldown, any:client);
			pCooldown[client] = true;
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
				CreateTimer(4.3, Timer_Cooldown, any:client);
				pCooldown[client] = true;
			}
		}
	}
	return Plugin_Continue;
}

public Action:Timer_Cooldown(Handle:timer, any:client)
{
	new healthkit = CreateEntityByName("item_healthkit_small");
	new Float:destination[3];
	GetClientAbsOrigin(client, destination);
	TeleportEntity(healthkit, destination, NULL_VECTOR,NULL_VECTOR);
	DispatchSpawn(healthkit);
	pCooldown[client] = false;
	CreateTimer(0.1, Timer_Remove, any:healthkit);
}

public Action:Timer_Remove(Handle:timer, any:healthkit)
{
	RemoveEdict(healthkit);
}