#pragma semicolon 1

//FF2_AIRDASH

//arg1 = Max Dash Charges
//arg2 = Dash Recharge Time
//arg3 = Dash Velocity
//arg4 = Velocity Override. 1 = Yes, 2 = Additive.
//arg5 = Rage cost per dash. Leave as 0 to keep it cooldown based.
//arg6 = Cooldown between dashes to prevent spam, recommended to keep low (0.1 to 0.5)
//arg7 = Air time in ticks (Default server tick rate is 66) before a client can dash
//Keep as 0 to allow clients to dash from the ground. Be wary of doing this however
//as they will lose the ability to jump regularly.
//arg8 = Which slot to take sounds from when dashing, set to -1 to keep silent.
//arg9 = Allow boss to glide after a dash
//arg10 = Min Glide speed
//arg11 = Time since dash in ticks until player can glide, I'd avoid setting to 0
//as glides can be easily lost
//arg12 = Max glide time
//Details: You have 1 glide per dash, if you cancel it mid-way, you cannot get it back.

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PLUGIN_VERSION "0.0"

//new Handle:g_hChargeHUD[MAXPLAYERS+1];
new Handle:g_hRechargeHandle[MAXPLAYERS+1];
new Handle:g_hDashReadyHandle[MAXPLAYERS+1];
new bool:g_bClientDash[MAXPLAYERS+1];
new bool:g_bDashReady[MAXPLAYERS+1];
new Float:g_fDashCooldown[MAXPLAYERS+1];
new g_Override[MAXPLAYERS+1];
new g_Charges[MAXPLAYERS+1];
new g_MaxCharges[MAXPLAYERS+1];
new g_AirTime[MAXPLAYERS+1];
new g_MinAirTime[MAXPLAYERS+1];
new g_TimeUntilGlide[MAXPLAYERS+1];
new g_SoundSlot[MAXPLAYERS+1];
new g_GlideTime[MAXPLAYERS+1];
new g_CanGlide[MAXPLAYERS+1];
new g_GlideState[MAXPLAYERS+1];
new Float:g_fGlideSpeed[MAXPLAYERS+1];
new Float:g_fMaxGlideTime[MAXPLAYERS+1];
new Float:g_fVelocity[MAXPLAYERS+1];
new Float:g_fRechargeTimer[MAXPLAYERS+1];
new Float:g_fRageCost[MAXPLAYERS+1];
new g_TimeSinceDash[MAXPLAYERS+1];

public Plugin:myinfo = {
   name = "Freak Fortress 2: Air dashes",
   author = "Blinx/Ankhxy/Ankhy",
   description = "Allows bosses to dash in the target eye direction by pressing jump",
   version = PLUGIN_VERSION
}

public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], status)
{
}

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//PrintToChatAll("Airdash init");
	
	for(new client = 1; client <=MaxClients; client++)
	{
		g_hRechargeHandle[client] = INVALID_HANDLE;
		g_hDashReadyHandle[client] = INVALID_HANDLE;
		g_GlideState[client] = 0;
		
		if (IsValidClient(client))
		{
			new boss = FF2_GetBossIndex(client);
			
			if (boss>=0)
			{
				if (FF2_HasAbility(boss, this_plugin_name, "ff2_airdash"))
				{
					//PrintToChatAll("Found someone with airdash plugin: %d | %d", boss, client);
					
					CreateTimer(9.0, t_EnableDash, client, TIMER_FLAG_NO_MAPCHANGE);
					g_MaxCharges[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash", 1, 3);
					g_Charges[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash", 1, 3);
					g_fRechargeTimer[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash", 2, 3.0);
					g_fVelocity[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash", 3, 750.0);
					g_Override[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash", 4, 0);
					g_fRageCost[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash", 5, 0.0);
					g_fDashCooldown[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash", 6, 0.25);
					g_MinAirTime[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash", 7, 16);
					g_SoundSlot[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash", 8, 1);
					g_CanGlide[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash", 9, 1);
					g_fGlideSpeed[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash", 10, -100.0);
					g_TimeUntilGlide[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash", 11, 15);
					g_fMaxGlideTime[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash", 12, 3.0);
					g_bDashReady[client] = true;
				}
			}
		}
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new client = 1; client <= MaxClients; client++)
	{
		g_bClientDash[client] = false;
	}
}

public Action:t_EnableDash(Handle:timer, int client)
{
	g_bClientDash[client] = true;
	
	return Plugin_Continue;
}

public Action:t_AddCharge(Handle:timer, int client)
{
	if(g_Charges[client] < g_MaxCharges[client])
		g_Charges[client]++;
		
	if(g_Charges[client] == g_MaxCharges[client])
		g_hRechargeHandle[client] = INVALID_HANDLE;
	else
		g_hRechargeHandle[client] = CreateTimer(g_fRechargeTimer[client], t_AddCharge, client);
		
	PrintCenterText(client, "Dash recharged. Current charges: %d", g_Charges[client]);
		
	return Plugin_Continue;
}

public Action:t_DashCooldown(Handle:timer, int client)
{
	g_bDashReady[client] = true;
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsValidClient(client))
	{
		new flags = GetEntityFlags(client);
		new boss = FF2_GetBossIndex(client);
		
		if(boss>=0)
		{
			//If you came here to understand how this works
			//Good fucking luck
			
			new Float:rage = FF2_GetBossCharge(boss, 0);
			
			if(flags & FL_ONGROUND)
			{
				g_AirTime[client] = 0;
				g_GlideState[client] = 0;
				g_GlideTime[client] = 0;
				g_TimeSinceDash[client] = 0;
			}
			else
			{
				g_AirTime[client]++;
			}
			
			if(g_GlideState[client] == 1)
			{
				g_TimeSinceDash[client]++;
			}
				
			if((g_bClientDash[client]) && !(buttons & IN_JUMP) && (g_GlideState[client] == 2) && (g_TimeSinceDash[client] > g_TimeUntilGlide[client]))
			{
				g_GlideState[client] = 0;
				g_GlideTime[client] = 0;
			}
			
			/*if (buttons > 0)
			{
				PrintToChatAll("Glide: %i | Dash: %i", g_GlideState[client], g_bClientDash[client]);
			}*/
			
			if((buttons & IN_JUMP) && (g_bClientDash[client]))
			{
				if(!(g_GlideState[client]) && (g_Charges[client] > 0) && (rage >= g_fRageCost[client]) && (g_bDashReady[client]) && (g_AirTime[client] >= g_MinAirTime[client]))
				{
					decl Float:eyeAng[3];
					decl Float:forwardVector[3];
					decl Float:newVel[3];
					
					GetClientEyeAngles(client, eyeAng);
					
					GetAngleVectors(eyeAng, forwardVector, NULL_VECTOR, NULL_VECTOR);
					NormalizeVector(forwardVector, forwardVector);
					ScaleVector(forwardVector, g_fVelocity[client]);
					
					if(!g_Override[client])
					{
						newVel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
						newVel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
						newVel[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
						
						for(new i = 0; i < 3; i++)
						{
							forwardVector[i] += newVel[i];
						}
					}
					
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, forwardVector);
					
					if(g_fRageCost[client] > 0.0)
					{
						FF2_SetBossCharge(client, 0, rage-g_fRageCost[client]);
					}
					
					g_Charges[client]--;
					
					if((g_CanGlide[client]) && (g_GlideState[client] == 0))
					{
						g_GlideState[client] = 1;
						g_TimeSinceDash[client] = 0;
					}

					g_hDashReadyHandle[client] == CreateTimer(g_fDashCooldown[client], t_DashCooldown, client);
					
					g_bDashReady[client] = false;
					
					if(g_hRechargeHandle[client] == INVALID_HANDLE)
						g_hRechargeHandle[client] = CreateTimer(g_fRechargeTimer[client], t_AddCharge, client);
						
					decl Float:position[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

					decl String:s[PLATFORM_MAX_PATH];
					if(FF2_RandomSound("sound_ability",s,PLATFORM_MAX_PATH,boss,g_SoundSlot[client]))
					{
						EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, position, NULL_VECTOR, true, 0.0);
						EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, position, NULL_VECTOR, true, 0.0);
					}
						
					PrintCenterText(client, "Dashed. Charges left: %d", g_Charges[client]);
				}
				else if((g_GlideState[client]) && (g_CanGlide[client]) && (g_TimeSinceDash[client] > g_TimeUntilGlide[client]) && (g_GlideTime[client] < g_fMaxGlideTime[client]*66))
				{
					decl Float:newVel[3];
					g_GlideState[client] = 2;
					g_GlideTime[client]++;
					
					newVel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
					newVel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
					newVel[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
					
					if(newVel[2] < g_fGlideSpeed[client])
						newVel[2] = g_fGlideSpeed[client];
					
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, newVel);
				}
			}
		}
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}