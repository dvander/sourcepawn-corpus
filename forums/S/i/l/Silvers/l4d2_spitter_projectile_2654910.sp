/*
*	Spitter Projectile Creator
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.2"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Spitter Projectile Creator
*	Author	:	SilverShot
*	Descrp	:	Provides two commands to creates the Spitter projectile and drop the Spitter goo.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=316763
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (10-Aug-2021)
	- Returns an error message if the commands are used via server console.

1.1 (10-May-2020)
	- Added better error log message when gamedata file is missing.
	- Various changes to tidy up code.

1.0 (09-Jun-2019)
	- Initial release.

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified SetTeleportEndPoint function.
	https://forums.alliedmods.net/showthread.php?t=109659

*	"Timocop" for "L4D2_RunScript" function.
	https://forums.alliedmods.net/showpost.php?p=2585717&postcount=2

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define GAMEDATA		"l4d2_spitter_projectile"



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Spitter Projectile Creator",
	author = "SilverShot",
	description = "Provides two commands to creates the Spitter projectile and drop the Spitter goo.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=316763"
}

Handle sdkActivateSpit, g_hSpitVelocity;

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Static);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CSpitterProjectile_Create") == false )
		SetFailState("Could not load the \"CSpitterProjectile_Create\" gamedata signature.");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	sdkActivateSpit = EndPrepSDKCall();
	if( sdkActivateSpit == null )
		SetFailState("Could not prep the \"CSpitterProjectile_Create\" function.");

	delete hGameData;

	CreateConVar("l4d2_spitter_projectile_version", PLUGIN_VERSION, "Spitter Projectile plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hSpitVelocity = FindConVar("z_spit_velocity");

	RegAdminCmd("sm_spitter_prj", Command_SpitterPrj, ADMFLAG_ROOT, "Shoots the Spitter projectile from yourself to where you're aiming.");
	RegAdminCmd("sm_spitter_goo", Command_SpitterGoo, ADMFLAG_ROOT, "Drops Spitter goo where you're aiming the crosshair.");
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
public Action Command_SpitterPrj(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	float vPos[3], vAng[3];
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);
	GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAng, vAng);
	ScaleVector(vAng, GetConVarFloat(g_hSpitVelocity));

	SDKCall(sdkActivateSpit, vPos, vAng, vAng, vAng, client);

	// If you want the projectile entity index, for example to set the owner.
	// int entity = SDKCall(sdkActivateSpit, vPos, vAng, vAng, vAng, client);
	// SetEntPropEnt(entity, Prop_Data, "m_hThrower", -1);
	return Plugin_Handled;
}

public Action Command_SpitterGoo(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "Cannot place Spitter Goo, please try again.");
		return Plugin_Handled;
	}

	L4D2_RunScript("DropSpit(Vector(%f %f %f))", vPos[0], vPos[1], vPos[2]);
	return Plugin_Handled;
}



// ====================================================================================================
//					STOCKS
// ====================================================================================================
bool SetTeleportEndPoint(int client, float vPos[3], float vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		float vNorm[3];
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vNorm);
		float angle = vAng[1];
		GetVectorAngles(vNorm, vAng);

		vPos[2] += 5.0;

		if( vNorm[2] == 1.0 )
		{
			vAng[0] = 0.0;
			vAng[1] += angle;
		}
		else
		{
			vAng[0] = 0.0;
			vAng[1] += angle - 90.0;
		}
	}
	else
	{
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}



/**
* Runs a single line of VScript code.
* NOTE: Dont use the "script" console command, it starts a new instance and leaks memory. Use this instead!
*
* @param sCode        The code to run.
* @noreturn
*/
stock void L4D2_RunScript(char[] sCode, any ...)
{
    static int iScriptLogic = INVALID_ENT_REFERENCE;
    if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
	{
        iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
        if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
            SetFailState("Could not create 'logic_script'");

        DispatchSpawn(iScriptLogic);
    }

    char sBuffer[64];
    VFormat(sBuffer, sizeof(sBuffer), sCode, 2);

    SetVariantString(sBuffer);
    AcceptEntityInput(iScriptLogic, "RunScriptCode");
}