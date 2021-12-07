#pragma semicolon 1

#define PLUGIN_VERSION "1.0.2"

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

bool		bHasHomingProjectiles[MAXPLAYERS+1], 
		bHasHomingHead[MAXPLAYERS+1], 
		bHasHomingFeet[MAXPLAYERS+1];
		
/*******FOR CONSOLE VARIABLES*******/
ConVar	hEnable, 
		hHomingForAll, 
		hHomingForAllHead, 
		hHomingForAllFeet, 
		hCanSeeEveryone, 
		hHomingProjectilesMod, 
		hHomingHead, 
		hHomingFeet, 
		hHomingSpeed, 
		hHomingReflectSpeed;
		
bool		bEnable, 
		bHomingForAll, 
		bHomingForAllHead, 
		bHomingForAllFeet, 
		bCanSeeEveryone, 
		bHomingHead, 
		bHomingFeet;
		
float		HOMING_SPEED_MULTIPLIER = 0.5, 
		HOMING_AIRBLAST_MULTIPLIER = 1.1;
/**********************************************/
		
/*#define HOMING_SPEED_MULTIPLIER 0.5		UPDATED !!!!!!
#define HOMING_AIRBLAST_MULTIPLIER 1.1*/	
	
int iHomingProjectilesMod;
ArrayList hArrayHomingProjectile = null;

#define HOMING_NONE 0
#define HOMING_SELF (1 << 0) // rocket's owner					index : 1
#define HOMING_SELF_ORIG (1 << 1) // original launcher's owner		index : 2
#define HOMING_ENEMIES (1 << 2) // enemies of owner				index : 4
#define HOMING_FRIENDLIES (1 << 3) // friendlies of owner			index : 8
#define HOMING_SMOOTH (1 << 4) // smooths the turning			index : 16

Handle	hHLookupBone, 
		hHGetBonePosition;

public void OnPluginStart()
{
	RegisterCmds();
	RegisterCvars();
	
	AutoExecConfig(true, "HomingProjectiles");
	
	HookEvent("teamplay_round_start", RoundStart);
	
	LoadTranslations("common.phrases");
	
	///////////////////////////////////////////////////////////////////////////////////////////////////////****TAKEN FROM A PELIPOIKA'S PLUGIN****///////////////////////////////////////////////////////////////////////////////////////////////////////
	//int CBaseAnimating::LookupBone( const char *szName )
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x56\x8B\xF1\x80\xBE\x41\x03\x00\x00\x00\x75\x2A\x83\xBE\x6C\x04\x00\x00\x00\x75\x2A\xE8\x2A\x2A\x2A\x2A\x85\xC0\x74\x2A\x8B\xCE\xE8\x2A\x2A\x2A\x2A\x8B\x86\x6C\x04\x00\x00\x85\xC0\x74\x2A\x83\x38\x00\x74\x2A\xFF\x75\x08\x50\xE8\x2A\x2A\x2A\x2A\x83\xC4\x08\x5E", 68);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	if ((hHLookupBone = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed to create SDKCall for CBaseAnimating::LookupBone signature!");
	
	//void CBaseAnimating::GetBonePosition ( int iBone, Vector &origin, QAngle &angles )
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetSignature(SDKLibrary_Server, "\x55\x8B\xEC\x83\xEC\x30\x56\x8B\xF1\x80\xBE\x41\x03\x00\x00\x00", 16);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	if ((hHGetBonePosition = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed to create SDKCall for CBaseAnimating::GetBonePosition signature!");
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}

void RegisterCmds()
{
	RegAdminCmd("sm_homingprojectiles", Command_HomingProjectiles, ADMFLAG_SLAY, "Toggle Homing Projectiles");
	RegAdminCmd("sm_homing", Command_HomingProjectiles, ADMFLAG_SLAY, "Toggle Homing Projectiles");
	
	RegAdminCmd("sm_homingarrowhead", Command_HomingHead, ADMFLAG_SLAY, "Toggle Homing Arrow to target head");
	RegAdminCmd("sm_hominghead", Command_HomingHead, ADMFLAG_SLAY, "Toggle Homing Arrow to target head");
	
	RegAdminCmd("sm_homingrocketfeet", Command_HomingFeet, ADMFLAG_SLAY, "Toggle Homing Rocket to target feet");
	RegAdminCmd("sm_homingfeet", Command_HomingFeet, ADMFLAG_SLAY, "Toggle Homing Rocket to target feet");
	
	RegAdminCmd("sm_homingremoveall", Command_HomingRemoveAll, ADMFLAG_SLAY, "Remove All Homing Projectiles");
}

void RegisterCvars()
{
	CreateConVar("sm_homingprojectiles_version", PLUGIN_VERSION, "[TF2] Homing Projectiles Version", FCVAR_NOTIFY | FCVAR_SPONLY);
	
	hEnable = CreateConVar("sm_homingprojectiles_enable", "1", "Enable/Disable \"Homing Projectiles\" Plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hEnable.AddChangeHook(ConVarChanged);
	
	hHomingForAll = CreateConVar("sm_homingprojectiles_all", "0", "Enable/Disable Homing Projectiles for all", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hHomingForAll.AddChangeHook(ConVarChanged);
	
	hHomingForAllHead = CreateConVar("sm_homingprojectiles_allhead", "0", "Enable/Disable Homing Arrow Head for all", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hHomingForAllHead.AddChangeHook(ConVarChanged);
	
	hHomingForAllFeet = CreateConVar("sm_homingprojectiles_allfeet", "0", "Enable/Disable Homing Rocket Feet for all", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hHomingForAllFeet.AddChangeHook(ConVarChanged);
	
	hCanSeeEveryone = CreateConVar("sm_homingprojectiles_canseeeveryone", "0", "If projectiles can attack/see invisible/disguised spies", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hCanSeeEveryone.AddChangeHook(ConVarChanged);
	
	hHomingProjectilesMod = CreateConVar("sm_homingprojectiles_mod", "4", "Homing Projectiles Mod ||| 0 - No Mod (no Homing Projectiles)\n1 - Target the owner\n2 - Target the real owner (for example if pyro airblast the proj. , it's the real owner and not the pyro will get the proj.)\n4 - Target enemies\n8 - Target allies\n16 - Smooth Rocket Movements (Useless alone. Also, the rocket will lose a little his precision)\nYou can have more than 1 mod by adding the value(example : 20 = 16 + 4 = Target enemies + Smooth Rocket Movements)", FCVAR_NOTIFY, true, 0.0, true, 31.0);
	hHomingProjectilesMod.AddChangeHook(ConVarChanged);
	
	hHomingHead = CreateConVar("sm_homingprojectiles_head", "1", "Enable/Disable command that toggle Homing Arrow Head ", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hHomingHead.AddChangeHook(ConVarChanged);
	
	hHomingFeet = CreateConVar("sm_homingprojectiles_feet", "1", "Enable/Disable command that toggle Homing Rocket Feet ", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	hHomingFeet.AddChangeHook(ConVarChanged);
	
	hHomingSpeed = CreateConVar("sm_homingprojectiles_speed", "0.5", "The Homing Projectile speed multiplier", FCVAR_NOTIFY, true, 0.0);
	hHomingSpeed.AddChangeHook(ConVarChanged);
	
	hHomingReflectSpeed = CreateConVar("sm_homingprojectiles_reflectspeed", "1.1", "The Homing Projectile reflected speed multiplier", FCVAR_NOTIFY, true, 0.0);
	hHomingReflectSpeed.AddChangeHook(ConVarChanged);
}

public void OnClientPutInServer(int iClient)
{
	bHasHomingProjectiles[iClient] = bHomingForAll;
	bHasHomingHead[iClient] = bHomingForAllHead;
	bHasHomingFeet[iClient] = bHomingForAllFeet;
}

public void OnClientDisconnect(int iClient)
{
	bHasHomingProjectiles[iClient] = bHomingForAll;
	bHasHomingHead[iClient] = bHomingForAllHead;
	bHasHomingFeet[iClient] = bHomingForAllFeet;
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

public Action RoundStart(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
	hArrayHomingProjectile.Clear();
	return Plugin_Continue;
}

public void ConVarChanged(ConVar hConvar, const char[] oldValue, const char[] newValue)
{
	if(hConvar == hEnable)
		bEnable = view_as<bool>(StringToInt(newValue));
	
	if(hConvar == hHomingForAll)
	{
		for(int iClient = 0; iClient <= MaxClients; iClient++)
			if(IsValidClient(iClient))
				bHasHomingProjectiles[iClient] = view_as<bool>(StringToInt(newValue));
				
	}
	
	if(hConvar == hHomingForAllHead)
	{
		for(int iClient = 0; iClient <= MaxClients; iClient++)
			if(IsValidClient(iClient))
				bHasHomingHead[iClient] = view_as<bool>(StringToInt(newValue));
				
	}
	
	if(hConvar == hHomingForAllFeet)
	{
		for(int iClient = 0; iClient <= MaxClients; iClient++)
			if(IsValidClient(iClient))
				bHasHomingFeet[iClient] = view_as<bool>(StringToInt(newValue));
				
	}
	
	if(hConvar == hCanSeeEveryone)
		bCanSeeEveryone = view_as<bool>(StringToInt(newValue));
	
	if(hConvar == hHomingProjectilesMod)
		iHomingProjectilesMod = StringToInt(newValue);
	
	if(hConvar == hHomingHead)
		bHomingHead = view_as<bool>(StringToInt(newValue));
	
	if(hConvar == hHomingFeet)
		bHomingFeet = view_as<bool>(StringToInt(newValue));
	
	if(hConvar == hHomingSpeed)
		HOMING_SPEED_MULTIPLIER = StringToFloat(newValue);
		
	if(hConvar == hHomingReflectSpeed)
		HOMING_AIRBLAST_MULTIPLIER = StringToFloat(newValue);
		
}

public void OnConfigsExecuted()
{
	bEnable = hEnable.BoolValue;
	bHomingForAll = hHomingForAll.BoolValue;
	bHomingForAllHead = hHomingForAllHead.BoolValue;
	bHomingForAllFeet = hHomingForAllFeet.BoolValue;
	bCanSeeEveryone = hCanSeeEveryone.BoolValue;
	iHomingProjectilesMod = hHomingProjectilesMod.IntValue;
	bHomingHead = hHomingHead.BoolValue;
	bHomingFeet = hHomingFeet.BoolValue;
}

public Action Command_HomingProjectiles(int iClient, int iArgs)
{
	if(bEnable)
	{
		char arg1[MAX_NAME_LENGTH], arg2[4], target_name[MAX_TARGET_LENGTH];
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
			char arg1[MAX_NAME_LENGTH], arg2[4], target_name[MAX_TARGET_LENGTH];
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
			char arg1[MAX_NAME_LENGTH], arg2[4], target_name[MAX_TARGET_LENGTH];
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

public Action Command_HomingRemoveAll(int iClient, int iArgs)
{
	if(bEnable)
	{
		char arg1[MAX_NAME_LENGTH], target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		
		if(!iClient && !iArgs)
		{
			ReplyToCommand(iClient, "[SM] Usage in server console: sm_homingremoveall <target>\n");
			return Plugin_Handled;
		}
		if(!iArgs)
		{
			if(bHasHomingProjectiles[iClient] || bHasHomingHead[iClient] || bHasHomingFeet[iClient])
			{
				bHasHomingFeet[iClient] = false;
				bHasHomingProjectiles[iClient] = false;
				bHasHomingHead[iClient] = false;
				
				ReplyToCommand(iClient, "[SM] Removed every Homing Projectiles you had");
			}
			else
			{
				ReplyToCommand(iClient, "[SM] You don't have any Homing Projectiles");
				return Plugin_Handled;
			}
		}
		else
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
					
				if(bHasHomingProjectiles[target] || bHasHomingHead[target] || bHasHomingFeet[target])
				{
					bHasHomingFeet[target] = false;
					bHasHomingProjectiles[target] = false;
					bHasHomingHead[target] = false;
					
					ReplyToCommand(target, "[SM] Removed every Homing Projectiles you had");
				}
			}
			ShowActivity2(iClient, "[SM] ", "Removed every Homing Projectiles to %s", target_name);
		}
		if(iArgs > 1)
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_homingremoveall\n[SM] Usage: sm_homingremoveall <target>");
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

	if(!bHasHomingProjectiles[iLauncher] && !bHasHomingHead[iLauncher] && !bHasHomingFeet[iLauncher])
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
	
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", fRocketPos);
	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", fInitialVelocity);

	float fSpeedInit = GetVectorLength(fInitialVelocity);
	float fSpeedBase = fSpeedInit *HOMING_SPEED_MULTIPLIER;
	
	if(bHomingHead) //TODO : Improve this code.
	{
		if(StrEqual(sClassname, "tf_projectile_arrow"))
		{
			if(bHasHomingHead[iLauncher])	
			{
				//GetClientEyePosition(client, fTargetPos);
				//fTargetPos[2] -= 25;
				int iHead = LookupBone(client, "bip_head");
				
				if(iHead != 1)
				{
					float fNothing[3];
					GetBonePosition(client, iHead, fTargetPos, fNothing);
					fTargetPos[2] -= 30;
				}
			}
		}
	}
	if(bHomingFeet)
	{
		if(StrEqual(sClassname, "tf_projectile_rocket") || StrEqual(sClassname, "tf_projectile_sentryrocket") || StrEqual(sClassname, "tf_projectile_energy_ball"))
		{
			if(StrEqual(sClassname, "tf_projectile_rocket") || StrEqual(sClassname, "tf_projectile_energy_ball"))
			{
				if(bHasHomingFeet[iLauncher])
					fTargetPos[2] -= 30;
			}	
			else if(StrEqual(sClassname, "tf_projectile_sentryrocket"))
			{
				int iBuilder = GetEntPropEnt(iLauncher, Prop_Send, "m_hBuilder");
				
				if(bHasHomingFeet[iBuilder])
					fTargetPos[2] -= 30;
			}
		}
	}

	fTargetPos[2] += 30 +Pow(GetVectorDistance(fTargetPos, fRocketPos), 2.0) /10000;
	
	if(bSmooth)
		Homing_SmoothTurn(fTargetPos, fRocketPos, iProjectile);

	float fNewVec[3], fAng[3];
	SubtractVectors(fTargetPos, fRocketPos, fNewVec);
	NormalizeVector(fNewVec, fNewVec);
	GetVectorAngles(fNewVec, fAng);

	float fSpeedNew = fSpeedBase +GetEntProp(iProjectile, Prop_Send, "m_iDeflected") *fSpeedBase *HOMING_AIRBLAST_MULTIPLIER;

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

stock int LookupBone(int iEntity, const char[] szName)
{
	return SDKCall(hHLookupBone, iEntity, szName);
}

stock void GetBonePosition(int iEntity, int iBone, float origin[3], float angles[3])
{
	SDKCall(hHGetBonePosition, iEntity, iBone, origin, angles);
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
			
		if(bHasHomingProjectiles[i] || bHasHomingHead[i] || bHasHomingFeet[i])
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