#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define PLUGIN_VERSION "1.1"

//new Handle:g_hChargeHUD[MAXPLAYERS+1];
new Handle:g_hRechargeHandle[MAXPLAYERS+1];
new Handle:g_hDashReadyHandle[MAXPLAYERS+1];
new bool:g_bClientDash[MAXPLAYERS+1];
new bool:g_bDashReady[MAXPLAYERS+1];
new Float:g_fDashCooldown[MAXPLAYERS+1];
new g_Override[MAXPLAYERS+1];
new g_Charges[MAXPLAYERS+1];
new g_MaxCharges[MAXPLAYERS+1];
new g_TimeUntilGlide[MAXPLAYERS+1];
new g_SoundSlot[MAXPLAYERS+1];
new g_GlideTime[MAXPLAYERS+1];
float SS_MaxDamage[MAXPLAYERS + 1];
float SS_DamageDecayExponent[MAXPLAYERS + 1];
new g_CanGlide[MAXPLAYERS+1];
new g_GlideState[MAXPLAYERS+1];
new Float:g_fGlideSpeed[MAXPLAYERS+1];
new Float:g_fMaxGlideTime[MAXPLAYERS+1];
new Float:g_fVelocity[MAXPLAYERS+1];
new Float:g_fRageCost[MAXPLAYERS+1];
new g_TimeSinceDash[MAXPLAYERS+1];
Handle syncdashhud;
static int dprcnt[MAXPLAYERS+1];
int D_Key[MAXPLAYERS+1];


public Plugin:myinfo = {
   name = "Freak Fortress 2: Air dashes",
   author = "Blinx/Ankhxy/Ankhy edited by artvin and ubermedicfully",
   description = "Allows bosses to dash in the target eye direction",
   version = PLUGIN_VERSION
}

public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], status)
{

}

public OnPluginStart2()
{
	HookEvent("arena_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("player_hurt", OnPlayerHurt);
	syncdashhud = CreateHudSynchronizer();
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
				if (FF2_HasAbility(boss, this_plugin_name, "ff2_airdash_dmg"))
				{
					//PrintToChatAll("Found someone with airdash plugin: %d | %d", boss, client);
					
					g_bClientDash[client] = true;
					g_MaxCharges[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash_dmg", 1, 3);
					g_Charges[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash_dmg", 2, 3);
					g_fVelocity[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash_dmg", 3, 750.0);
					g_Override[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash_dmg", 4, 0);
					g_fRageCost[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash_dmg", 5, 0.0);
					g_fDashCooldown[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash_dmg", 6, 0.25);
					g_SoundSlot[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash_dmg", 7, 1);
					g_CanGlide[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash_dmg", 8, 1);
					g_fGlideSpeed[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash_dmg", 9, -100.0);
					g_TimeUntilGlide[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash_dmg", 10, 15);
					g_fMaxGlideTime[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_airdash_dmg", 11, 3.0);
					dprcnt[client] = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash_dmg", 12, 50); //% charge to start with
					int keyId = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_airdash_dmg", 15);
					if (keyId == 1)
						D_Key[client] = IN_ATTACK;
					else if (keyId == 2)
						D_Key[client] = IN_ATTACK2;
					else if (keyId == 3)
						D_Key[client] = IN_RELOAD;
					else if (keyId == 4)
						D_Key[client] = IN_ATTACK3;
					else
					{
						D_Key[client] = IN_RELOAD;
						PrintCenterText(client, "Invalid key");
					}
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

public Action:t_DashCooldown(Handle:timer, int client)
{
	g_bDashReady[client] = true;
	
	return Plugin_Continue;
}

public int OnPlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client || !attacker || !IsClientInGame(client) || !IsClientInGame(attacker))
		return;
	
	int boss2 = FF2_GetBossIndex(attacker);
	if(boss2 >= 0)
	{
		if(FF2_HasAbility(boss2, this_plugin_name, "ff2_airdash_dmg"))
		{
			 dprcnt[attacker] += FF2_GetAbilityArgument(boss2, this_plugin_name, "ff2_airdash_dmg", 13, 16); //+ percent Charge on hit
			 if(g_Charges[attacker] == g_MaxCharges[attacker])	//Preventing from gaining charge when on max dashes.
			 {
			 	bool nocharge = view_as<bool>(FF2_GetAbilityArgument(boss2, this_plugin_name, "ff2_airdash_dmg", 14, 0));
				if (nocharge)
					dprcnt[attacker] -= FF2_GetAbilityArgument(boss2, this_plugin_name, "ff2_airdash_dmg", 13, 16);	//When arg activated, prevents from gaining percentage
			 }
		}
	}	
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(g_bClientDash[client] && IsPlayerAlive(client))
	{
		new boss = FF2_GetBossIndex(client);
		
		if(boss>=0)
		{
			//If you came here to understand how this works
			//Good fucking luck
			
			new Float:rage = FF2_GetBossCharge(boss, 0);
		
			if(g_GlideState[client] == 1)
			{
				g_TimeSinceDash[client]++;
			}
				
			if((g_bClientDash[client]) && !(buttons & IN_RELOAD) && (g_GlideState[client] == 2) && (g_TimeSinceDash[client] > g_TimeUntilGlide[client]))
			{
				g_GlideState[client] = 0;
			    SS_DamageDecayExponent[client] = 0.65;
			    SS_MaxDamage[client] = 90.0;
				g_GlideTime[client] = 0;
			}
		    if (dprcnt[client] >= 100) 
		    {
		    	if(g_Charges[client] < g_MaxCharges[client])
					g_Charges[client]++;
					
				if(g_Charges[client] == g_MaxCharges[client])
					g_hRechargeHandle[client] = INVALID_HANDLE;
		        dprcnt[client] = 0;
		    }
		    static float delay[36];
			if(g_bClientDash[client] && delay[client]<GetGameTime())
			{
				delay[client] = GetGameTime()+0.25; 
				SetHudTextParams(-1.0, 0.85, 1.01, 0, 255, 0, 255);
				ShowSyncHudText(client, syncdashhud, "Dash Charges (%d / %d) [%d%%] ", g_Charges[client], g_MaxCharges[client], dprcnt[client]);
			}

			if((buttons & D_Key[client]) && (g_bClientDash[client]))
			{			
				if(!(g_GlideState[client]) && (g_Charges[client] > 0) && (rage >= g_fRageCost[client]) && (g_bDashReady[client]))
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
						
					decl Float:position[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

					decl String:s[PLATFORM_MAX_PATH];
					if(FF2_RandomSound("sound_ability",s,PLATFORM_MAX_PATH,boss,g_SoundSlot[client]))
					{
						EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, position, NULL_VECTOR, true, 0.0);
						EmitSoundToAll(s, client, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, position, NULL_VECTOR, true, 0.0);
					}
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

stock bool IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

public bool FF2_GetAbilityArgumentBool(int iBoss, const char[] pluginName, const char[] abilityName, int iArg) {
	return FF2_GetAbilityArgument(iBoss, pluginName, abilityName, iArg, 1) == 1;
}