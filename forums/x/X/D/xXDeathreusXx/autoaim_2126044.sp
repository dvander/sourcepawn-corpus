////////////////////////
// Table of contents: //
/////// Commands ///////
//////// Events ////////
//////// Stocks ////////
////////////////////////


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_NAME  "Auto Aim"
#define PLUGIN_VERSION  "0.3"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Deathreus, snippets from ReFlexPoison and javalia and friagram",
	description = "Long story short, it's an aimbot",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=238529"
}

new bool:g_bToHead[MAXPLAYERS+1];
new Handle:g_hCvarEnabled;
new bool:g_bCvarEnabled;
/*new Handle:g_hCvarAimAndShoot;
new bool:g_bCvarAimAndShoot;*/
new g_bAutoAiming[MAXPLAYERS+1] = {false, ...};

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
	CreateConVar("sm_autoaim_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_autoaim_enabled", "1", "Enable Aimbot?(As if you'd want if off)\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	/*g_hCvarAimAndShoot = CreateConVar("sm_autoaim_aimandshoot", "0", "Aim and automatically shoot?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0);
	g_bCvarAimAndShoot = GetConVarBool(g_hCvarAimAndShoot);
	HookConVarChange(g_hCvarAimAndShoot, OnConVarChange);*/

	RegAdminCmd("sm_autoaim", AutoAimCmd, ADMFLAG_GENERIC);
	RegAdminCmd("sm_aim", AutoAimCmd, ADMFLAG_GENERIC);		// Convenience purposes only

	/*for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		OnClientConnected(i);*/
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
	/*if(convar == g_hCvarAimAndShoot)
		g_bCvarAimAndShoot = bool:StringToInt(newValue);*/
}

public OnClientDisconnect(client)
{
	g_bAutoAiming[client] = false;
}

/*public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(!g_bCvarEnabled || !IsValidClient(client) || !g_bAutoAiming[client]) 
		return Plugin_Continue;

	switch(iItemDefinitionIndex)
	{
		case 14, 201, 230, 402, 526, 664, 752, 792, 801, 851, 881, 890, 899, 908, 957, 966:		// ALL the rifles
		{
			g_bToHead[client] = true;
		}
		case 61, 1006:	// Both Ambassador's
		{
			g_bToHead[client] = true;
		}
		default:
		{
			g_bToHead[client] = false;
		}
	}

	return Plugin_Continue;
}*/

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:velocity[3], Float:angles[3], &weapon)
{
	if(!g_bCvarEnabled || !g_bAutoAiming[client])
		return Plugin_Continue;

	if(!IsPlayerAlive(client) || !IsClientInGame(client))
		return Plugin_Continue;

	new iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(iCurrentWeapon == -1)
		return Plugin_Continue;

	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class == TFClass_Sniper
	|| (class == TFClass_Spy
	&& (GetEntProp(iCurrentWeapon, Prop_Send, "m_iItemDefinitionIndex")==61
	|| GetEntProp(iCurrentWeapon, Prop_Send, "m_iItemDefinitionIndex")==1006)))
		g_bToHead[client] = true;
	else
		g_bToHead[client] = false;

	decl Float:fClientEyePosition[3], Float:fAngles[3], Float:anglevector[3],/*Float:targetvector[3],*/ Float:vecrt[3];
	GetClientEyePosition(client, fClientEyePosition);
	GetClientEyeAngles(client, fAngles);

	GetAngleVectors(fAngles, anglevector, vecrt, NULL_VECTOR);

	if(IsValidClient(client))
	{
		//TR_GetEndPosition(targetvector);

		new iClosest = GetClosestClient(client);
		/*if(!IsValidClient(iClosest))
			return Plugin_Continue;*/

		decl Float:fClosestLocation[3];
		GetClientAbsOrigin(iClosest, fClosestLocation);
		fClosestLocation[2] += 33.5;
		
		if(!g_bToHead[client])
			fClosestLocation[2] = fClosestLocation[2] - 15.0;
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

		TeleportEntity(client, NULL_VECTOR, fAngle, NULL_VECTOR);
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
	for(new i = 1; i < MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) != clientteam && IsPlayerAlive(i) && i != iClient)
		{
			GetClientAbsOrigin(i, fEntityOrigin);
			fEntityDistance = GetVectorDistance(fClientLocation, fEntityOrigin);
			if((fEntityDistance < fClosestDistance) || fClosestDistance == -1.0)
			{
				if(CanSeeTarget(fClientLocation, fEntityOrigin, i, clientteam))
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