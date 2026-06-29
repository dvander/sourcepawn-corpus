/*
 * [TF2] Take Control of a Bot
 * 
 * Author:  Grognak
 * Version: 1.3
 * Date:    7/8/12
 *
 */

#pragma semicolon 1

#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_NAME         "[TF2] Take Control of a Bot"
#define PLUGIN_AUTHOR       "Grognak"
#define PLUGIN_DESCRIPTION  "Allows players to control bots while they're dead"
#define PLUGIN_VERSION      "1.3"
#define PLUGIN_CONTACT      "grognak.tf2@gmail.com"

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

new bool:bBcEnabled,
	bool:bHideDeath[MAXPLAYERS+1] = {false, ...};

public OnPluginStart()
{
	new Handle:cvarEnabled;
	
	cvarEnabled = CreateConVar("botcontrol_enabled", "1", "Enable the plugin?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("botcontrol_version", PLUGIN_VERSION, "Bot Control's Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	HookConVarChange(cvarEnabled, CvarChange);

	bBcEnabled = GetConVarBool(cvarEnabled);

	AddCommandListener(NewTarget, "spec_next");
	AddCommandListener(NewTarget, "spec_prev");
	AddCommandListener(MedicHook, "voicemenu");

	AddNormalSoundHook(NormalSHook:SoundHook);

	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
}

public OnEntityCreated(iEntity, const String:sClassname[])
{
	if (strcmp(sClassname, "tf_ammo_pack") == 0)
	{
		CreateTimer(0.1, tHandleWeapons, iEntity); // Without a timer, the server crashes
	}
}

public Action:NewTarget(iClient, const String:cmd[], args)
{
	new iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");

	if (!bBcEnabled || !IsValidClient(iTarget) || !IsClientObserver(iClient))
		return Plugin_Continue;

	if (IsFakeClient(iTarget) && GetClientTeam(iClient) == GetClientTeam(iTarget))
	{
		PrintHintText(iClient, "Press [ %voicemenu 0 0% ] to take control of this bot.");
	}

	return Plugin_Continue;
}

public Action:MedicHook(iClient, const String:cmd[], args)
{
	new String:arg1[2],
		String:arg2[2];

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));

	if (!bBcEnabled)
		return Plugin_Continue;

	if (StrEqual(arg1, "0") && StrEqual(arg2, "0"))
	{
		// Player called for Medic
		if (IsClientObserver(iClient) && !IsFakeClient(iClient))
		{
			new iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");

			if (IsValidClient(iTarget) && IsFakeClient(iTarget) 
			&& GetClientTeam(iClient) == GetClientTeam(iTarget))
			{
				new Float:fSpawnTime = GetEntPropFloat(iClient, Prop_Send, "m_flDeathTime");

				new Float:fPlayerOrigin[3],
					Float:fPlayerAngles[3];
				
				new iTargetHealth = GetClientHealth(iTarget);
				new iTargetClass  = _:TF2_GetPlayerClass(iTarget);

				bHideDeath[iTarget] = true;

				GetClientAbsOrigin(iTarget, fPlayerOrigin);
				GetClientAbsAngles(iTarget, fPlayerAngles);
				
				TF2_RespawnPlayer(iClient);
				TF2_SetPlayerClass(iClient, TFClassType:iTargetClass);
				TF2_RegeneratePlayer(iClient);

				// TODO: Make all of the player weapons vanilla?
				/*TF2_RemoveAllWeapons(iClient);

				new iEntity;
				
				for (new i = 0; i < 6; i++)
				{
					iEntity = GetPlayerWeaponSlot(iTarget, i);

					if (iEntity == -1)
						break;

					
				}*/
				
				SetEntityHealth(iClient, iTargetHealth);
				ForcePlayerSuicide(iTarget);
				//AcceptEntityInput(iTarget, "kill");
				TeleportEntity(iClient, fPlayerOrigin, fPlayerAngles, NULL_VECTOR);

				CreateTimer(fSpawnTime, tRespawnPlayer, iTarget);

				return Plugin_Handled;
			}
		}
	}	

	return Plugin_Continue;
}

public Action:PlayerDeath(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!bBcEnabled || !bHideDeath[iClient])
		return Plugin_Continue;

	CreateTimer(0.2, tDestroyRagdoll, iClient);
	
	return Plugin_Handled; // Disable the killfeed notification for takeovers
}  

public Action:SoundHook(iClients[MAXPLAYERS+1], &numClients, String:sample[PLATFORM_MAX_PATH], &iEntity, &iChannel, &Float:fVolume, &iLevel, &iPitch, &iFlags)
{
	if (!bBcEnabled || !IsValidClient(iEntity))
		return Plugin_Continue;
		
	if (StrContains(sample, "pain", false) != -1 && bHideDeath[iEntity])
		return Plugin_Stop;

	return Plugin_Continue;
}

public Action:tDestroyRagdoll(Handle:timer, any:iClient)
{
	new iRagdoll = GetEntPropEnt(iClient, Prop_Send, "m_hRagdoll");

	bHideDeath[iClient] = false;

	if (iRagdoll < 0)
		return;

	AcceptEntityInput(iRagdoll, "kill");
}

public Action:tHandleWeapons(Handle:timer, any:iEntity)
{
		new iRagdoll = FindRagdollClosestToEntity(iEntity, 256.0); 
		new iClient  = GetEntPropEnt(iRagdoll, Prop_Send, "m_iPlayerIndex");

		if (IsValidClient(iClient) && bHideDeath[iClient])
			AcceptEntityInput(iEntity, "kill");
}

public Action:tRespawnPlayer(Handle:timer, any:iClient)
{
	if (bBcEnabled && IsValidClient(iClient) && IsClientInGame(iClient))
		TF2_RespawnPlayer(iClient);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{	
		bBcEnabled = GetConVarBool(convar);
}

// Returns the entity index if found or -1 if there's none within the limit.
stock FindRagdollClosestToEntity(iEntity, Float:fLimit)
{
	new iSearch = -1,
		iReturn = -1;
		
	new Float:fLowest = -1.0,
		Float:fVectorDist,
		Float:fEntityPos[3],
		Float:fRagdollPos[3];

	if (!IsValidEntity(iEntity))
		return iReturn;
		
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityPos);
		
	while ((iSearch = FindEntityByClassname(iSearch, "tf_ragdoll")) != -1)
	{
		GetEntPropVector(iSearch, Prop_Send, "m_vecRagdollOrigin", fRagdollPos);
		
		fVectorDist = GetVectorDistance(fEntityPos, fRagdollPos);

		if (fVectorDist < fLimit &&
		   (fVectorDist < fLowest ||
		    fLowest == -1.0))
		{
			fLowest = fVectorDist;
			iReturn = iSearch;
		}
	}

	return iReturn;
}

stock bool:IsValidClient(iClient) 
{
    if (iClient <= 0 ||
    	iClient > MaxClients ||
    	!IsClientInGame(iClient))
    	return false;
    
    return true;
}
