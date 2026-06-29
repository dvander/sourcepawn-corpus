#pragma semicolon 1

#define PLUGIN_VERSION "1.0.1"

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[TF2] Homing Projectiles",
	author = "Phil25 - pheadxdll - Whai",
	description = "Homing Projectiles from RTD'",
	version = PLUGIN_VERSION,
	url = ""
};

bool bHasHomingProjectiles[MAXPLAYERS+1], bHasHomingHead[MAXPLAYERS+1], bHasHomingFeet[MAXPLAYERS+1];
ArrayList hArrayHomingProjectile = null;

ConVar hEnable, hCanSeeEveryone, hHomingProjectilesMod, hHomingHead, hHomingFeet, hDefaultSetting;
bool bEnable, bCanSeeEveryone, bHomingHead, bHomingFeet, bDefaultSetting;
int iHomingProjectilesMod;

#define HOMING_SPEED_MULTIPLIER 0.5
#define HOMING_AIRBLAST_MULTIPLIER 1.1

#define HOMING_NONE 0
#define HOMING_SELF (1 << 0) // rocket's owner					index : 1
#define HOMING_SELF_ORIG (1 << 1) // original launcher's owner		index : 2
#define HOMING_ENEMIES (1 << 2) // enemies of owner				index : 4
#define HOMING_FRIENDLIES (1 << 3) // friendlies of owner			index : 8
#define HOMING_SMOOTH (1 << 4) // smooths the turning			index : 16

public void OnPluginStart()
{
	RegAdminCmd("sm_homingprojectiles", Command_HomingProjectiles, ADMFLAG_SLAY, "Toggle Homing Projectiles");
	RegAdminCmd("sm_homing", Command_HomingProjectiles, ADMFLAG_SLAY, "Toggle Homing Projectiles");
	
	RegAdminCmd("sm_homingarrowhead", Command_HomingHead, ADMFLAG_SLAY, "Toggle Homing Arrow to target head");
	RegAdminCmd("sm_hominghead", Command_HomingHead, ADMFLAG_SLAY, "Toggle Homing Arrow to target head");
	
	RegAdminCmd("sm_homingrocketfeet", Command_HomingFeet, ADMFLAG_SLAY, "Toggle Homing Rocket to target feet");
	RegAdminCmd("sm_homingfeet", Command_HomingFeet, ADMFLAG_SLAY, "Toggle Homing Rocket to target feet");
	
	CreateConVar("sm_homingprojectiles_version", PLUGIN_VERSION, "[TF2] Homing Projectiles Version", FCVAR_NOTIFY | FCVAR_SPONLY);
	
	hEnable = CreateConVar("sm_homingprojectiles_enable", "1", "Enable/Disable \"Homing Projectiles\" Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hEnable.AddChangeHook(ConVarChanged);
	
	hCanSeeEveryone = CreateConVar("sm_homingprojectiles_canseeeveryone", "0", "If projectiles can attack/see invisible/disguised spies", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCanSeeEveryone.AddChangeHook(ConVarChanged);
	
	hHomingProjectilesMod = CreateConVar("sm_homingprojectiles_mod", "4", "Homing Projectiles Mod ||| 0 - No Mod (no Homing Projectiles)\n1 - Target the owner\n2 - Target the real owner (for example if pyro airblast the proj. , it's the real owner and not the pyro will get the proj.)\n4 - Target enemies\n8 - Target allies\n16 - Smooth Rocket Movements (Useless alone. Also, the rocket will lose a little his precision)\nYou can have more than 1 mod by adding the value(example : 20 = 16 + 4 = Target enemies + Smooth Rocket Movements)", FCVAR_NOTIFY, true, 0.0, true, 31.0);
	hHomingProjectilesMod.AddChangeHook(ConVarChanged);
	
	hHomingHead = CreateConVar("sm_homingprojectiles_head", "1", "Homing Arrow Head ||| 1 - Enable || 2 - Disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hHomingHead.AddChangeHook(ConVarChanged);
	
	hHomingFeet = CreateConVar("sm_homingprojectiles_feet", "1", "Homing Rocket Feet ||| 1 - Enable || 2 - Disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hHomingFeet.AddChangeHook(ConVarChanged);
	
	hDefaultSetting = CreateConVar("sm_homingprojectiles_default", "0", "Default setting for homing rockets ||| 1 - Enable || 2 - Disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hDefaultSetting.AddChangeHook(ConVarChanged);
	
	AutoExecConfig(true, "HomingProjectiles");
	
	HookEvent("teamplay_round_start", RoundStart);
	
	LoadTranslations("common.phrases");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int iClient)
{
	bHasHomingProjectiles[iClient] = bDefaultSetting;
	bHasHomingHead[iClient] = false;
	bHasHomingFeet[iClient] = false;
}

public void OnClientDisconnect(int iClient)
{
	bHasHomingProjectiles[iClient] = bDefaultSetting;
	bHasHomingHead[iClient] = false;
	bHasHomingFeet[iClient] = false;
}

public void OnMapStart()
{
	hArrayHomingProjectile = new ArrayList(3);
	hArrayHomingProjectile.Clear();
}

public void OnMapEnd()
{
	hArrayHomingProjectile.Clear();
}

public void RoundStart(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
	hArrayHomingProjectile.Clear();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	bEnable = hEnable.BoolValue;
	bCanSeeEveryone = hCanSeeEveryone.BoolValue;
	iHomingProjectilesMod = hHomingProjectilesMod.IntValue;
	bHomingHead = hHomingHead.BoolValue;
	bHomingFeet = hHomingFeet.BoolValue;
	bDefaultSetting = hDefaultSetting.BoolValue;
}

public Action Command_HomingProjectiles(int iClient, int iArgs)
{
	if(bEnable)
	{
		char arg1[MAX_NAME_LENGTH], arg2[32], target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		if(!iClient && !iArgs)
		{
			ReplyToCommand(iClient, "[SM] Usage in server console: sm_homingprojectiles <target>\n[SM] Usage in server console: sm_homingprojectiles <target> <1 - enable | 0 - disable>");
			return Plugin_Handled;
		}
		if(!iArgs)
		{
			if(bHasHomingProjectiles[iClient])
			{
				bHasHomingProjectiles[iClient] = false;
				ReplyToCommand(iClient, "[SM] Homing Projectiles is now disabled to you");
			}
			else
			{
				bHasHomingProjectiles[iClient] = true;
				ReplyToCommand(iClient, "[SM] Homing Projectiles is now enabled to you");
			}
		}
		if(iArgs == 1)
		{
			
			GetCmdArg(1, arg1, sizeof(arg1));
			
			if((target_count = ProcessTargetString(arg1, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(iClient, target_count);
				return Plugin_Handled;
			}
			
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					return Plugin_Handled;
				
				if(!bHasHomingProjectiles[target])
				{
					bHasHomingProjectiles[target] = true;
					ReplyToCommand(target, "[SM] Homing Projectiles is now enabled to you");
				}
				else
				{
					bHasHomingProjectiles[target] = false;
					ReplyToCommand(target, "[SM] Homing Projectiles is now disabled to you");
				}
			}
			ShowActivity2(iClient, "[SM] ", "Toggled Homing Projectiles for %s", target_name);
		}
		if(iArgs == 2)
		{
			GetCmdArg(1, arg1, sizeof(arg1));
			GetCmdArg(2, arg2, sizeof(arg2));
			
			if((target_count = ProcessTargetString(arg1, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(iClient, target_count);
				return Plugin_Handled;
			}
			
			for(int i = 0; i < target_count; i++)
			{
				int target = target_list[i];
				
				if(!target)
					return Plugin_Handled;
				
				if(StrEqual(arg2, "on", false) || StrEqual(arg2, "1", false))
				{
					if(!bHasHomingProjectiles[target])
						ReplyToCommand(target, "[SM] Homing Projectiles is now enabled to you");
						
					bHasHomingProjectiles[target] = true;	
				}
				else if(StrEqual(arg2, "off", false) || StrEqual(arg2, "0", false))
				{
					if(bHasHomingProjectiles[target])
						ReplyToCommand(target, "[SM] Homing Projectiles is now disabled to you");
					
					bHasHomingProjectiles[target] = false;
				}
			}
			if(StrEqual(arg2, "on", false) || StrEqual(arg2, "1", false))
			{
				ShowActivity2(iClient, "[SM] ", "Homing Projectiles is enabled to %s", target_name);
			}
			else if(StrEqual(arg2, "off", false) || StrEqual(arg2, "0", false))
			{
				ShowActivity2(iClient, "[SM] ", "Homing Projectiles is disabled to %s", target_name);
			}
		}
		if(iArgs > 2)
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_homingprojectiles\n[SM] Usage: sm_homingprojectiles <target>\n[SM] Usage: sm_homingprojectiles <target> <1 - enable | 0 - disable>");
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(iClient, "[SM] Cannot use the command, plugin not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_HomingHead(int iClient, int iArgs)
{
	if(bEnable)
	{
		if(bHomingHead)
		{
			char arg1[MAX_NAME_LENGTH], arg2[32], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			
			if(!iClient && !iArgs)
			{
				ReplyToCommand(iClient, "[SM] Usage in server console: sm_homingarrowhead <target>\n[SM] Usage in server console: sm_homingarrowhead <target> <1 - enable | 0 - disable>");
				return Plugin_Handled;
			}
			if(!iArgs)
			{
				if(bHasHomingHead[iClient])
				{
					bHasHomingHead[iClient] = false;
					ReplyToCommand(iClient, "[SM] Homing Arrow Head is now disabled to you");
				}
				else
				{
					bHasHomingHead[iClient] = true;
					ReplyToCommand(iClient, "[SM] Homing Arrow Head is now enabled to you");
				}
			}
			if(iArgs == 1)
			{
				
				GetCmdArg(1, arg1, sizeof(arg1));
				
				if((target_count = ProcessTargetString(arg1, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
				{
					ReplyToTargetError(iClient, target_count);
					return Plugin_Handled;
				}
				
				for(int i = 0; i < target_count; i++)
				{
					int target = target_list[i];
					
					if(!target)
						return Plugin_Handled;
					
					if(!bHasHomingHead[target])
					{
						bHasHomingHead[target] = true;
						ReplyToCommand(target, "[SM] Homing Arrow Head is now enabled to you");
					}
					else
					{
						bHasHomingHead[target] = false;
						ReplyToCommand(target, "[SM] Homing Arrow Head is now disabled to you");
					}
				}
				ShowActivity2(iClient, "[SM] ", "Toggled Homing Arrow Head for %s", target_name);
			}
			if(iArgs == 2)
			{
				GetCmdArg(1, arg1, sizeof(arg1));
				GetCmdArg(2, arg2, sizeof(arg2));
				
				if((target_count = ProcessTargetString(arg1, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
				{
					ReplyToTargetError(iClient, target_count);
					return Plugin_Handled;
				}
				
				for(int i = 0; i < target_count; i++)
				{
					int target = target_list[i];
					
					if(!target)
						return Plugin_Handled;
					
					if(StrEqual(arg2, "on", false) || StrEqual(arg2, "1", false))
					{
						if(!bHasHomingHead[target])
							ReplyToCommand(target, "[SM] Homing Arroww Head is now enabled to you");
							
						bHasHomingHead[target] = true;	
					}
					else if(StrEqual(arg2, "off", false) || StrEqual(arg2, "0", false))
					{
						if(bHasHomingHead[target])
							ReplyToCommand(target, "[SM] Homing Arrow Head is now disabled to you");
						
						bHasHomingHead[target] = false;
					}
				}
				if(StrEqual(arg2, "on", false) || StrEqual(arg2, "1", false))
				{
					ShowActivity2(iClient, "[SM] ", "Homing Arrow Head is enabled to %s", target_name);
				}
				else if(StrEqual(arg2, "off", false) || StrEqual(arg2, "0", false))
				{
					ShowActivity2(iClient, "[SM] ", "Homing Arrow Head is disabled to %s", target_name);
				}
			}
			if(iArgs > 2)
			{
				ReplyToCommand(iClient, "[SM] Usage: sm_homingarrowhead\n[SM] Usage: sm_homingarrowhead <target>\n[SM] Usage: sm_homingarrowhead <target> <1 - enable | 0 - disable>");
				return Plugin_Handled;
			}
		}
		else
		{
			ReplyToCommand(iClient, "[SM] Cannot use the command, the owner disabled this function");
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(iClient, "[SM] Cannot use the command, plugin not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_HomingFeet(int iClient, int iArgs)
{
	if(bEnable)
	{
		if(bHomingFeet)
		{
			char arg1[MAX_NAME_LENGTH], arg2[32], target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			
			if(!iClient && !iArgs)
			{
				ReplyToCommand(iClient, "[SM] Usage in server console: sm_homingrocketfeet <target>\n[SM] Usage in server console: sm_homingrocketfeet <target> <1 - enable | 0 - disable>");
				return Plugin_Handled;
			}
			if(!iArgs)
			{
				if(bHasHomingFeet[iClient])
				{
					bHasHomingFeet[iClient] = false;
					ReplyToCommand(iClient, "[SM] Homing Rocket Feet is now disabled to you");
				}
				else
				{
					bHasHomingFeet[iClient] = true;
					ReplyToCommand(iClient, "[SM] Homing Rocket Feet is now enabled to you");
				}
			}
			if(iArgs == 1)
			{
				
				GetCmdArg(1, arg1, sizeof(arg1));
				
				if((target_count = ProcessTargetString(arg1, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
				{
					ReplyToTargetError(iClient, target_count);
					return Plugin_Handled;
				}
				
				for(int i = 0; i < target_count; i++)
				{
					int target = target_list[i];
					
					if(!target)
						return Plugin_Handled;
					
					if(!bHasHomingFeet[target])
					{
						bHasHomingFeet[target] = true;
						ReplyToCommand(target, "[SM] Homing Rocket Feet is now enabled to you");
					}
					else
					{
						bHasHomingFeet[target] = false;
						ReplyToCommand(target, "[SM] Homing Rocket Feet is now disabled to you");
					}
				}
				ShowActivity2(iClient, "[SM] ", "Toggled Homing Rocket Feet for %s", target_name);
			}
			if(iArgs == 2)
			{
				GetCmdArg(1, arg1, sizeof(arg1));
				GetCmdArg(2, arg2, sizeof(arg2));
				
				if((target_count = ProcessTargetString(arg1, iClient, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
				{
					ReplyToTargetError(iClient, target_count);
					return Plugin_Handled;
				}
				
				for(int i = 0; i < target_count; i++)
				{
					int target = target_list[i];
					
					if(!target)
						return Plugin_Handled;
					
					if(StrEqual(arg2, "on", false) || StrEqual(arg2, "1", false))
					{
						if(!bHasHomingFeet[target])
							ReplyToCommand(target, "[SM] Homing Rocket Feet is now enabled to you");
							
						bHasHomingFeet[target] = true;	
					}
					else if(StrEqual(arg2, "off", false) || StrEqual(arg2, "0", false))
					{
						if(bHasHomingFeet[target])
							ReplyToCommand(target, "[SM] Homing Rocket Feet is now disabled to you");
						
						bHasHomingFeet[target] = false;
					}
				}
				if(StrEqual(arg2, "on", false) || StrEqual(arg2, "1", false))
				{
					ShowActivity2(iClient, "[SM] ", "Homing Rocket Feet is enabled to %s", target_name);
				}
				else if(StrEqual(arg2, "off", false) || StrEqual(arg2, "0", false))
				{
					ShowActivity2(iClient, "[SM] ", "Homing Rocket Feet is disabled to %s", target_name);
				}
			}
			if(iArgs > 2)
			{
				ReplyToCommand(iClient, "[SM] Usage: sm_homingrocketfeet\n[SM] Usage: sm_homingrocketfeet <target>\n[SM] Usage: sm_homingrocketfeet <target> <1 - enable | 0 - disable>");
				return Plugin_Handled;
			}
		}
		else
		{
			ReplyToCommand(iClient, "[SM] Cannot use the command, the owner disabled this function");
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(iClient, "[SM] Cannot use the command, plugin not enabled");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public void OnEntityCreated(int iEntity, const char[] cClassname)
{
	if(IsValidProjectiles(cClassname) && IsHomingProjectilesPresent() && bEnable)
		CreateTimer(0.2, CheckProjectilesOwner, EntIndexToEntRef(iEntity));
	
}

public Action CheckProjectilesOwner(Handle timer, any iRefEntity)
{
	int iProjectile = EntRefToEntIndex(iRefEntity);
	
	if(iProjectile <= MaxClients || !IsValidEntity(iProjectile))
		return Plugin_Stop;
		
	int iLauncher;
	
	char sClassname[32];
	GetEdictClassname(iProjectile, sClassname, sizeof(sClassname));
	
	if(StrEqual(sClassname, "tf_projectile_sentryrocket"))
		iLauncher = GetEntPropEnt(GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity"), Prop_Send, "m_hBuilder");

	else
		iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	
	if(!IsValidClient(iLauncher))
		return Plugin_Stop;

	if(!bHasHomingProjectiles[iLauncher])
		return Plugin_Stop;

	if(GetEntProp(iProjectile, Prop_Send, "m_nForceBone") != 0)
		return Plugin_Stop;

	SetEntProp(iProjectile, Prop_Send, "m_nForceBone", 1);
	
	Homing_Push(iProjectile, iHomingProjectilesMod);
	
	return Plugin_Stop;
}

public void OnGameFrame()
{
	int iData[3];
	int iProjectile, i = hArrayHomingProjectile.Length;

	while(--i >= 0)
	{
		hArrayHomingProjectile.GetArray(i, iData);
		
		if(iData[0] == 0)
		{
			hArrayHomingProjectile.Erase(i);
			continue;
		}

		iProjectile = EntRefToEntIndex(iData[0]);
		if(iProjectile > MaxClients)
			Homing_Think(iProjectile, iData[0], i, iData[1], iData[2]);
			
		else
			hArrayHomingProjectile.Erase(i);

	}
}

/*****STOCKS HOMING PROJECTILES*****/

stock void Homing_Push(int iProjectile, int iFlags=HOMING_ENEMIES)
{
	int iData[3];
	iData[0] = EntIndexToEntRef(iProjectile);
	iData[2] = iFlags;
	hArrayHomingProjectile.PushArray(iData);
}

stock void Homing_Think(int iProjectile, int iRefProjectile, int iArrayIndex, int iCurrentTarget, int iFlags)
{
	if(!Homing_IsValidTarget(iCurrentTarget, iProjectile, iFlags))
		Homing_FindTarget(iProjectile, iRefProjectile, iArrayIndex, iFlags);
		
	else 
		Homing_TurnToTarget(iCurrentTarget, iProjectile, view_as<bool>(iFlags & HOMING_SMOOTH));
}

stock bool Homing_IsValidTarget(int client, int iProjectile, int iFlags)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return false;

	int iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum"), iOwner = 0;

	iOwner = 0;
	
	
	if(iFlags & HOMING_SELF_ORIG)
		iOwner = GetLauncher(iProjectile);
		
	else
		iOwner = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");

	if(iOwner == client)
	{
		if(!(iFlags & HOMING_SELF) && !(iFlags & HOMING_SELF_ORIG))
			return false;
	}
	else
	{
		if(GetClientTeam(client) == iTeam)
		{
			if(!(iFlags & HOMING_FRIENDLIES))
				return false;
		}	
		else
		{
			if(!(iFlags & HOMING_ENEMIES))
				return false;
		}
	}
	
	if(!bCanSeeEveryone)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			return false;
	
		if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
			return false;
		
	}
	return CanEntitySeeTarget(iProjectile, client);
}

stock void Homing_FindTarget(int iProjectile, int iRefProjectile, int iArrayIndex, int iFlags)
{
	float fPos[3], fPosOther[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fPos);

	int iBestTarget = 0;
	float fBestDist = 9999999999.0;

	for(int i = 1; i <= MaxClients; ++i)
	{
		if(!Homing_IsValidTarget(i, iProjectile, iFlags))
			continue;

		GetClientEyePosition(i, fPosOther);
		float fDistance = GetVectorDistance(fPos, fPosOther, true);
		if(fDistance > fBestDist)
			continue;

		iBestTarget = i;
		fBestDist = fDistance;
	}
	
	int iData[3];
	iData[0] = iRefProjectile;
	iData[1] = iBestTarget;
	iData[2] = iFlags;
	hArrayHomingProjectile.SetArray(iArrayIndex, iData);

	if(iBestTarget)
		Homing_TurnToTarget(iBestTarget, iProjectile, view_as<bool>(iFlags & HOMING_SMOOTH));
}

stock void Homing_TurnToTarget(int client, int iProjectile, bool bSmooth=false)
{
	char sClassname[32];
	float fTargetPos[3], fRocketPos[3], fInitialVelocity[3];
	int iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	
	GetEdictClassname(iProjectile, sClassname, sizeof(sClassname));
	GetClientAbsOrigin(client, fTargetPos);
	
	float SpeedMultiplier = HOMING_SPEED_MULTIPLIER, 
		AirblastSpeedMultiplier = HOMING_AIRBLAST_MULTIPLIER;
	
	if(bHomingHead) //TODO : Improve this shit.
	{
		if(StrEqual(sClassname, "tf_projectile_arrow"))
		{
			if(bHasHomingHead[iLauncher])	
			{
				GetClientEyePosition(client, fTargetPos);
				fTargetPos[2] -= 25;
				//SpeedMultiplier = ;
				//AirblastSpeedMultiplier = ;
			}
		}
	}
	if(bHomingFeet)
	{
		if(StrEqual(sClassname, "tf_projectile_rocket") || StrEqual(sClassname, "tf_projectile_sentryrocket"))
		{
			if(StrEqual(sClassname, "tf_projectile_rocket"))
			{
				if(bHasHomingFeet[iLauncher])
					fTargetPos[2] -= 28;
			}	
			else if(StrEqual(sClassname, "tf_projectile_sentryrocket"))
			{
				int iBuilder = GetEntPropEnt(iLauncher, Prop_Send, "m_hBuilder");
				
				if(bHasHomingFeet[iBuilder])
					fTargetPos[2] -= 28;
			}
		}
	}
		
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fRocketPos);
	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", fInitialVelocity);

	float fSpeedInit = GetVectorLength(fInitialVelocity);
	float fSpeedBase = fSpeedInit *SpeedMultiplier;

	fTargetPos[2] += 30 +Pow(GetVectorDistance(fTargetPos, fRocketPos), 2.0) /10000;
	
	if(bSmooth)
		Homing_SmoothTurn(fTargetPos, fRocketPos, iProjectile);

	float fNewVec[3], fAng[3];
	SubtractVectors(fTargetPos, fRocketPos, fNewVec);
	NormalizeVector(fNewVec, fNewVec);
	GetVectorAngles(fNewVec, fAng);

	float fSpeedNew = fSpeedBase +GetEntProp(iProjectile, Prop_Send, "m_iDeflected") *fSpeedBase *AirblastSpeedMultiplier;

	ScaleVector(fNewVec, fSpeedNew);
	TeleportEntity(iProjectile, NULL_VECTOR, fAng, fNewVec);
}

stock void Homing_SmoothTurn(float fTargetPos[3], float fRocketPos[3], int iProjectile)
{
	float fDist = GetVectorDistance(fRocketPos, fTargetPos);

	float fAng[3], fFwd[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_angRotation", fAng);
	GetAngleVectors(fAng, fFwd, NULL_VECTOR, NULL_VECTOR);

	float fNewTargetPos[3];
	
	for(int i = 0; i < 3; ++i)
	{
		fNewTargetPos[i] = fRocketPos[i] + fDist *fFwd[i];
		fTargetPos[i] += (fNewTargetPos[i] -fTargetPos[i]) *0.96;
	}
}

stock int GetLauncher(int iProjectile)
{
	int iWeapon = GetEntPropEnt(iProjectile, Prop_Send, "m_hOriginalLauncher");
	
	if(iWeapon > MaxClients)
		return GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
		
	else
		return 0;
}


	/***********OTHERS***********/
stock bool IsValidProjectiles(const char[] sClassname)
{
	if(strncmp(sClassname, "tf_projectile_", 14))
		return false;

	return !strcmp(sClassname[14], "rocket")
		|| !strcmp(sClassname[14], "arrow")
		|| !strcmp(sClassname[14], "flare")
		|| !strcmp(sClassname[14], "energy_ball")
		|| !strcmp(sClassname[14], "healing_bolt")
		|| !strcmp(sClassname[14], "sentryrocket");
		//|| !strcmp(sClassname[14], "");
		
}

stock bool IsHomingProjectilesPresent()
{
	for(int i = 0; i <= MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;
			
		if(bHasHomingProjectiles[i])
			return true;
	}
	return false;
}
	
stock bool CanEntitySeeTarget(int iEnt, int iTarget)
{
	if(!iEnt) return false;

	float fStart[3], fEnd[3];
	if(IsValidClient(iEnt))
		GetClientEyePosition(iEnt, fStart);
	else GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", fStart);

	if(IsValidClient(iTarget))
		GetClientEyePosition(iTarget, fEnd);
	else GetEntPropVector(iTarget, Prop_Send, "m_vecOrigin", fEnd);

	Handle hTrace = TR_TraceRayFilterEx(fStart, fEnd, MASK_SOLID, RayType_EndPoint, TraceFilterIgnorePlayersAndSelf, iEnt);
	if(hTrace != INVALID_HANDLE){
		if(TR_DidHit(hTrace)){
			CloseHandle(hTrace);
			return false;
		}
		CloseHandle(hTrace);
	}
	return true;
}

public bool TraceFilterIgnorePlayersAndSelf(int iEntity, int iContentsMask, any iTarget){
	if(iEntity == iTarget)
		return false;

	if(1 <= iEntity <= MaxClients)
		return false;

	return true;
}

/***STOCKS***/

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}