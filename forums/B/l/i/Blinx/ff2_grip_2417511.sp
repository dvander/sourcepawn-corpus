/******************************************
	Usage:
	
	"abilityX"
	{
		"name"			"ability_pull"
		"arg0"			"2"				//Use sounds in 2nd slot
		"arg1" 			"1.5"			//Pull speed
		"arg2"			"300.0"			//Upwards force
		"arg3"			"materials/swamp/cable/rope_swamp.vmt" //Material to use for the "rope". DO NOT USE BACKSPACES.
		"buttonmode"	"2"				//Wouldn't change this either no sir
		"plugin_name"	"ff2_grip"
	}
	"abilityX+1"
	{
		"name"			"ability_pull_charges"
		"arg1"			"3"			//amount of grip charges to grant per rage (this is additive to previous charges, not set)
		"plugin_name"	"ff2_grip"
	}

	This ability doesn't filter out grips on the same team, so duo bosses could be funny.
	
	This ability isn't effective at pulling people above you.
	
	Grips have a 1 second timer before they can be used again to prevent rapidfire spam usage (since inputs are put in every game frame)
******************************************/

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new bool:cangrip[MAXPLAYERS+1];
new gripcharges[MAXPLAYERS+1];
new Precache_chain;

public Plugin:myinfo = {
   name = "Freak Fortress 2: Pull",
   author = "Blinx",
   description = "Ability to allow bosses to pull other players towards them.",
   version = "1.0.0"
}

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", OnRoundStart);
}


public OnMapStart()
{
	Precache_chain=PrecacheModel("materials/swamp/cable/rope_swamp.vmt");
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i < MAXPLAYERS; i++)
	{
		cangrip[i] = true;
		gripcharges[i] = 0;
	}
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	new slot=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 0);
	
	if (!strcmp(ability_name,"ability_pull"))
		ability_pull(ability_name,index,slot);
		
	if (!strcmp(ability_name,"ability_pull_charges"))
		ability_pull_charges(ability_name,index);
}

public Action:ability_pull_charges(const String:ability_name[],index)
{
	new client = GetClientOfUserId(FF2_GetBossUserId(index));
	
	gripcharges[client] += FF2_GetAbilityArgument(index,this_plugin_name,ability_name,1,3);
	
	PrintCenterText(client, "Grips remaining: %i (Use with reload)", gripcharges[client]);
}

public Action:ability_pull(const String:ability_name[],index, slot)
{
	new client = GetClientOfUserId(FF2_GetBossUserId(index));

	if (GetClientButtons(client) & 8192) //Reload
	{
		
		if (gripcharges[client] < 1)
			PrintCenterText(client, "No grips.");
			
		if (cangrip[client] == true && gripcharges[client] > 0) //Prolly don't need to check grip charges again but eh
		{
			new Float:pos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			
			new Float:angles[3];
			new Float:eyepos[3];
			GetClientEyeAngles(client, angles);
			GetClientEyePosition(client, eyepos);
				
			TR_TraceRayFilter(eyepos, angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceRayDontHitSelf, client);
			new ent = TR_GetEntityIndex();
			
			if(IsValidClient(ent) && IsPlayerAlive (ent))
			{	
				new String:ArgBuffer[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,3,ArgBuffer,sizeof(ArgBuffer));
				new Float:scaleforce = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 1, 1.5);
				new Float:force  = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 2, 300.0);
				new Float:pos2[3];
				new Float:result[3];	

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos2);

				SubtractVectors(pos, pos2, result); //This is how you produce velocity that pulls one entity to another
				ScaleVector(result, scaleforce);

				result[2] += force; //Necessary to get people off the ground
				
				TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, result); //Fly.... FLLYYYYYY
				SetEntPropFloat(ent, Prop_Data, "m_flGravity", 0.0); //0 gravity so we don't need to make a super complicated formula that factors in gravity and friction. Trust me, I tried, I failed.
				
				CreateTimer(0.25, t_NormalGravity, ent);
				
				cangrip[client] = false;
				gripcharges[client] -= 1;
				
				Precache_chain=PrecacheModel(ArgBuffer);
				pos[2] += 50.0;
				pos2[2] += 40.0;
				new color[4] = {255, 255, 255, 255};
				TE_SetupBeamPoints(pos, pos2, Precache_chain, 0, 0, 3, 0.25, 7.5, 7.5, 1, 5.0, color, 0); //Draw a beam towards the boss and the target
				TE_SendToAll(0.0);
				
				PrintCenterText(client, "Grips remaining: %i (Use with reload)", gripcharges[client]);
				CreateTimer(1.0, t_CanGrip, client); //Anti-spam timer.
				
				if(FF2_RandomSound("sound_ability",ArgBuffer,PLATFORM_MAX_PATH,index,slot)) //Play sounds in the selected slot on a successful grip.
				{
					EmitSoundToAll(ArgBuffer, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
					EmitSoundToAll(ArgBuffer, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, pos, NULL_VECTOR, true, 0.0);
				}
			}
		}
	}
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    if(entity == data)
        return false;

    return true;
}

public Action:t_CanGrip(Handle:timer, client)
{
	if (IsValidClient(client))
		cangrip[client] = true;
}

stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}

public Action:t_NormalGravity(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsPlayerAlive(client)) //I don't know if this check is safe, it depends on whether or not gravity is reset on respawn.
		SetEntPropFloat(client, Prop_Data, "m_flGravity", 1.0);
}