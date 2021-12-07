#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ff2_ams>
#include <ff2_dynamic_defaults>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2: Dynamic Defeault Settings"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"Changing Dynamic Ability Settings via Stocks"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL "www.skyregiontr.com"

#define MAXPLAYERARRAY MAXPLAYERS+1

#define DYNAMIC "ff2_dynamic_defaults"	// Dynamic Defaults Plugin

/*
 *	Defines "dynamic_jump_change_stats"
 */
#define DJ_STATS "dynamic_jump_change_stats"
#define DJ "dynamic_jump"

/*
 *	Defines "dynamic_weighdown_change_stats"
 */
#define DW_STATS "dynamic_weighdown_change_stats"
#define DW "dynamic_weighdown"

/*
 *	Defines "dynamic_teleport_change_stats"
 */
#define DT_STATS "dynamic_teleport_change_stats"
#define DT "dynamic_teleport"

/*
 *	Defines "dynamic_glide_change_stats"
 */
#define DG_STATS "dynamic_glide_change_stats"
#define DG "dynamic_glide"

/*
 *	Defines "dynamic_speed_change_stats"
 */
#define DSM_STATS "dynamic_speed_change_stats"
#define DSM "dynamic_speed_management"

/*
 *	Defines "dynamic_mobility_management"

#define MOBILITY "dynamic_mobility_management"
int DMM_ButtonMode[MAXPLAYERARRAY];
bool DMM_Switch[MAXPLAYERARRAY];
Handle DMM_Hudhandle;
 */
 
 
public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

public void OnPluginStart2()
{
	
}

/*
public void OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundStart); // for non-arena maps
	
	HookEvent("arena_win_panel", Event_RoundEnd);
	HookEvent("teamplay_round_win", Event_RoundEnd); // for non-arena maps
	
	DMM_Hudhandle = CreateHudSynchronizer();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ClearEverything();
	
	MainBoss_PrepareAbilities();
	CreateTimer(1.0, TimerHookSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerHookSpawn(Handle timer)
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int UserIdx = GetEventInt(event, "userid");
	
	if(IsValidClient(GetClientOfUserId(UserIdx)))
	{
		CreateTimer(0.3, SummonedBoss_PrepareAbilities, UserIdx, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		FF2_LogError("ERROR: Invalid client index. %s:Event_PlayerSpawn()", this_plugin_name);
	}
}

public Action SummonedBoss_PrepareAbilities(Handle timer, int UserIdx)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return;

	int bossClientIdx = GetClientOfUserId(UserIdx);
	if(IsValidClient(bossClientIdx))
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			HookAbilities(bossIdx, bossClientIdx);
		}
	}
	else
	{
		FF2_LogError("ERROR: Unable to find respawned player. %s:SummonedBoss_PrepareAbilities()", this_plugin_name);
	}
}

public void MainBoss_PrepareAbilities()
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
	{
		FF2_LogError("ERROR: Abilitypack called when round is over or when gamemode is not FF2. %s:MainBoss_PrepareAbilities()", this_plugin_name);
		return;
	}
	for(int bossClientIdx = 1; bossClientIdx <= MaxClients; bossClientIdx++)
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			HookAbilities(bossIdx, bossClientIdx);
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearEverything();
}

public void ClearEverything()
{	
	for(int i =1; i<= MaxClients; i++)
	{
		DMM_Switch[i] = true;
		DD_SetDisabled(i, false, false, false, false);
	}
}

public void HookAbilities(int bossIdx, int bossClientIdx)
{
	if(bossIdx >= 0)
	{
		if(FF2_HasAbility(bossIdx, this_plugin_name, MOBILITY))
		{
			//DD_SetDisabled(bossClientIdx, true, false, false, false);
			DMM_Switch[bossClientIdx] = true;
		}
	}
}

public Action OnPlayerRunCmd(int bossClientIdx, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return; // Because some FF2 forks still allow RAGE to be activated when the round is over....
	
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	if(bossIdx >= 0)
	{
		if(FF2_HasAbility(bossIdx, this_plugin_name, MOBILITY))
		{
			char buttonname[32], abilityname[32], HUDStatus[256];
			static int x;
			DMM_ButtonMode[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, MOBILITY, 1, 1);
			switch(DMM_ButtonMode[bossClientIdx])
			{
				case 1:	// special
				{
					DMM_ButtonMode[bossClientIdx] = IN_ATTACK3;
					buttonname = "SPECIAL"; 
				}
				case 2: // reload
				{
					 DMM_ButtonMode[bossClientIdx] = IN_RELOAD; 
					 buttonname = "RELOAD"; 
				}
				case 3: // alt-fire
				{
					DMM_ButtonMode[bossClientIdx] = IN_ATTACK2;
					buttonname = "ALT-FIRE"; 
				}
				case 4:
				{
					DMM_ButtonMode[bossClientIdx] = IN_ATTACK; // attack
					buttonname = "ATTACK";
				}
				case 5: // use (requires server to have "tf_allow_player_use" set to 1)
				{
					DMM_ButtonMode[bossClientIdx] = IN_USE;
					buttonname = "USE"; 
					if(!GetConVarBool(FindConVar("tf_allow_player_use")))
					{
						LogMessage("[ff2_dynamic_settings] WARNING! Boss requires '+use' as part of its abilities, please set 'tf_allow_player_use' to 1 on your server.cfg!");
						buttonname = "RELOAD";
						DMM_ButtonMode[bossClientIdx] = IN_RELOAD;
					}
				}
				default:
				{
					 DMM_ButtonMode[bossClientIdx] = IN_RELOAD; 
					 buttonname = "RELOAD"; 
				}
			}
			
			if(DMM_Switch[bossClientIdx])
			{
				abilityname = "Super Jump";
				
				Handle plugin = FindPlugin("ff2_dynamic_defaults.ff2");
				if(plugin != INVALID_HANDLE)
				{
					Function func = GetFunctionByName(plugin, "DJ_Tick");
					if (func != INVALID_FUNCTION)
					{
						Call_StartFunction(plugin, func);
						Call_PushCell(bossClientIdx);
						Call_PushCell(buttons);
						Call_PushFloat(GetEngineTime());
						Call_Finish();
					}
					else
						PrintToServer("ERROR: Could not find ff2_dynamic_defaults.sp:DT_Tick().");
				}
				else
					PrintToServer("ERROR: Could not find ff2_dynamic_defaults plugin. DT_Tick() failed.");
			}
			else
			{
				abilityname = "Teleport";
				
				Handle plugin = FindPlugin("ff2_dynamic_defaults.ff2");
				if(plugin != INVALID_HANDLE)
				{
					Function func = GetFunctionByName(plugin, "DT_Tick");
					if (func != INVALID_FUNCTION)
					{
						Call_StartFunction(plugin, func);
						Call_PushCell(bossClientIdx);
						Call_PushCell(buttons);
						Call_PushFloat(GetEngineTime());
						Call_Finish();
					}
					else
						PrintToServer("ERROR: Could not find ff2_dynamic_defaults.sp:DT_Tick().");
				}
				else
					PrintToServer("ERROR: Could not find ff2_dynamic_defaults plugin. DT_Tick() failed.");
			}
			
			SetHudTextParams(-1.0, 0.70, 0.01, 255 , 255 , 255, 255);
			Format(HUDStatus, sizeof(HUDStatus), "Press %s to change mobility option to \"%s\"", buttonname, abilityname);
			ShowSyncHudText(bossClientIdx, DMM_Hudhandle, HUDStatus);
			
			if((GetClientButtons(bossClientIdx) & DMM_ButtonMode[bossClientIdx]) && (x % 10 == 0))
			{
				if(DMM_Switch[bossClientIdx])
				{
					x = 0;
					DMM_Switch[bossClientIdx] = false;
					
					
					DJ_SetUsesRemaining(bossClientIdx, 99999);
					DT_SetUsesRemaining(bossClientIdx, 0);
					
					DD_SetDisabled(bossClientIdx, false, true, false, false);
					
					PrintToChatAll("Jump Activated");
				}
				else
				{
					x = 0;
					DMM_Switch[bossClientIdx] = true;
					
					DJ_SetUsesRemaining(bossClientIdx, 0);
					DT_SetUsesRemaining(bossClientIdx, 99999);
					
					DD_SetDisabled(bossClientIdx, true, false, false, false);
					
					PrintToChatAll("Teleport Activated");
				}
			}
			
			
			x++;
		}
	}
}
*/

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Continue; // Because some FF2 forks still allow RAGE to be activated when the round is over....
	
	int bossClientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));
	
	if(!StrContains(ability_name, DJ_STATS))
	{
		DJ_ChangeStatus(bossIdx, bossClientIdx, ability_name);
	}
	if(!StrContains(ability_name, DW_STATS))
	{
		DW_ChangeStatus(bossIdx, bossClientIdx, ability_name);
	}
	if(!StrContains(ability_name, DT_STATS))
	{
		DT_ChangeStatus(bossIdx, bossClientIdx, ability_name);
	}
	if(!StrContains(ability_name, DG_STATS))
	{
		DG_ChangeStatus(bossIdx, bossClientIdx, ability_name);
	}
	if(!StrContains(ability_name, DSM_STATS))
	{
		DSM_ChangeStatus(bossIdx, bossClientIdx, ability_name);
	}
	
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if(client <= 0 || client > MaxClients) return false;
	if(!IsClientInGame(client) || !IsClientConnected(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;		
}

// Dynamic Jump
public void DJ_ChangeStatus(int bossIdx, int bossClientIdx, const char[] ability_name)
{
	if(!FF2_HasAbility(bossIdx, DYNAMIC, DJ))
	{
		char bossname[128];
		FF2_GetBossName(bossIdx, bossname, sizeof(bossname), 1, 0);
		FF2_LogError("The boss \"%s\" does not have the \"%s\" ability. Please remove \"%s\" ability or make sure \"%s\" ability is present", bossname, DJ, ability_name, DJ);
		return;
	}
	
	float DJ_ChargeTime 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 1, -1.0);
	float DJ_Cooldown  		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 2, -1.0);
	float DJ_Multipler  	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 3, -1.0);
	
	int DJ_RemainUses = FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 4, -1);
	float DJ_Cooldown_Until = GetEngineTime() + FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 5, 0.1);
	
	DJ_ChangeFundamentalStats(bossClientIdx, DJ_ChargeTime, DJ_Cooldown, DJ_Multipler);
	if(DJ_RemainUses != -1)
	{
		DJ_SetUsesRemaining(bossClientIdx, DJ_RemainUses);
	}
	DJ_CooldownUntil(bossClientIdx, DJ_Cooldown_Until);
	
	FF2_EmitRandomSound(bossClientIdx, "sound_ds_jump");
}

// Dynamic Weighdown
public void DW_ChangeStatus(int bossIdx, int bossClientIdx, const char[] ability_name)
{
	if(!FF2_HasAbility(bossIdx, DYNAMIC, DW))
	{
		char bossname[128];
		FF2_GetBossName(bossIdx, bossname, sizeof(bossname), 1, 0);
		FF2_LogError("The boss \"%s\" does not have the \"%s\" ability. Please remove \"%s\" ability or make sure \"%s\" ability is present", bossname, DW, ability_name, DW);
		return;
	}
	
	int DW_RemainUses 		= FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 1, -1);
	float DW_Cooldown_Until = GetEngineTime() + FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 2, 0.1);
	
	DW_CooldownUntil(bossClientIdx, DW_Cooldown_Until);
	if(DW_RemainUses != -1)
	{
		DW_SetUsesRemaining(bossClientIdx, DW_RemainUses);
	}
	
	FF2_EmitRandomSound(bossClientIdx, "sound_ds_weighdown");
}

// Dynamic Teleport
public void DT_ChangeStatus(int bossIdx, int bossClientIdx, const char[] ability_name)
{
	if(!FF2_HasAbility(bossIdx, DYNAMIC, DT))
	{
		char bossname[128];
		FF2_GetBossName(bossIdx, bossname, sizeof(bossname), 1, 0);
		FF2_LogError("The boss \"%s\" does not have the \"%s\" ability. Please remove \"%s\" ability or make sure \"%s\" ability is present", bossname, DT, ability_name, DT);
		return;
	}
	
	float DT_ChargeTime 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 1, -1.0);
	float DT_Cooldown  		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 2, -1.0);
	float DT_Stun_Duration 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 3, -1.0);
	
	int DT_RemainUses		= FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 4, -1);
	float DT_Cooldown_Until = GetEngineTime() + FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 5, 0.1);
	
	bool DT_TeleportAbove	= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 6, FF2_GetAbilityArgument(bossIdx, DYNAMIC, DT, 8)));
	bool DT_TeleportSide 	= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 7, FF2_GetAbilityArgument(bossIdx, DYNAMIC, DT, 9)));
	bool DT_TargetTeam		= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 8, FF2_GetAbilityArgument(bossIdx, DYNAMIC, DT, 12)));
	
	DT_ChangeFundamentalStats(bossClientIdx, DT_ChargeTime, DT_Cooldown, DT_Stun_Duration);
	DT_CooldownUntil(bossClientIdx, DT_Cooldown_Until);
	if(DT_RemainUses != -1.0)
	{
		DT_SetUsesRemaining(bossClientIdx, DT_RemainUses);
	}
	DT_SetAboveSide(bossClientIdx, DT_TeleportAbove, DT_TeleportSide);
	DT_SetTargetTeam(bossClientIdx, DT_TargetTeam);
	
	FF2_EmitRandomSound(bossClientIdx, "sound_ds_teleport");
}

// Dynamic Glide
public void DG_ChangeStatus(int bossIdx, int bossClientIdx, const char[] ability_name)
{
	if(!FF2_HasAbility(bossIdx, DYNAMIC, DG))
	{
		char bossname[128];
		FF2_GetBossName(bossIdx, bossname, sizeof(bossname), 1, 0);
		FF2_LogError("The boss \"%s\" does not have the \"%s\" ability. Please remove \"%s\" ability or make sure \"%s\" ability is present", bossname, DG, ability_name, DG);
		return;
	}
	
	float DG_DownwardVel 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 1, -1.0);
	float DG_DecayVel 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 2, -1.0);
	float DG_Cooldown 		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 3, -1.0);
	float DG_MaxDuration 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 4, -1.0);
	
	DG_ChangeFundamentalStats(bossClientIdx,DG_DownwardVel,DG_DecayVel,DG_Cooldown,DG_MaxDuration);
	
	FF2_EmitRandomSound(bossClientIdx, "sound_ds_glide");
}

//Dynamic Speed Management
public void DSM_ChangeStatus(int bossIdx, int bossClientIdx, const char[] ability_name)
{
	if(!FF2_HasAbility(bossIdx, DYNAMIC, DSM))
	{
		char bossname[128];
		FF2_GetBossName(bossIdx, bossname, sizeof(bossname), 1, 0);
		FF2_LogError("The boss \"%s\" does not have the \"%s\" ability. Please remove \"%s\" ability or make sure \"%s\" ability is present", bossname, DSM, ability_name, DSM);
		return;
	}
	
	float DSM_BFB 			= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 1, -1.0);
	float DSM_SniperRifle	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 2, -1.0);
	float DSM_Bow			= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 3, -1.0);
	float DSM_Minigun		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 4, -1.0);
	float DSM_Slowed		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 5, -1.0);
	float DSM_CritCola		= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 5, -1.0);
	float DSM_Whip			= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 6, -1.0);
	float DSM_Dazed			= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 7, -1.0);
	
	bool DSM_DisguiseSpeedCanReduce 	= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 8, FF2_GetAbilityArgument(bossIdx, this_plugin_name, DSM, 17, 0)));
	bool DSM_DisguiseSpeedCanIncrease 	= view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 9, FF2_GetAbilityArgument(bossIdx, this_plugin_name, DSM, 18, 0)));
	
	DSM_SetDisguiseSettings(bossClientIdx, DSM_DisguiseSpeedCanReduce, DSM_DisguiseSpeedCanIncrease);
	DSM_SetModifiers(bossClientIdx, DSM_BFB, DSM_SniperRifle, DSM_Bow, DSM_Minigun, DSM_Slowed, DSM_CritCola, DSM_Whip, DSM_Dazed);
	
	FF2_EmitRandomSound(bossClientIdx, "sound_ds_speed");
}

public void FF2_EmitRandomSound(int bossClientIdx, const char[] keyvalue)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	char sound[PLATFORM_MAX_PATH];
	if(FF2_RandomSound(keyvalue, sound, sizeof(sound), bossIdx))
	{
		EmitSoundToAll(sound);
		EmitSoundToAll(sound);
	}
}