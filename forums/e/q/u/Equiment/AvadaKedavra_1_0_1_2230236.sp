/** ~ Spells Plugin ~
* Module 'Avada Kedavra'
* Author: Equiment
**/

/* ~ Includes & Defines ~ */
#include <sourcemod>
#include <sdktools>
/* ~~~~~~~~~~~~~~ */

/* ~ Variables ~ */
new Laser = -1;
new bool:Spell[MAXPLAYERS+1];
new Handle:WandWeapon;
new String:Wand[64];
/* ~~~~~~~~~~~~~ */

/* ~ Information ~ */
public Plugin:myinfo =
{
    name = "Spells: Avada Kedavra",
    author = "Equiment",
    version = "1.0",
	url = "http://steamcommunity.com/id/equiment"
};
/* ~~~~~~~~~~~~~~~ */

/* ~ Main load ~ */
public OnPluginStart()
{
	HookEvent("player_spawn", Spawn);
	HookEvent("weapon_fire", Fire);
	WandWeapon = CreateConVar("sm_avadakedavraweapon", "knife", "Weapon to use as Magic Wand");
	AutoExecConfig(true, "spells/AvadaKedavra");
}
/* ~~~~~~~~~~~~~~ */

/* ~~~~~~~~~~~~~~ */
public OnConfigsExecuted()	GetConVarString(WandWeapon, Wand, sizeof(Wand));
/* ~~~~~~~~~~~~~~ */

/* ~ Map load ~ */
public OnMapStart()
{
	AddFileToDownloadsTable("sound/spells/kedavra.mp3");
	PrecacheSound("spells/kedavra.mp3", true);
	Laser = PrecacheModel("materials/sprites/laserbeam.vmt"); 
}
/* ~~~~~~~~~~~~ */

/* ~ Event > Spawn ~ */
public Action:Spawn(Handle:event, const String:name[], bool:dB)	Spell[GetClientOfUserId(GetEventInt(event, "userid"))] = true;
/* ~~~~~~~~~~~~~~~~~ */

/* ~ Event > Fire ~ */
public Action:Fire(Handle:event, const String:name[], bool:dB)	
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(Spell[client])
	{
		decl String:weapon[64];
		
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		
		if(StrContains(weapon, Wand) != -1)
		{
			new target = GetClientAimTarget(client);
			
			if(0 < target < MaxClients && IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != GetClientTeam(client))
			{
				CreateTimer(0.5, Timer_Slap, any:target);
				CreateTimer(1.2, Timer_Kill, any:target);
				Ray(client);
				
				new Float:pos[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				EmitAmbientSound("spells/kedavra.mp3", pos, client, SNDLEVEL_NORMAL);
				
				Spell[client] = false;
			}
		}
	}
}
/* ~~~~~~~~~~~~~~~~~~ */

/* ~ Timer > Slap ~ */
public Action:Timer_Slap(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		Slap(client, 5);
	}
}
/* ~~~~~~~~~~~~~~~ */

/* ~ Timer > Kill ~ */
public Action:Timer_Kill(Handle:timer, any:client)	if(IsClientInGame(client) && IsPlayerAlive(client))	ForcePlayerSuicide(client);
/* ~~~~~~~~~~~~~~~~ */

/* ~ Stocks > Ray ~ */
stock Ray(client)
{
	decl Float:clientpos[3];
	decl Float:position[3];
	GetPlayerEye(client, position);
	GetClientEyePosition(client, clientpos);
	TE_SetupBeamPoints(clientpos, position, Laser, 0, 0, 0, 0.3, 3.0, 3.0, 10, 0.0, {21, 178, 57, 255}, 30);
	TE_SendToAll(0.0);
}
/* ~~~~~~~~~~~~~~~~ */

/* ~ Stocks > Eye ~ */
stock bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return (true);
	}

	CloseHandle(trace);
	return (false);
}
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}
/* ~~~~~~~~~~~~~~~~~ */

/* ~ Stocks > Slap ~ */
stock Slap(client, slaps)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		for (new i = 1; i <= slaps; i++)
		{
			SlapPlayer(client, 0);
		}
	}
}
/* ~~~~~~~~~~~~~~~~~ */