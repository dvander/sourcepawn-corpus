/*
 * SourceMod Hosties Project
 * by: databomb & dataviruset
 *
 * This file is part of the SM Hosties project.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */
 
// Sample Last Request Plugin: Shotgun Wars!
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
// Make certain the lastrequest.inc is last on the list
#include <hosties>
#include <lastrequest>
#include <emitsoundany>
#include <colors>
#pragma semicolon 1
 
#define PLUGIN_VERSION "1.0"
#define DMG_HEADSHOT		(1 << 30)
#define LoopClients(%1) for (int %1 = 1; %1 <= MaxClients; %1++) if (IsClientInGame(%1))
new bool:	g_bIsCSGO;
 
 
// This global will store the index number for the new Last Request
new g_LREntryNum;
 
new String:g_sLR_Name[64];
 
new Handle:gH_Timer_Countdown = INVALID_HANDLE;
 
new bool:bAllCountdownsCompleted = false;
 

new			g_iTrailSprite;
new			g_iBloodDecal;
new Handle:	g_hThrownKnives;
new Handle:	g_hTimerLR[MAXPLAYERS+1];
new bool:	g_bHeadshot[MAXPLAYERS+1];

new Float:	g_Cvar_fVelocity;
new Float:	g_Cvar_fDamage;
new Float:	g_Cvar_fHSDamage;
new Float:	g_Cvar_fModelScale;
new Float:	g_Cvar_fGravity;
new Float:	g_Cvar_fElasticity;
new Float:	g_Cvar_fMaxLifeTime;
new bool:	g_Cvar_bTrails;

new bool:allow[MAXPLAYERS+1] = false;
new colourt[MAXPLAYERS+1];
new colourct[MAXPLAYERS+1];

public Plugin:myinfo =
{
        name = "Last Request: Throwing Knives",
        description = "edited by dkzinho",
        version = PLUGIN_VERSION,
        url = "sourcemod.net"
};
 
public OnPluginStart()
{
	g_bIsCSGO = Func_IsCSGO();
	// Load the name in default server language
	Format(g_sLR_Name, sizeof(g_sLR_Name), "Throwing Knives", LANG_SERVER);
	decl Handle:hCvar;

	hCvar = CreateConVar("throwingknives_velocity", "1900", "Knife velocity.");
	HookConVarChange(hCvar, OnVelocityChange);
	g_Cvar_fVelocity = GetConVarFloat(hCvar);
	hCvar = CreateConVar("throwingknives_damage", "20", "Knife Damage.", _, true, 0.0);
	HookConVarChange(hCvar, OnDamageChange);
	g_Cvar_fDamage = GetConVarFloat(hCvar);
	hCvar = CreateConVar("throwingknives_hsdamage", "80", "Damage on HeadShot.", _, true, 0.0);
	HookConVarChange(hCvar, OnHSDamageChange);
	g_Cvar_fHSDamage = GetConVarFloat(hCvar);
	hCvar = CreateConVar("throwingknives_modelscale", "1.0", "Model Scale (1.0 - Normal)", _, true, 0.0);
	HookConVarChange(hCvar, OnModelScaleChange);
	g_Cvar_fModelScale = GetConVarFloat(hCvar);
	hCvar = CreateConVar("throwingknives_gravity", "1.0", "Knife Gravity (1.0 - Normal)", _, true, 0.0);
	HookConVarChange(hCvar, OnGravityChange);
	g_Cvar_fGravity = GetConVarFloat(hCvar);
	hCvar = CreateConVar("throwingknives_elasticity", "0.2", "Knife Elasticity", _, true, 0.0);
	HookConVarChange(hCvar, OnElasticityChange);
	g_Cvar_fElasticity = GetConVarFloat(hCvar);
	hCvar = CreateConVar("throwingknives_maxlifetime", "1.5", "Max Life Time (float)", _, true, 1.0, true, 30.0);
	HookConVarChange(hCvar, OnMaxLifeTimeChange);
	g_Cvar_fMaxLifeTime = GetConVarFloat(hCvar);
	hCvar = CreateConVar("throwingknives_trails", "1", "Trails ?", _, true, 0.0, true, 1.0);
	HookConVarChange(hCvar, OnTrailsChange);
	g_Cvar_bTrails = GetConVarBool(hCvar);
	AutoExecConfig(true, "throwingkniveslr");

	CloseHandle(hCvar);
	g_hThrownKnives = CreateArray();
	
	HookEvent("weapon_fire", Event_WeaponFire);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	HookEvent("round_end", OnRoundEnd);
	for(new idx = 1; idx <= MaxClients ; idx++)
	{
		if(IsClientInGame(idx))
		{
			SDKHook(idx, SDKHook_WeaponCanUse, OnWeaponDecideUse);
		}
	}
}

public OnVelocityChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[])		g_Cvar_fVelocity = GetConVarFloat(hCvar);
public OnDamageChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[])			g_Cvar_fDamage = GetConVarFloat(hCvar);
public OnHSDamageChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[])		g_Cvar_fHSDamage = GetConVarFloat(hCvar);
public OnModelScaleChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[])		g_Cvar_fModelScale = GetConVarFloat(hCvar);
public OnGravityChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[])			g_Cvar_fGravity = GetConVarFloat(hCvar);
public OnElasticityChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[])		g_Cvar_fElasticity = GetConVarFloat(hCvar);
public OnMaxLifeTimeChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[])	g_Cvar_fMaxLifeTime = GetConVarFloat(hCvar);
public OnTrailsChange(Handle:hCvar, const String:sOldValue[], const String:sNewValue[])			g_Cvar_bTrails = GetConVarBool(hCvar);

public OnMapStart()
{
	g_iTrailSprite = PrecacheModel(g_bIsCSGO ? "effects/blueblacklargebeam.vmt":"sprites/bluelaser1.vmt");
	g_iBloodDecal = PrecacheDecal("sprites/blood.vmt");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponDecideUse);
	if(!IsClientSourceTV(client) && !IsClientReplay(client))
	{
		SDKHookEx(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:OnTakeDamage(iVictim, &iAttacker, &inflictor, &Float:damage, &damagetype, &iWeapon, Float:fDamageForce[3], Float:fDamagePosition[3])
{
	new dmgtype = g_bIsCSGO ? DMG_SLASH|DMG_NEVERGIB:DMG_BULLET|DMG_NEVERGIB;

	if(0 < inflictor <= MaxClients && inflictor == iAttacker && damagetype == dmgtype)
	{
		g_bHeadshot[iAttacker] = false;
		if(g_hTimerLR[iAttacker] != INVALID_HANDLE)
		{
			KillTimer(g_hTimerLR[iAttacker]);
			g_hTimerLR[iAttacker] = INVALID_HANDLE;
		}
	} 
}
	
public Action:OnWeaponDecideUse(client, weapon)
{
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && allow[client])
	{
			decl String:sClassname[128];
			GetEntityClassname(weapon, sClassname, sizeof(sClassname));
		   
			if(StrContains(sClassname, "knife", false) == -1)
			{
					return Plugin_Handled;
			}
	}
	return Plugin_Continue;
}
public OnConfigsExecuted()
{
        static bool:bAddedThrowingKnives = false;
        if (!bAddedThrowingKnives)
        {
                g_LREntryNum = AddLastRequestToList(ThrowingKnives_Start, ThrowingKnives_Stop, g_sLR_Name);
                bAddedThrowingKnives = true;
        }      
}
 
// The plugin should remove any LRs it loads when it's unloaded
public OnPluginEnd()
{
        RemoveLastRequestFromList(ThrowingKnives_Start, ThrowingKnives_Stop, g_sLR_Name);
}
 
public ThrowingKnives_Start(Handle:LR_Array, iIndexInArray)
{
	new This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, _:Block_LRType);
	if (This_LR_Type == g_LREntryNum)
	{              
		new LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
		new LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);

		decl String:nome_guarda[32];
		GetClientName(LR_Player_Guard, nome_guarda, sizeof(nome_guarda));	

		decl String:nome_prisio[32];
		GetClientName(LR_Player_Prisoner, nome_prisio, sizeof(nome_prisio));	
		// check datapack value
		new LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);    
		switch (LR_Pack_Value)
		{
			case -1:
			{
			PrintToServer("no info included");
			}
		}

		SetEntityHealth(LR_Player_Prisoner, 250); 
		SetEntityHealth(LR_Player_Guard, 250);

		StripAllWeapons(LR_Player_Prisoner);
		StripAllWeapons(LR_Player_Guard); 
		allow[LR_Player_Prisoner] = true;
		allow[LR_Player_Guard] = true;

		colourt[LR_Player_Prisoner] = GetRandomInt(0, 5);
		colourct[LR_Player_Guard] = GetRandomInt(0, 5);

		// Store a countdown timer variable - we'll use 3 seconds
		SetArrayCell(LR_Array, iIndexInArray, 3, _:Block_Global1);

		if (gH_Timer_Countdown == INVALID_HANDLE)
		{
			gH_Timer_Countdown = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}

		CPrintToChatAll("\x04[TKLR]\x01 Last request Throwing Knife between \x04%s\x01 and \x04%s \x03will be started!", nome_guarda, nome_prisio);
	}
}
 
public ThrowingKnives_Stop(This_LR_Type, LR_Player_Prisoner, LR_Player_Guard)
{
	decl String:nome_guarda[32];
	GetClientName(LR_Player_Guard, nome_guarda, sizeof(nome_guarda));	

	decl String:nome_prisio[32];
	GetClientName(LR_Player_Prisoner, nome_prisio, sizeof(nome_prisio));	
	 
	if (This_LR_Type == g_LREntryNum)
	{
		if (IsClientInGame(LR_Player_Prisoner))
		{
			allow[LR_Player_Prisoner] = false;
			allow[LR_Player_Guard] = false;
			SetEntityGravity(LR_Player_Prisoner, 1.0);
			if (IsPlayerAlive(LR_Player_Prisoner))
			{
				SetEntityHealth(LR_Player_Prisoner, 100);
				GivePlayerItem(LR_Player_Prisoner, "weapon_knife");
				CPrintToChatAll("\x04[TKLR]\x01 The player \x04%s\x01 won the LR Throwing Knife against \x04%s", nome_prisio, nome_guarda);
			}
		}
		if (IsClientInGame(LR_Player_Guard))
		{
			allow[LR_Player_Prisoner] = false;
			allow[LR_Player_Guard] = false;
			SetEntityGravity(LR_Player_Guard, 1.0);
			if (IsPlayerAlive(LR_Player_Guard))
			{
				SetEntityHealth(LR_Player_Guard, 100);
				GivePlayerItem(LR_Player_Guard, "weapon_knife");
				CPrintToChatAll("\x04[TKLR]\x01 The player \x04%s\x01 won the LR Throwing Knife against \x04%s", nome_guarda, nome_prisio);
			}
		}
	}
}
 
public Action:Timer_Countdown(Handle:timer)
{
        new numberOfLRsActive = ProcessAllLastRequests(ThrowingKnives_Countdown, g_LREntryNum);
        if ((numberOfLRsActive <= 0) || bAllCountdownsCompleted)
        {
                gH_Timer_Countdown = INVALID_HANDLE;
                return Plugin_Stop;
        }
        return Plugin_Continue;
}
 
public ThrowingKnives_Countdown(Handle:LR_Array, iIndexInArray)
{
	new LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner);
	new LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard);

	new countdown = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);
	if (countdown > 0)
	{
		StripAllWeapons(LR_Player_Prisoner);
		StripAllWeapons(LR_Player_Guard);
		bAllCountdownsCompleted = false;
		PrintCenterText(LR_Player_Prisoner, "Lr start in %i...", countdown);
		PrintCenterText(LR_Player_Guard, "Lr start in %i...", countdown);
		SetArrayCell(LR_Array, iIndexInArray, --countdown, _:Block_Global1); 			
	}
	else if (countdown == 0)
	{ 
	//	EmitSoundToAllAny("sm_hosties/noscopestart1.mp3"); 	
		bAllCountdownsCompleted = true;
		SetArrayCell(LR_Array, iIndexInArray, --countdown, _:Block_Global1);   

		new PrisonerKnife = GivePlayerItem(LR_Player_Prisoner, "weapon_knife");
		new GuardKnife = GivePlayerItem(LR_Player_Guard, "weapon_knife");

		SetArrayCell(LR_Array, iIndexInArray, PrisonerKnife, _:Block_PrisonerData);
		SetArrayCell(LR_Array, iIndexInArray, GuardKnife, _:Block_GuardData);

		SetEntityGravity(LR_Player_Prisoner, 0.7);
		SetEntityGravity(LR_Player_Guard, 0.7);
	}
}
 
public Event_WeaponFire(Handle:hEvent, const String:sEvName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(IsPlayerAlive(iClient) && IsClientInGame(iClient) && allow[iClient]) 
	{ 
		decl String:sWeapon[16];
		GetEventString(hEvent, "weapon", sWeapon, sizeof(sWeapon));

		if(StrContains(sWeapon[7], "knife", false) != -1 || strcmp(sWeapon[7], "bayonet") == 0)
		{
			g_hTimerLR[iClient] = CreateTimer(0.0, CreateKnifeLR, iClient);
		}
	}
}
  
public Action:Event_PlayerDeath(Handle:hEvent, const String:sEvName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(allow[iClient])
	{
		decl String:sWeapon[20]; 
		GetEventString(hEvent, "weapon", sWeapon, sizeof(sWeapon));

		if(StrContains(sWeapon, "knife", false) != -1 || strcmp(sWeapon, "bayonet") == 0)
		{
			SetEventBool(hEvent, "headshot", g_bHeadshot[iClient]);
			g_bHeadshot[iClient] = false;
		}
	}

	return Plugin_Continue;
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	gH_Timer_Countdown = INVALID_HANDLE;
	
	LoopClients(i)
	{
		allow[i] = false;
		if(g_hTimerLR[i] != INVALID_HANDLE)
		{
			KillTimer(g_hTimerLR[i]);
			g_hTimerLR[i] = INVALID_HANDLE;
		}
	}
	
}
public Action:CreateKnifeLR(Handle:timer, any:iClient)
{
	g_hTimerLR[iClient] = INVALID_HANDLE;
	if(IsClientInGame(iClient))
	{
		new slot_knife = GetPlayerWeaponSlot(iClient, 2);
		new iKnife = CreateEntityByName("smokegrenade_projectile");
		DispatchKeyValue(iKnife, "classname", "throwing_knife");
		if(DispatchSpawn(iKnife))
		{
			new iTeam = GetClientTeam(iClient);
			SetEntPropEnt(iKnife, Prop_Send, "m_hOwnerEntity", iClient);
			SetEntPropEnt(iKnife, Prop_Send, "m_hThrower", iClient);
			SetEntProp(iKnife, Prop_Send, "m_iTeamNum", iTeam);

			decl String:sBuffer[PLATFORM_MAX_PATH];
			if(slot_knife != -1)
			{
				GetEntPropString(slot_knife, Prop_Data, "m_ModelName", sBuffer, sizeof(sBuffer));
				if(ReplaceString(sBuffer, sizeof(sBuffer), "v_knife_", "w_knife_", true) != 1)
				{
					sBuffer[0] = '\0';
				}
				else if(g_bIsCSGO && ReplaceString(sBuffer, sizeof(sBuffer), ".mdl", "_dropped.mdl", true) != 1)
				{
					sBuffer[0] = '\0';
				}
			}

			if(FileExists(sBuffer, true) == false)
			{
				if(g_bIsCSGO)
				{
					switch(iTeam)
					{
						case 2:	strcopy(sBuffer, sizeof(sBuffer), "models/weapons/w_knife_default_t_dropped.mdl");
						case 3:	strcopy(sBuffer, sizeof(sBuffer), "models/weapons/w_knife_default_ct_dropped.mdl");
					}
				}
				else
				{
					strcopy(sBuffer, sizeof(sBuffer), "models/weapons/w_knife_t.mdl");
				}
			}

			SetEntProp(iKnife, Prop_Send, "m_nModelIndex", PrecacheModel(sBuffer));
			SetEntPropFloat(iKnife, Prop_Send, "m_flModelScale", g_Cvar_fModelScale);
			SetEntPropFloat(iKnife, Prop_Send, "m_flElasticity", g_Cvar_fElasticity);
			SetEntPropFloat(iKnife, Prop_Data, "m_flGravity", g_Cvar_fGravity);

			// Player fOrigin and fAngles
			decl Float:fOrigin[3], Float:fAngles[3], Float:sPos[3], Float:fPlayerVelocity[3], Float:fVelocity[3];
			GetClientEyePosition(iClient, fOrigin);
			GetClientEyeAngles(iClient, fAngles);

			// knive new spawn position and fAngles is same as player's
			GetAngleVectors(fAngles, sPos, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(sPos, 50.0);
			AddVectors(sPos, fOrigin, sPos);

			// knive flying direction and speed/power
			GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fPlayerVelocity);
			GetAngleVectors(fAngles, fVelocity, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(fVelocity, g_Cvar_fVelocity);
			AddVectors(fVelocity, fPlayerVelocity, fVelocity);

			SetEntPropVector(iKnife, Prop_Data, "m_vecAngVelocity", Float:{4000.0, 0.0, 0.0});

			// Stop grenade detonate and Kill knive after 1 - 30 sec
			SetEntProp(iKnife, Prop_Data, "m_nNextThinkTick", -1);
			Format(sBuffer, sizeof(sBuffer), "!self,Kill,,%0.1f,-1", g_Cvar_fMaxLifeTime);
			DispatchKeyValue(iKnife, "OnUser1", sBuffer);
			AcceptEntityInput(iKnife, "FireUser1");

			// trail effect
			if(g_Cvar_bTrails)
			{
				if(g_bIsCSGO)
				{
					TE_SetupBeamFollow(iKnife, g_iTrailSprite, 0, 0.5, 1.0, 0.1, 0, {255, 255, 255, 255});
				}
				else
				{
					TE_SetupBeamFollow(iKnife, g_iTrailSprite, 0, 0.5, 8.0, 1.0, 0, {255, 255, 255, 255});
				}
				TE_SendToAll();
			}

			// Throw knive!
			TeleportEntity(iKnife, sPos, fAngles, fVelocity);
			SDKHookEx(iKnife, SDKHook_Touch, KnifeHit);

			PushArrayCell(g_hThrownKnives, EntIndexToEntRef(iKnife));
		}
	}
}

public Action:KnifeHit(iKnife, iVictim)
{
	if(0 < iVictim <= MaxClients)
	{
		SetVariantString("csblood");
		AcceptEntityInput(iKnife, "DispatchEffect");
		AcceptEntityInput(iKnife, "Kill");

		new iAttacker = GetEntPropEnt(iKnife, Prop_Send, "m_hThrower");
		new inflictor = GetPlayerWeaponSlot(iAttacker, 2);

		if(inflictor == -1)
		{
			inflictor = iAttacker;
		}

		decl Float:fVictimEye[3], Float:fDamagePosition[3], Float:fDamageForce[3];
		GetClientEyePosition(iVictim, fVictimEye);

		GetEntPropVector(iKnife, Prop_Data, "m_vecOrigin", fDamagePosition);
		GetEntPropVector(iKnife, Prop_Data, "m_vecVelocity", fDamageForce);

		if(GetVectorLength(fDamageForce) != 0.0) // iKnife movement stop
		{
			new Float:distance = GetVectorDistance(fDamagePosition, fVictimEye);
			g_bHeadshot[iAttacker] = distance <= 20.0;

			new dmgtype = g_bIsCSGO ? DMG_SLASH|DMG_NEVERGIB:DMG_BULLET|DMG_NEVERGIB;

			if(g_bHeadshot[iAttacker])
			{
				dmgtype |= DMG_HEADSHOT;
			}

			SDKHooks_TakeDamage(iVictim, inflictor, iAttacker,
			g_bHeadshot[iAttacker] ? g_Cvar_fHSDamage:g_Cvar_fDamage,
			dmgtype, iKnife, fDamageForce, fDamagePosition);

			TE_SetupBloodSprite(fDamagePosition, Float:{0.0, 0.0, 0.0}, {255, 0, 0, 255}, 1, g_iBloodDecal, g_iBloodDecal);
			TE_SendToAll(0.0);

			new ragdoll = GetEntPropEnt(iVictim, Prop_Send, "m_hRagdoll");
			if(ragdoll != -1)
			{
				ScaleVector(fDamageForce, 50.0);
				fDamageForce[2] = FloatAbs(fDamageForce[2]);
				SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", fDamageForce);
				SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollVelocity", fDamageForce);
			}
		}
	}
	else if(FindValueInArray(g_hThrownKnives, EntIndexToEntRef(iVictim)) != -1) // ножи столкнулись
	{
		SDKUnhook(iKnife, SDKHook_Touch, KnifeHit);
		decl Float:sPos[3], Float:dir[3];
		GetEntPropVector(iKnife, Prop_Data, "m_vecOrigin", sPos);
		TE_SetupArmorRicochet(sPos, dir);
		TE_SendToAll(0.0);

		DispatchKeyValue(iKnife, "OnUser1", "!self,Kill,,1.0,-1");
		AcceptEntityInput(iKnife, "FireUser1");
	}
}

public OnEntityDestroyed(entity)
{
	if(IsValidEdict(entity))
	{
		new index = FindValueInArray(g_hThrownKnives, EntIndexToEntRef(entity));
		if(index != -1)
		{
			RemoveFromArray(g_hThrownKnives, index);
		}
	}
}

bool:Func_IsCSGO()
{
	if (GetFeatureStatus(FeatureType_Native, "GetEngineVersion") == FeatureStatus_Available)
	{
		return GetEngineVersion() == Engine_CSGO;
	}
	else if (GetFeatureStatus(FeatureType_Native, "GuessSDKVersion") == FeatureStatus_Available)
	{
		return GuessSDKVersion() == SOURCE_SDK_CSGO;
	}
	return false;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	MarkNativeAsOptional("GuessSDKVersion");
	MarkNativeAsOptional("GetEngineVersion");

	return APLRes_Success; 
}