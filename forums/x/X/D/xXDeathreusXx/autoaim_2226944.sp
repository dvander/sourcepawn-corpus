////////////////////////
// Table of contents: //
/////// Commands ///////
//////// Events ////////
//////// Stocks ////////
////////////////////////

/*
*	CREDITS, for sto-erm... borrowed code
*	ReFlexPoison: For the idea from his autoreflect plugin, and for his "GetClosestClient" stock, and the heavy modification of the OnPlayerRunCmd he used.
*	friagram: Used and modified his "CanSeeTarget" stock to make sure it doesn't aim across the map, as it made it hard to know where I was going.
*	javalia: Found some code from a homing projectiles plugin of his that made arrows aim for the head, modified this to make players aim for the head or not.
*	Mitchell: He helped alot and handed over some excellent code to improve the aim.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_NAME  "Auto Aim"
#define PLUGIN_VERSION  "0.4.5"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Deathreus",
	description = "Long story short, it's an aimbot",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=238529"
}

new bool:g_bToHead[MAXPLAYERS+1];
new Handle:g_hCvarEnabled;
new bool:g_bCvarEnabled;
new Handle:g_hCvarAimAndShoot;
new bool:g_bCvarAimAndShoot;
new Handle:g_hCvarAimMode;
new bool:g_bCvarAimMode;
new Handle:g_hCvarAimKey;
new g_iCvarAimKey;
/*new Handle:g_hCvarAimFoV;
new bool:g_bCvarAimFoV;*/
new g_bAutoAiming[MAXPLAYERS+1] = {false, ...};
new ClientEyes[MAXPLAYERS+1];
new ActiveWeapon[MAXPLAYERS+1];
//new ActiveWeaponClass[MAXPLAYERS+1];
new sprmdl;
/*new g_bIsLooking[MAXPLAYERS+1][MAXPLAYERS+1];
new g_offsPlayerFOV = -1;
new g_offsPlayerDefaultFOV = -1;*/

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_autoaim_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_autoaim_enabled", "1", "Enable Aimbot?(As if you'd want if off)\n0 = Disabled\n1 = Enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarAimAndShoot = CreateConVar("sm_autoaim_aimandshoot", "0", "Aim and automatically shoot?\n0 = No\n1 = Yes\nOnly have one of these modes on at a time", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bCvarAimAndShoot = GetConVarBool(g_hCvarAimAndShoot);
	HookConVarChange(g_hCvarAimAndShoot, OnConVarChange);
	
	g_hCvarAimMode = CreateConVar("sm_autoaim_aimmode", "0", "Should the aimbot only aim if a button is pressed?\n0 = No\n1 = Yes", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bCvarAimMode = GetConVarBool(g_hCvarAimMode);
	HookConVarChange(g_hCvarAimMode, OnConVarChange);

	g_hCvarAimKey = CreateConVar("sm_autoaim_aimkey", "2", "What key needs to be pressed to enable the bot?\n 1 = Secondary Attack\n2 = Special Attack\n3 = Reload", FCVAR_NONE, true, 1.0, true, 3.0);
	g_iCvarAimKey = GetConVarInt(g_hCvarAimKey);
	HookConVarChange(g_hCvarAimKey, OnConVarChange);
	
	/*g_hCvarAimFoV = CreateConVar("sm_autoaim_aiminfov", "0", "Should it only aim at targets within your FoV?\n0 = No\n1 = Yes\nOnly have one of these modes on at a time", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bCvarAimFoV = GetConVarBool(g_hCvarAimFoV);
	HookConVarChange(g_hCvarAimFoV, OnConVarChange);*/

	RegAdminCmd("sm_autoaim", AutoAimCmd, ADMFLAG_GENERIC, "Turns on aimbot");
	RegAdminCmd("sm_aim", AutoAimCmd, ADMFLAG_GENERIC, "Turns on aimbot");		// Convenience purposes only
	
	/*g_offsPlayerFOV = FindSendPropInfo("CBasePlayer", "m_iFOV");
	if (g_offsPlayerFOV == -1) SetFailState("Couldn't find CBasePlayer offset for m_iFOV.");
	
	g_offsPlayerDefaultFOV = FindSendPropInfo("CBasePlayer", "m_iDefaultFOV");
	if (g_offsPlayerDefaultFOV == -1) SetFailState("Couldn't find CBasePlayer offset for m_iDefaultFOV.");*/

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(IsClientInGame(i))
		{
			SDKHook(i, SDKHook_WeaponCanSwitchToPost, WeaponSwitch);
			if(IsPlayerAlive(i))
				CreateEyeProp(i);
		}
	}
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_death", Event_Death);
}

public OnPluginEnd()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsSprite(ClientEyes[i]))
		{
			AcceptEntityInput(ClientEyes[i], "kill");
		}
	}
}


/////////////////////////////////////
// Commands start below this point //
/////////////////////////////////////

public Action:AutoAimCmd(client, args)
{
	if(!g_bCvarEnabled || !IsValidClient(client))
		return Plugin_Continue;

	if(args != 0 && args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_autoaim <target> [0/1]");
		return Plugin_Handled;
	}

	if(args == 0)
	{
		if(!g_bAutoAiming[client])
		{
			PrintToChat(client, "[SM] Auto aiming enabled.");
			g_bAutoAiming[client] = true;
		}
		else
		{
			PrintToChat(client, "[SM] Auto aiming disabled.");
			g_bAutoAiming[client] = false;
		}
		return Plugin_Handled;
	}

	else if(args == 2)
	{
		decl String:arg1[PLATFORM_MAX_PATH];
		GetCmdArg(1, arg1, sizeof(arg1));
		decl String:arg2[8];
		GetCmdArg(2, arg2, sizeof(arg2));

		new value = StringToInt(arg2);
		if(value != 0 && value != 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_autoaim <target> [0/1]");
			return Plugin_Handled;
		}

		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for(new i=0; i<target_count; i++) if(IsValidClient(target_list[i]))
		{
			if(value == 0)
			{
				PrintToChat(target_list[i], "[SM] Auto aiming disabled.");
				g_bAutoAiming[target_list[i]] = false;
			}
			else
			{
				PrintToChat(target_list[i], "[SM] Auto aiming enabled.");
				g_bAutoAiming[target_list[i]] = true;
			}
		}
	}

	return Plugin_Handled;
}

/////////////////////////////////////
//  Events start below this point  //
/////////////////////////////////////

public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_hCvarEnabled)
		g_bCvarEnabled = bool:StringToInt(newValue);

	if(convar == g_hCvarAimAndShoot)
		g_bCvarAimAndShoot = bool:StringToInt(newValue);

	if(convar == g_hCvarAimMode)
		g_bCvarAimMode = bool:StringToInt(newValue);

	if(convar == g_hCvarAimKey)
		g_iCvarAimKey = StringToInt(newValue);

	/*if(convar == g_hCvarAimFoV)
		g_bCvarAimFoV = bool:StringToInt(newValue);*/
}

public OnMapStart()
{
	sprmdl = PrecacheModel("effects/strider_bulge_dudv_dx60.vmt");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanSwitchToPost, WeaponSwitch);
}

public OnClientDisconnect(client)
{
	g_bAutoAiming[client] = false;
	
	if(IsSprite(ClientEyes[client]))
		AcceptEntityInput(ClientEyes[client], "Kill");
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsPlayerAlive(client))
	{
		CreateEyeProp(client);
	}
}

public Action:Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsSprite(ClientEyes[client]))
	{
		AcceptEntityInput(ClientEyes[client], "kill");
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:velocity[3], Float:angles[3], &weapon)
{
	if(!g_bCvarEnabled || !g_bAutoAiming[client])
		return Plugin_Continue;
	if(!IsPlayerAlive(client) || !IsClientInGame(client))
		return Plugin_Continue;
	
	static NextTargetTime[MAXPLAYERS+1];
	static Target[MAXPLAYERS+1];

	new iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(iCurrentWeapon == -1)
		return Plugin_Continue;

	new clientteam = GetClientTeam(client);

	new TFClassType:class = TF2_GetPlayerClass(client);
	new String:Weapon[16];
	GetClientWeapon(client, Weapon, sizeof(Weapon));

	// Check for, and disable aiming for sapper's, medigun's, and wrench's
	if((class == TFClass_Spy && (StrEqual(Weapon, "tf_weapon_sapper", false) || StrEqual(Weapon, "tf_weapon_builder", false))) || StrEqual(Weapon, "tf_weapon_medigun", false) || StrEqual(Weapon, "tf_weapon_wrench", false))
		return Plugin_Continue;

	// These checks are probably mostly redundant, but just want to be sure I make certain classes aim at certain points of the body to be effective
	if (class == TFClass_Sniper || (class == TFClass_Spy && !StrEqual(Weapon, "tf_weapon_knife", false)))
		g_bToHead[client] = true;
	else if(StrEqual(Weapon, "tf_weapon_scattergun", false)
	|| StrEqual(Weapon, "tf_weapon_pep_brawler_blaster", false)
	|| StrEqual(Weapon, "tf_weapon_handgun_scout_primary", false)
	|| StrEqual(Weapon, "tf_weapon_soda_popper", false)
	|| StrEqual(Weapon, "tf_weapon_pistol_acout", false))
		g_bToHead[client] = false;
	else if(StrEqual(Weapon, "tf_weapon_rocketlauncher", false)
	|| StrEqual(Weapon, "tf_weapon_shotgun_soldier", false))
		g_bToHead[client] = false;
	else if(StrEqual(Weapon, "tf_weapon_flamethrower", false)
	|| StrEqual(Weapon, "tf_weapon_shotgun_pyro", false))
		g_bToHead[client] = false;
	else if(StrEqual(Weapon, "tf_weapon_pipebomblauncher", false)
	|| StrEqual(Weapon, "tf_weapon_grenadelauncher", false)
	|| StrEqual(Weapon, "tf_weapon_cannon", false))
		g_bToHead[client] = true;
	else if(StrEqual(Weapon, "tf_weapon_minigun", false)
	|| StrEqual(Weapon, "tf_weapon_shotgun_hwg", false))
		g_bToHead[client] = false;
	else if(class == TFClass_Engineer && !StrEqual(Weapon, "tf_weapon_wrench"))
		g_bToHead[client] = false;
	else if(StrEqual(Weapon, "tf_weapon_crossbow", false)
	|| StrEqual(Weapon, "tf_weapon_syringegun_medic", false))
		g_bToHead[client] = true;
	else if(StrEqual(Weapon, "tf_weapon_smg", false))
		g_bToHead[client] = false;
	else
		g_bToHead[client] = true;

	decl Float:fClientEyePosition[3], Float:targetEyes[3]/*, Float:fAnlges, Float:anglevector, Float:vecrt, Float:targetvector*/;

	GetClientEyePosition(client, fClientEyePosition);
	//GetAngleVectors(fAngles, anglevector, vecrt, NULL_VECTOR);

	if((g_bCvarAimMode) && IsValidClient(client))
	{
		new String:button;

		if(g_iCvarAimKey == 1)
			button = IN_ATTACK2;
		else if(g_iCvarAimKey == 2)
			button = IN_ATTACK3; // Special Attack
		else if(g_iCvarAimKey == 3)
			button = IN_RELOAD;

		if(buttons & button)
		{
			// Thanks Mitchell for this awesome code
			if(NextTargetTime[client] < GetTime())
			{
				Target[client] = GetClosestClient(client);
				NextTargetTime[client] = GetTime() + 5;
			}
			if(!IsValidClient(Target[client]) || !IsPlayerAlive(Target[client]))
			{
				Target[client] = GetClosestClient(client);
				NextTargetTime[client] = GetTime() + 5;
			}
			else
			{
				GetClientEyePosition(Target[client], targetEyes);
				if(!CanSeeTarget(fClientEyePosition, targetEyes, Target[client], clientteam))
				{
					Target[client] = GetClosestClient(client);
					NextTargetTime[client] = GetTime() + 5;
				}
			}

			if(Target[client] > 0)
			{
				if(IsSprite(ClientEyes[Target[client]]))
				{
					decl Float:camangle[3],Float:vec[3];
					GetEntPropVector(ClientEyes[Target[client]], Prop_Data, "m_vecAbsOrigin", targetEyes);

					TE_SetupGlowSprite(targetEyes, sprmdl, 0.1, 0.1, 200);
					TE_SendToClient(client);

					switch(ActiveWeapon[client])
					{
						case 56, 1005, 1092, 39, 351, 595, 740, 1081:
							targetEyes[2] += GetVectorDistance(fClientEyePosition, targetEyes)/75.0;	// Calculate the dropoff
					}
					
					if(!g_bToHead[client])
						targetEyes[2] -= 25.0;

					MakeVectorFromPoints(targetEyes, fClientEyePosition, vec);
					GetVectorAngles(vec, camangle);
					camangle[0] *= -1.0;
					camangle[1] += 180.0;

					ClampAngle(camangle);
					TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
				}
				else Target[client] = 0;
			}
		}
	}
	else if((g_bCvarAimAndShoot) && IsValidClient(client))
	{
		if(NextTargetTime[client] < GetTime())
		{
			Target[client] = GetClosestClient(client);
			NextTargetTime[client] = GetTime() + 5;
		}
		if(!IsValidClient(Target[client]) || !IsPlayerAlive(Target[client]))
		{
			Target[client] = GetClosestClient(client);
			NextTargetTime[client] = GetTime() + 5;
		}
		else
		{
			GetClientEyePosition(Target[client], targetEyes);
			if(!CanSeeTarget(fClientEyePosition, targetEyes, Target[client], clientteam))
			{
				Target[client] = GetClosestClient(client);
				NextTargetTime[client] = GetTime() + 5;
			}
		}

		if(Target[client] > 0)
		{
			if(IsSprite(ClientEyes[Target[client]]))
			{
				decl Float:camangle[3],Float:vec[3];
				GetEntPropVector(ClientEyes[Target[client]], Prop_Data, "m_vecAbsOrigin", targetEyes);

				TE_SetupGlowSprite(targetEyes, sprmdl, 0.1, 0.1, 200);
				TE_SendToClient(client);

				switch(ActiveWeapon[client])
				{
					case 56, 1005, 1092, 39, 351, 595, 740, 1081:
						targetEyes[2] += GetVectorDistance(fClientEyePosition, targetEyes)/75.0;	// Calculate the dropoff
				}
				
				if(!g_bToHead[client])
					targetEyes[2] -= 25.0;

				MakeVectorFromPoints(targetEyes, fClientEyePosition, vec);
				GetVectorAngles(vec, camangle);
				camangle[0] *= -1.0;
				camangle[1] += 180.0;

				ClampAngle(camangle);
				TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
				
				if(IsLooking(fClientEyePosition, targetEyes, Target[client]))	// If the player is looking at the target
					buttons |= IN_ATTACK;
			}
			else Target[client] = 0;
		}
	}
	/*else if((g_bCvarAimFoV) && IsValidClient(client))
	{
		if(NextTargetTime[client] < GetTime())
		{
			Target[client] = GetClosestClient(client);
			NextTargetTime[client] = GetTime() + 5;
		}
		if(!IsValidClient(Target[client]) || !IsPlayerAlive(Target[client]))
		{
			Target[client] = GetClosestClient(client);
			NextTargetTime[client] = GetTime() + 5;
		}
		else
		{
			GetClientEyePosition(Target[client], targetEyes);
			if(!CanSeeTarget(fClientEyePosition, targetEyes, Target[client], clientteam))
			{
				Target[client] = GetClosestClient(client);
				NextTargetTime[client] = GetTime() + 5;
			}
		}
		
		new bool:bPlayerInFOV[MAXPLAYERS + 1] = false;
		new Float:flBuffer[3];
		new flClientFOV = GetEntData(client, g_offsPlayerFOV);
		
		SubtractVectors(targetEyes, fClientEyePosition, flBuffer);
		GetVectorAngles(flBuffer, flBuffer);
		
		if (FloatAbs(AngleDiff(targetEyes[1], flBuffer[1])) <= flClientFOV)		// Figure out if the player is within FoV
			bPlayerInFOV[Target[client]] = true;

		if(Target[client] > 0)
		{
			if(IsSprite(ClientEyes[Target[client]]) && bPlayerInFOV[Target[client]])
			{
				decl Float:camangle[3],Float:vec[3];
				GetEntPropVector(ClientEyes[Target[client]], Prop_Data, "m_vecAbsOrigin", targetEyes);

				TE_SetupGlowSprite(targetEyes, sprmdl, 0.1, 0.1, 200);
				TE_SendToClient(client);

				switch(ActiveWeapon[client])
				{
					case 56, 1005, 1092, 39, 351, 595, 740, 1081:
						targetEyes[2] += GetVectorDistance(fClientEyePosition, targetEyes)/75.0;	// Calculate the dropoff
				}
				
				if(!g_bToHead[client])
					targetEyes[2] -= 25.0;

				MakeVectorFromPoints(targetEyes, fClientEyePosition, vec);
				GetVectorAngles(vec, camangle);
				camangle[0] *= -1.0;
				camangle[1] += 180.0;

				ClampAngle(camangle);
				TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
			}
			else Target[client] = 0;
		}
	}*/
	else
	{
		if(NextTargetTime[client] < GetTime())
		{
			Target[client] = GetClosestClient(client);
			NextTargetTime[client] = GetTime() + 5;
		}
		if(!IsValidClient(Target[client]) || !IsPlayerAlive(Target[client]))
		{
			Target[client] = GetClosestClient(client);
			NextTargetTime[client] = GetTime() + 5;
		}
		else
		{
			GetClientEyePosition(Target[client], targetEyes);
			if(!CanSeeTarget(fClientEyePosition, targetEyes, Target[client], clientteam))
			{
				Target[client] = GetClosestClient(client);
				NextTargetTime[client] = GetTime() + 5;
			}
		}

		if(Target[client] > 0)
		{
			if(IsSprite(ClientEyes[Target[client]]))
			{
				decl Float:camangle[3],Float:vec[3];
				GetEntPropVector(ClientEyes[Target[client]], Prop_Data, "m_vecAbsOrigin", targetEyes);

				TE_SetupGlowSprite(targetEyes, sprmdl, 0.1, 0.1, 200);
				TE_SendToClient(client);

				switch(ActiveWeapon[client])
				{
					case 56, 1005, 1092, 39, 351, 595, 740, 1081:
						targetEyes[2] += GetVectorDistance(fClientEyePosition, targetEyes)/75.0;	// Calculate the dropoff
				}
				
				if(!g_bToHead[client])
					targetEyes[2] -= 25.0;

				MakeVectorFromPoints(targetEyes, fClientEyePosition, vec);
				GetVectorAngles(vec, camangle);
				camangle[0] *= -1.0;
				camangle[1] += 180.0;

				ClampAngle(camangle);
				TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
			}
			else Target[client] = 0;
		}

		/*TR_GetEndPosition(targetvector);

		new iClosest = GetClosestClient(client);
		if(!IsValidClient(iClosest))
			return Plugin_Continue;

		decl Float:fClosestLocation[3];
		GetClientAbsOrigin(iClosest, fClosestLocation);
		fClosestLocation[2] += 33.5;

		if(!g_bToHead[client])
			fClosestLocation[2] = fClosestLocation[2] - 8.0;
		else if(GetEntProp(iClosest, Prop_Send, "m_bDucked"))
			fClosestLocation[2] += 15.0;
		else
			fClosestLocation[2] += 33.5;

		decl Float:fVector[3];
		MakeVectorFromPoints(fClosestLocation, fClientEyePosition, fVector);
		NormalizeVector(fVector, fVector);

		decl Float:fAngle[3];
		GetVectorAngles(fVector, fAngle);
		fAngle[0] *= -1.0;
		fAngle[1] += 180.0;

		TeleportEntity(client, NULL_VECTOR, fAngle, NULL_VECTOR);*/
	}
	

	return Plugin_Continue;
}


/////////////////////////////////////
//  Stocks start below this point  //
/////////////////////////////////////

stock GetClosestClient(iClient)
{
	decl Float:fClientLocation[3];
	GetClientAbsOrigin(iClient, fClientLocation);
	decl Float:fEntityOrigin[3];

	new clientteam = GetClientTeam(iClient);
	new iClosestEntity = -1;
	new Float:fClosestDistance = -1.0;
	new Float:fEntityDistance;

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) != clientteam && IsPlayerAlive(i) && i != iClient)
		{
			GetClientAbsOrigin(i, fEntityOrigin);
			fEntityDistance = GetVectorDistance(fClientLocation, fEntityOrigin);
			if((fEntityDistance < fClosestDistance) || fClosestDistance == -1.0)
			{
				if(CanSeeTarget(fClientLocation, fEntityOrigin, i, clientteam) && IsSprite(ClientEyes[i]))
				{
					fClosestDistance = fEntityDistance;
					iClosestEntity = i;
				}
			}
		}
	}
	return iClosestEntity;
}

stock bool:IsValidClient(client, bool:bReplay = true)
{
	if(client <= 0
	|| client > MaxClients
	|| !IsClientInGame(client))
		return false;

	if(bReplay
	&& (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}

bool:CanSeeTarget(Float:startpos[3], Float:targetpos[3], target, clientteam)
{
	TR_TraceRayFilter(startpos, targetpos, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, target);

	if(TR_GetEntityIndex() == target)
	{
		if(TF2_GetPlayerClass(target) == TFClass_Spy)
		{
			if(TF2_IsPlayerInCondition(target, TFCond_Cloaked))
			{
				if(TF2_IsPlayerInCondition(target, TFCond_CloakFlicker)
					|| TF2_IsPlayerInCondition(target, TFCond_OnFire)
					|| TF2_IsPlayerInCondition(target, TFCond_Jarated)
					|| TF2_IsPlayerInCondition(target, TFCond_Milked)
					|| TF2_IsPlayerInCondition(target, TFCond_Bleeding))
				{
					return true;
				}

				return false;
			}
			if(TF2_IsPlayerInCondition(target, TFCond_Disguised) && GetEntProp(target, Prop_Send, "m_nDisguiseTeam") == clientteam)
			{
				return false;
			}

			return true;
		}

		return true;
	}

	return false;
}

bool:IsLooking(Float:startpos[3], Float:targetpos[3], target)
{
	new Handle:TraceRay = TR_TraceRayFilterEx(startpos, targetpos, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, target);
	
	if(TR_GetEntityIndex(TraceRay) == target || TR_DidHit(TraceRay))
		return true;
	
	return false;
}

public bool:TraceRayFilterClients(entity, mask, any:data)
{
	if(entity > 0 && entity <=MaxClients)
	{
		if(entity == data)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	return true;
}

public Action:WeaponSwitch(client, weapon)
{
	if(IsValidEntity(weapon))
		ActiveWeapon[client] = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"); 

	return Plugin_Continue;
}

stock CreateEyeProp(client)
{
	if(IsSprite(ClientEyes[client]))
		AcceptEntityInput(ClientEyes[client], "kill");

	new DProp = CreateEntityByName("env_sprite");

	if(DProp > 0 && IsValidEntity(DProp))
	{
		DispatchKeyValue(DProp, "classname", "env_sprite");
		DispatchKeyValue(DProp, "spawnflags", "1");
		DispatchKeyValue(DProp, "rendermode", "0");
		DispatchKeyValue(DProp, "rendercolor", "0 0 0");
		
		DispatchKeyValue(DProp, "model", "effects/strider_bulge_dudv_dx60.vmt");
		SetVariantString("!activator");
		AcceptEntityInput(DProp, "SetParent", client, DProp, 0);
		SetVariantString("head");
		AcceptEntityInput(DProp, "SetParentAttachment", DProp , DProp, 0);
		DispatchSpawn(DProp);

		ClientEyes[client] = EntIndexToEntRef(DProp);
		SDKHook(DProp, SDKHook_SetTransmit, OnShouldProp);

		TeleportEntity(DProp, Float:{0.0,0.0,-4.0}, NULL_VECTOR, NULL_VECTOR);

	}
}

public Action:OnShouldProp(Ent, Client)
{
	return Plugin_Handled;
}

stock bool:IsSprite(Ent)
{
	if(Ent != -1 && IsValidEdict(Ent) && IsValidEntity(Ent) && IsEntNetworkable(Ent))
	{
		decl String:ClassName[255];
		GetEdictClassname(Ent, ClassName, 255);
		if(StrEqual(ClassName, "env_sprite"))
			return true;
	}
	return false;
}

stock ClampAngle(Float:fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}