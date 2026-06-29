#pragma semicolon 1

// ff2_airdash - ffsamu_airdash
// An improved WIP version of the original ff2_airdash by Blinx.
// New:
// -Added:
// -Now passively blocks the powerup drop exploit.
// -Added a new arg3: Delay before dashes become available.
// -Added a configurable HUD:
//   Shows how much charges do you have, along with the key that you must press to use them
//   The HUD's text, position, RGBA colors, recharge message and dashes-enabled message can be changed (arg16 to arg24)
//   

// Planned, not yet implemented:
// -Add a cooldown HUD string (arg3)
// -Add arg25: Conditions to apply when a dash is used. (condition ; duration)

// Ability name: "ff2_airdash_HUD"
// arg1 = Max dash charges
// arg2 = Starting charges
// arg3 = Delay before dashes are available, once they are, a message on your screen appears (arg23)
// arg4 = Dash recharge time, each time a dash is recharged a text on your screen appears (arg24)
// arg5 = Dash velocity
// arg6 = Velocity override. 1 = yes | 2 = additive/relative
// arg7 = Rage cost per dash, leave as 0 to keep it cooldown based.
// arg8 = Cooldown between dashes to prevent spam, recommended to keep low (0.1 to 0.5)
// arg9 = Air time in ticks (Default server tick rate is 66) before a client can dash
// Keep as 0 to allow clients to dash from the ground, if arg15 is 5 the boss will not be able to jump.
// arg10 = Which slot to take sounds from when dashing, set to -1 to keep silent.
// arg11 = Allow boss to glide after a dash? 1 = yes | 0 = no
// arg12 = Minimum glide speed
// arg13 = Time since dash in ticks until player can glide, I'd avoid setting to 0, as glides can be easily lost
// arg14 = Max glide time
// Detail: You have 1 glide per dash, if you cancel it mid-way, you cannot get it back.

// NEW ARGS:
// arg15 = Key to use dash.
// 1 = ATTACK (left click, not recommended)
// 2 = ATTACK2 (right click i guess)
// 3 = RELOAD
// 4 = ATTACK3 (special attack/m3)
// 5 = JUMP
// 6 = DUCK (or ctrl)
// arg16, arg17, arg18 and arg19 = R ; G ; B ; A Values (RGBA Color of the HUD)
// arg20 and arg21 = The HUD's X ; Y position
// arg22 = The HUD's text. Cannot use \n 'cause i somehow broke it lmao
// arg23 = Message displayed on the screen after dashes become available (arg3)
// arg24 = Message displaed on the screen once a dash recharges (arg4)

#include <sourcemod>
#include <tf2items>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <morecolors>

#define PLUGIN_VERSION "1.0"
#define MAXPLAYERARRAY MAXPLAYERS+1

// i figured out i can set the ability name by defining it with strings
// so i don't have to go to the getarguments and change every formattable string
#define SAMU_STRING "ff2_airdash_HUD"
new Handle:g_hRechargeHandle[MAXPLAYERARRAY];
new Handle:g_hDashReadyHandle[MAXPLAYERARRAY];
new bool:g_bClientDash[MAXPLAYERARRAY];
new bool:g_bDashReady[MAXPLAYERARRAY];
new Float:g_fDashCooldown[MAXPLAYERARRAY];
new g_Override[MAXPLAYERARRAY];
new g_Charges[MAXPLAYERARRAY];
new g_MaxCharges[MAXPLAYERARRAY];
new g_AirTime[MAXPLAYERARRAY];
new g_MinAirTime[MAXPLAYERARRAY];
new g_TimeUntilGlide[MAXPLAYERARRAY];
new g_SoundSlot[MAXPLAYERARRAY];
new g_GlideTime[MAXPLAYERARRAY];
new g_CanGlide[MAXPLAYERARRAY];
new g_GlideState[MAXPLAYERARRAY];
new Float:g_fGlideSpeed[MAXPLAYERARRAY];
new Float:g_fMaxGlideTime[MAXPLAYERARRAY];
new Float:g_fVelocity[MAXPLAYERARRAY];
new Float:g_fRechargeTimer[MAXPLAYERARRAY];
new Float:g_fRageCost[MAXPLAYERARRAY];
new g_TimeSinceDash[MAXPLAYERARRAY];
float gfDashXPos[MAXPLAYERARRAY];
float gfDashYPos[MAXPLAYERARRAY];
float g_DelayBeforeEnabled[MAXPLAYERARRAY];
Handle syncdashhud;
int D_Key[MAXPLAYERARRAY];
int DashHUDColors[MAXPLAYERARRAY][4];
char DashHudText[64];
char DashesAvailable[64];
char DashRecharged[64];

public Plugin:myinfo = {
   name = "Freak Fortress 2: Air dash",
   author = "OG Airdash by Blinx, edit by samuu",
   description = "Allows bosses to dash in the direction they are facing - Now includes HUD!",
   version = PLUGIN_VERSION
}

public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], status)
{
	// The FitnessGram™ Pacer Test is a multistage aerobic capacity test that progressively gets more difficult as it continues. The 20 meter pacer test will begin in 30 seconds. Line up at the start. The running speed starts slowly, but gets faster each minute after you hear this signal. [beep] A single lap should be completed each time you hear this sound. [ding] Remember to run in a straight line, and run as long as possible. The second time you fail to complete a lap before the sound, your test is over. The test will begin on the word start. On your mark, get ready, start.
}

public OnPluginStart2()
{
	HookEvent("arena_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	syncdashhud = CreateHudSynchronizer();
	AddCommandListener(Command_DropItem, "dropitem");
}

public Action OnRoundStart(Handle event, const String:name[], bool dontBroadcast)
{
	// PrintToChatAll("Airdash init");
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
				if (FF2_HasAbility(boss, this_plugin_name, SAMU_STRING))
				{
					// PrintToChatAll("Found someone with airdash plugin: %d | %d", boss, client);
					
					g_MaxCharges[client] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 1, 3);
					g_Charges[client] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 2, 3);
					g_DelayBeforeEnabled[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, SAMU_STRING, 3, 5.0);
					g_fRechargeTimer[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, SAMU_STRING, 4, 3.0);
					g_fVelocity[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, SAMU_STRING, 5, 750.0);
					g_Override[client] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 6, 0);
					g_fRageCost[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, SAMU_STRING, 7, 0.0);
					g_fDashCooldown[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, SAMU_STRING, 8, 0.25);
					g_MinAirTime[client] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 9, 16);
					g_SoundSlot[client] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 10, 1);
					g_CanGlide[client] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 11, 1);
					g_fGlideSpeed[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, SAMU_STRING, 12, -100.0);
					g_TimeUntilGlide[client] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 13, 15);
					g_fMaxGlideTime[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, SAMU_STRING, 14, 3.0);
					int keyId = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 15, 3); // Key to use airdash
					if (keyId == 1)
						D_Key[client] = IN_ATTACK;
					else if (keyId == 2)
						D_Key[client] = IN_ATTACK2;
					else if (keyId == 3)
						D_Key[client] = IN_RELOAD;
					else if (keyId == 4)
						D_Key[client] = IN_ATTACK3;
					else if (keyId == 5)
						D_Key[client] = IN_JUMP;
					else if (keyId == 6)
						D_Key[client] = IN_DUCK;
					else
					{
						// in case an invalid option is used, defaults to 3 (reload)
						D_Key[client] = IN_RELOAD;
                        PrintCenterText(client, "INVALID KEY ON CFG - Defaulting to RELOAD...");
					}
					DashHUDColors[client][0] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 16, 255);
			        DashHUDColors[client][1] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 17, 255);
			        DashHUDColors[client][2] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 18, 255);
			        DashHUDColors[client][3] = FF2_GetAbilityArgument(boss, this_plugin_name, SAMU_STRING, 19, 255);
			        gfDashXPos[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, SAMU_STRING, 20, -1.0);
			        gfDashYPos[client] = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, SAMU_STRING, 21, 0.86);
				    FF2_GetAbilityArgumentString(boss, this_plugin_name, SAMU_STRING, 22, DashHudText, sizeof(DashHudText));
				    FF2_GetAbilityArgumentString(boss, this_plugin_name, SAMU_STRING, 23, DashesAvailable, sizeof(DashesAvailable));
				    FF2_GetAbilityArgumentString(boss, this_plugin_name, SAMU_STRING, 24, DashRecharged, sizeof(DashRecharged));
				    
					CreateTimer(g_DelayBeforeEnabled[client], t_EnableDash, client, TIMER_FLAG_NO_MAPCHANGE);

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
      PrintCenterText(client, DashesAvailable);
	
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
		
	 // center message bc still no hud cooldown
	 // however you can edit what it says through args, yay
    PrintCenterText(client, DashRecharged);
		
	return Plugin_Continue;
}

public Action:t_DashCooldown(Handle:timer, int client)
{
	g_bDashReady[client] = true;
	
	return Plugin_Continue;
}

public Action Command_DropItem(int client, const char[] command, int argc)
{
	// Code took from ff2_blockdropitem by Sadao
    // Blocks the powerup drop exploit.
	if(IsValidClient(client))
	{
		int bossidx=FF2_GetBossIndex(client);
		if(bossidx!=-1)
		{
			if(FF2_HasAbility(bossidx, this_plugin_name, SAMU_STRING))
			{
				return Plugin_Handled;
			}
		}
	}
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
			// If you came here to understand how this works
			// Good fucking luck
			
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
				
			if((g_bClientDash[client]) && !(buttons & IN_RELOAD) && (g_GlideState[client] == 2) && (g_TimeSinceDash[client] > g_TimeUntilGlide[client]))
			{
				g_GlideState[client] = 0;
				g_GlideTime[client] = 0;
			}
		    static float delay[36];
			if(g_bClientDash[client] && delay[client]<GetGameTime())
			{
				delay[client] = GetGameTime()+0.25; 
	            SetHudTextParams(gfDashXPos[client], gfDashYPos[client], 1.0, DashHUDColors[client][0], DashHUDColors[client][1], DashHUDColors[client][2], DashHUDColors[client][3]);
	            ShowSyncHudText(client, syncdashhud, DashHudText, g_Charges[client], g_MaxCharges[client]);
                // Thank god, now i don't have to use else if for huds
			}
			
			/*if (buttons > 0)
			{
				PrintToChatAll("Glide: %i | Dash: %i", g_GlideState[client], g_bClientDash[client]);
			}*/
			
			if((buttons & D_Key[client]) && (g_bClientDash[client]))
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