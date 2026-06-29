#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ff2_ams>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2: SkyRegion Passive Abilities"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"No Buildings, No Packs"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "1"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL "www.skyregiontr.com"

#define MAXPLAYERARRAY MAXPLAYERS+1

/*
 * Defines "passive_removepacks"
 */
#define PACK "passive_removepacks"
bool Remove_sHealth[MAXPLAYERARRAY];			//arg1 - Remove Small Healthpacks? 	1=yes, 0=no
bool Remove_mHealth[MAXPLAYERARRAY];			//arg2 - Remove Medium Healthpacks? 1=yes, 0=no
bool Remove_fHealth[MAXPLAYERARRAY];			//arg3 - Remove Full Healthpacks? 	1=yes, 0=no
bool Remove_sAmmo[MAXPLAYERARRAY];				//arg4 - Remove Small Ammopacks?	1=yes, 0=no
bool Remove_mAmmo[MAXPLAYERARRAY];				//arg5 - Remove Medium Ammopacks?	1=yes, 0=no
bool Remove_fAmmo[MAXPLAYERARRAY];				//arg6 - Remove Full Ammopacks?	 	1=yes, 0=no
bool Remove_Powerup[MAXPLAYERARRAY];			//arg7 - Remove Powerups?	 		1=yes, 0=no


/*
 * Defines "passive_nobuildings"
 */
#define BLD "passive_nobuildings"
bool Remove_bSentry[MAXPLAYERARRAY];			//arg1 - Remove Sentryguns?		1=yes, 0=no
bool Remove_bDispenser[MAXPLAYERARRAY];			//arg2 - Remove Dispensers?		1=yes, 0=no
bool Remove_bTeleporter[MAXPLAYERARRAY];		//arg3 - Remove Teleporters?	1=yes, 0=no

/*
 * Defines "passive_multijump"
 */
#define JUMP "passive_multijump"
int JUMP_MaxCount[MAXPLAYERARRAY];
float JUMP_Velocity[MAXPLAYERARRAY];
int JUMP_LastButtons[MAXPLAYERARRAY];
int JUMP_LastFlags[MAXPLAYERARRAY];
int JUMP_CurJumpCount[MAXPLAYERARRAY];


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
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundStart); // for non-arena maps
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	PrepareAbilities();
}

public void PrepareAbilities()
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
	{
		PrintToServer("[sr_abilities] Abilitypack called when round is over or gamemode is not FF2");
		return;
	}
	for(int bossClientIdx = 1; bossClientIdx <= MaxClients; bossClientIdx++)
	{		
		int bossIdx = FF2_GetBossIndex(bossClientIdx); // Well this seems to be the solution to make it multi-boss friendly
		if(bossIdx >= 0)
		{
			if(FF2_HasAbility(bossIdx, this_plugin_name, PACK))
			{
				//Arguments
				Remove_sHealth[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PACK , 1, 0));
				Remove_mHealth[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PACK , 2, 0));
				Remove_fHealth[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PACK , 3, 0));
				Remove_sAmmo[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PACK , 4, 0));
				Remove_mAmmo[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PACK , 5, 0));
				Remove_fAmmo[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PACK , 6, 0));
				Remove_Powerup[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, PACK , 7, 0));
				
				int entity = -1; 
				while((entity = FindEntityByClassname(entity, "item_*")) != -1)
				{
					static char classname[32];
					GetEntityClassname(entity, classname, sizeof(classname));
					
					if(!strcmp(classname, "item_ammopack_small") && Remove_sAmmo[bossClientIdx])
						AcceptEntityInput(entity, "kill");						
					if(!strcmp(classname, "item_ammopack_medium") && Remove_mAmmo[bossClientIdx])
						AcceptEntityInput(entity, "kill");
					if(!strcmp(classname, "item_ammopack_full") && Remove_fAmmo[bossClientIdx])
						AcceptEntityInput(entity, "kill");						
					if(!strcmp(classname, "item_healthkit_small") && Remove_sHealth[bossClientIdx])
						AcceptEntityInput(entity, "kill");
					if(!strcmp(classname, "item_healthkit_medium") && Remove_mHealth[bossClientIdx])
						AcceptEntityInput(entity, "kill");						
					if(!strcmp(classname, "item_healthkit_full") && Remove_fHealth[bossClientIdx])
						AcceptEntityInput(entity, "kill");						
					if(!strcmp(classname, "item_powerup_*") && Remove_Powerup[bossClientIdx])
						AcceptEntityInput(entity, "kill");
				}
			}
			if(FF2_HasAbility(bossIdx, this_plugin_name, BLD))
			{
				//Arguments
				Remove_bSentry[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, BLD , 1, 0));
				Remove_bDispenser[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, BLD , 2, 0));
				Remove_bTeleporter[bossClientIdx] = view_as<bool>(FF2_GetAbilityArgument(bossIdx, this_plugin_name, BLD , 3, 0));
				
				int entity = -1;
				while((entity = FindEntityByClassname(entity, "obj_*")) != -1)
				{
					static char classname[32];
					GetEntityClassname(entity, classname, sizeof(classname));
					if(!strcmp(classname, "obj_dispenser") && Remove_bDispenser[bossClientIdx])
					{
						SetVariantInt(0); AcceptEntityInput(entity, "SetHealth");
						SetVariantInt(1); AcceptEntityInput(entity, "RemoveHealth");
					}
					if(!strcmp(classname, "obj_sentrygun") && Remove_bSentry[bossClientIdx])
					{
						SetVariantInt(0); AcceptEntityInput(entity, "SetHealth");
						SetVariantInt(1); AcceptEntityInput(entity, "RemoveHealth");
					}
					if(!strcmp(classname, "obj_teleporter") && Remove_bTeleporter[bossClientIdx])
					{
						SetVariantInt(0); AcceptEntityInput(entity, "SetHealth");
						SetVariantInt(1); AcceptEntityInput(entity, "RemoveHealth");
					}
				
				}
			}
			if(FF2_HasAbility(bossIdx, this_plugin_name, JUMP))
			{
				JUMP_MaxCount[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, JUMP , 1, 2);
				JUMP_Velocity[bossClientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, JUMP , 2, 230.0);
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	for(int bossClientIdx = 1; bossClientIdx <= MaxClients; bossClientIdx++)
	{		
		int bossIdx = FF2_GetBossIndex(bossClientIdx); // Well this seems to be the solution to make it multi-boss friendly
		if(bossIdx >= 0)
		{
			if(FF2_HasAbility(bossIdx, this_plugin_name, PACK))
			{
				if(!strcmp(classname, "item_ammopack_small") && Remove_sAmmo[bossClientIdx])
					AcceptEntityInput(entity, "kill");						
				if((!strcmp(classname, "item_ammopack_medium") || !strcmp(classname, "tf_ammo_pack")) && Remove_mAmmo[bossClientIdx])
					AcceptEntityInput(entity, "kill");						
				if(!strcmp(classname, "item_ammopack_full") && Remove_fAmmo[bossClientIdx])
					AcceptEntityInput(entity, "kill");						
				if((!strcmp(classname, "item_healthkit_small") || !strcmp(classname, "item_healthammokit")) && Remove_sHealth[bossClientIdx])
					AcceptEntityInput(entity, "kill");					
				if(!strcmp(classname, "item_healthkit_medium") && Remove_mHealth[bossClientIdx])
					AcceptEntityInput(entity, "kill");						
				if(!strcmp(classname, "item_healthkit_full") && Remove_fHealth[bossClientIdx])
					AcceptEntityInput(entity, "kill");						
				if(!strcmp(classname, "item_powerup_*") && Remove_Powerup[bossClientIdx])
					AcceptEntityInput(entity, "kill");
			}
			if(FF2_HasAbility(bossIdx, this_plugin_name, BLD))
			{
				if(!strcmp(classname, "obj_dispenser") && Remove_bDispenser[bossClientIdx])
				{
					SetVariantInt(0); AcceptEntityInput(entity, "SetHealth");
					SetVariantInt(1); AcceptEntityInput(entity, "RemoveHealth");
					//SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
				}
				if(!strcmp(classname, "obj_sentrygun") && Remove_bSentry[bossClientIdx])
				{
					SetVariantInt(0); AcceptEntityInput(entity, "SetHealth");
					SetVariantInt(1); AcceptEntityInput(entity, "RemoveHealth");
					//SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
				}
				if(!strcmp(classname, "obj_teleporter") && Remove_bTeleporter[bossClientIdx])
				{
					SetVariantInt(0); AcceptEntityInput(entity, "SetHealth");
					SetVariantInt(1); AcceptEntityInput(entity, "RemoveHealth");
					//SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
				}
			}
		}
	}
}

public Action FF2_OnAbility2(int bossClientIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Continue;
	
	int bossIdx = FF2_GetBossIndex(client);
	if(bossIdx >= 0)
	{
		if(FF2_HasAbility(bossIdx, this_plugin_name, JUMP))
		{
			int fCurFlags = GetEntityFlags(client); 
			int fCurButtons = GetClientButtons(client);
			
			if(JUMP_LastFlags[client] & FL_ONGROUND)
			{	
				if(!(fCurFlags & FL_ONGROUND) && !(JUMP_LastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP)
					JUMP_CurJumpCount[client]++;	
			}
			else if(fCurFlags & FL_ONGROUND)
			{
				JUMP_CurJumpCount[client] = 0; 
			}
			else if(!(JUMP_LastButtons[client] & IN_JUMP) && fCurButtons & IN_JUMP)
			{
				if(1 <= JUMP_CurJumpCount[client] <= JUMP_MaxCount[client])
				{						
					JUMP_CurJumpCount[client]++;
					float vVel[3];
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel); 
					
					vVel[2] = JUMP_Velocity[client];
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel); 
				}
			}
			JUMP_LastFlags[client] = fCurFlags;				
			JUMP_LastButtons[client] = fCurButtons;
		}
	}
	return Plugin_Continue;
}

/*
 *	@param client	Checks client valid or not
 *	@return 		true if client is valid
 */
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client) || !IsClientConnected(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

/*
public BLD_Prethink(bossClientIdx)
{
	int entity;
	while((entity = FindEntityByClassname(entity, "obj_sentrygun")) != -1)
	{
		if(Disable_bSentry[bossClientIdx])
			SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
	}
	while((entity = FindEntityByClassname(entity, "obj_dispenser")) != -1)
	{
		if(Disable_bDispenser[bossClientIdx])
			SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
	}
	while((entity = FindEntityByClassname(entity, "obj_teleporter")) != -1)
	{
		if(Disable_bTeleporter[bossClientIdx])
			SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
	}
}
*/