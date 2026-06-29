/**
 * vim: set ts=4 :
 * =============================================================================
 * [TF2] Spawn Bonus Ducks
 * Allows admins to spawn bonus ducks.
 *
 * [TF2] Spawn Bonus Ducks (C)2016 404: User Not Found (UNF Gaming).
 * All rights reserved.
 *
 * Special thanks to Jessecar for the original code snippet for spawning ducks.
 * It's just a shame that the Steam servers got mildly DDoSed because of this,
 * when Jesse and Geel abused the shit out of their plugins to farm journal XP.
 * =============================================================================
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
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

float g_fPosition[3];

public Plugin myinfo = {
	name			= "[TF2] Spawn Bonus Ducks",
	author			= "404: User Not Found",
	description		= "Allows admins to spawn bonus ducks.",
	version			= PLUGIN_VERSION,
	url				= "https://www.unfgaming.net"
};

#define MODEL_DUCK "models/workshop/player/items/pyro/eotl_ducky/eotl_bonus_duck.mdl"

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] strError, int iErrMax)
{
	if(GetEngineVersion() != Engine_TF2)
	{
		Format(strError, iErrMax, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_spawnbonusducks_version", PLUGIN_VERSION, "[TF2] Spawn Bonus Ducks version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_quack", Command_Quack, ADMFLAG_CHEATS, "Usage: sm_quack <target> <# of ducks> <is quackston? (0/1 = no/yes)> (will spawn a set amount ducks where the target is standing)");
	RegAdminCmd("sm_aimquack", Command_AimQuack, ADMFLAG_CHEATS, "Usage: sm_quack <target> <# of ducks> <is quackston? (0/1 = no/yes)> (will spawn a set amount ducks where you are aiming)");
	RegAdminCmd("sm_unquack", Command_UnQuack, ADMFLAG_CHEATS, "Usage: sm_unqauck");
	
	LoadTranslations("common.phrases");
}

public void OnMapStart()
{
	PrecacheModel(MODEL_DUCK);
}

public Action Command_Quack(int iClient, int iArguments)
{
	char strTargetName[MAX_TARGET_LENGTH];
	int iTargetList[MAXPLAYERS];
	int iTargetCount;
	bool bTNISML;

	char strTarget[32];
	GetCmdArg(1, strTarget, sizeof(strTarget));
	
	char strDuckCount[3];
	GetCmdArg(2, strDuckCount, sizeof(strDuckCount));
	int iDuckCount = StringToInt(strDuckCount);
	
	char strQuackston[1];
	GetCmdArg(3, strQuackston, sizeof(strQuackston));
	int iQuackston = StringToInt(strQuackston);
	
	if(iArguments < 3 || iArguments > 3)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_quack <target> <# of ducks to spawn> <are ducks Quackston? (0/1 - 0: No, 1: Yes)");
		return Plugin_Handled;
	}
	if(iDuckCount <= 0 || iDuckCount > 100)
	{
		ReplyToCommand(iClient, "[SM] Invalid amount entered for argument #2 (Accepted # of ducks to spawn: 1 - 100)");
		return Plugin_Handled;
	}
	if(iQuackston < 0 || iQuackston > 1)
	{
		ReplyToCommand(iClient, "[SM] Invalid value entered for argument #3 (Accepted values: 0 - 1 (0 = normal ducks, 1 = Quackston ducks)");
		return Plugin_Handled;
	}
	if((iTargetCount = ProcessTargetString(strTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE, strTargetName, sizeof(strTargetName), bTNISML)) <= 0)
	{
		ReplyToTargetError(iClient, iTargetCount);
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		ReplyToCommand(iClient, "[SM] Too many entities have been spawned! Cannot spawn new ducks! Try reloading the map.");
		return Plugin_Handled;
	}
	
	for(int i = 0; i < iTargetCount; i++)
	{
		SpawnDuck(iTargetList[i], iDuckCount, iQuackston);
	}	
	return Plugin_Handled;
}

public Action Command_AimQuack(int iClient, int iArguments)
{
	if(!IsPlayerAlive(iClient))
	{
		ReplyToCommand(iClient, "[SM] This command cannot be run while you are dead.");
		return Plugin_Handled;
	}
	if(!IsClientInGame(iClient))
	{
		ReplyToCommand(iClient, "[SM] This command cannot be run from the console.");
		return Plugin_Handled;
	}

	char strDuckCount[3];
	GetCmdArg(1, strDuckCount, sizeof(strDuckCount));
	int iDuckCount = StringToInt(strDuckCount);
	
	char strQuackston[1];
	GetCmdArg(2, strQuackston, sizeof(strQuackston));
	int iQuackston = StringToInt(strQuackston);
	
	if(iArguments < 2 || iArguments > 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_aimquack <# of ducks to spawn> <are ducks Quackston? (0/1 - 0: No, 1: Yes)");
		return Plugin_Handled;
	}
	if(iDuckCount <= 0 || iDuckCount > 100)
	{
		ReplyToCommand(iClient, "[SM] Invalid amount entered for argument #1 (Accepted # of ducks to spawn: 1 - 100)");
		return Plugin_Handled;
	}
	if(iQuackston < 0 || iQuackston > 1)
	{
		ReplyToCommand(iClient, "[SM] Invalid value entered for argument #2 (Accepted values: 0 - 1 (0 = normal ducks, 1 = Quackston ducks)");
		return Plugin_Handled;
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		ReplyToCommand(iClient, "[SM] Too many entities have been spawned! Cannot spawn new ducks! Try reloading the map.");
		return Plugin_Handled;
	}
	if(!SetTeleportEndPoint(iClient))
	{
		ReplyToCommand(iClient, "[SM] Could not find spawn point for bonus ducks.");
		return Plugin_Handled;
	}
	
	SpawnDuckAtCrosshair(iClient, iDuckCount, iQuackston);
	
	return Plugin_Handled;
}

public Action Command_UnQuack(int iClient, int iArguments)
{
	RemoveAllEntitiesByClassname("tf_bonus_duck_pickup");

	return Plugin_Handled;
}

stock void SpawnDuck(int iClient, int iSpawnCount = 1, int iIsQuackston = 0)
{
	float fDuckPosition[3];
	GetClientAbsOrigin(iClient, fDuckPosition);
	
	for(int i = 0; i < iSpawnCount; i++)
	{
		int iDuck = CreateEntityByName("tf_bonus_duck_pickup");
		SetEntityModel(iDuck, MODEL_DUCK);
		
		if(iIsQuackston == 1)
		{
			SetEntProp(iDuck, Prop_Send, "m_bSpecial", 1);
			SetEntProp(iDuck, Prop_Send, "m_nSkin", 21);
		}
		else
		{
			TFClassType iClass = TF2_GetPlayerClass(iClient);
			TFTeam iTeam = TF2_GetClientTeam(iClient);
			switch(iClass)
			{
				case TFClass_Scout:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 3);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 12);
					}
				}
				case TFClass_Sniper:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 4);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 13);
					}
				}
				case TFClass_Soldier:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 5);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 14);
					}
				}
				case TFClass_DemoMan:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 6);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 15);
					}
				}
				case TFClass_Medic:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 7);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 16);
					}
				}
				case TFClass_Heavy:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 8);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 17);
					}
				}
				case TFClass_Pyro:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 9);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 18);
					}
				}
				case TFClass_Spy:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 10);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 19);
					}
				}
				case TFClass_Engineer:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 11);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 20);
					}
				}
			}
		}
		DispatchKeyValue(iDuck, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(iDuck);
		TeleportEntity(iDuck, fDuckPosition, NULL_VECTOR, NULL_VECTOR); 
	}
}

stock void SpawnDuckAtCrosshair(int iClient, int iSpawnCount = 1, int iIsQuackston = 0)
{
	float fStart[3];
	float fAngle[3];
	float fEnd[3]; 
	GetClientEyePosition(iClient, fStart); 
	GetClientEyeAngles(iClient, fAngle); 
	TR_TraceRayFilter(fStart, fAngle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, iClient); 
	if(TR_DidHit(INVALID_HANDLE)) 
	{	 
		TR_GetEndPosition(fEnd, INVALID_HANDLE); 
	}
	
	for(int i = 0; i < iSpawnCount; i++)
	{
		int iDuck = CreateEntityByName("tf_bonus_duck_pickup");
		SetEntityModel(iDuck, MODEL_DUCK);
		
		if(iIsQuackston == 1)
		{
			SetEntProp(iDuck, Prop_Send, "m_bSpecial", 1);
			SetEntProp(iDuck, Prop_Send, "m_nSkin", 21);
		}
		else
		{
			TFClassType iClass = TF2_GetPlayerClass(iClient);
			TFTeam iTeam = TF2_GetClientTeam(iClient);
			switch(iClass)
			{
				case TFClass_Scout:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 3);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 12);
					}
				}
				case TFClass_Sniper:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 4);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 13);
					}
				}
				case TFClass_Soldier:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 5);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 14);
					}
				}
				case TFClass_DemoMan:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 6);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 15);
					}
				}
				case TFClass_Medic:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 7);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 16);
					}
				}
				case TFClass_Heavy:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 8);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 17);
					}
				}
				case TFClass_Pyro:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 9);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 18);
					}
				}
				case TFClass_Spy:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 10);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 19);
					}
				}
				case TFClass_Engineer:
				{
					if(iTeam == TFTeam_Red)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 11);
					}
					else if(iTeam == TFTeam_Blue)
					{
						SetEntProp(iDuck, Prop_Send, "m_nSkin", 20);
					}
				}
			}
		}
		DispatchKeyValue(iDuck, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(iDuck);
		TeleportEntity(iDuck, fEnd, NULL_VECTOR, NULL_VECTOR); 
	}
}

stock void RemoveAllEntitiesByClassname(char[] strClassname)
{
	int iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, strClassname)) != -1)
	{
		PrintToServer("classname(%s) %i", strClassname, iEntity);
		AcceptEntityInput(iEntity, "Kill");
	}
}

bool SetTeleportEndPoint(int iClient)
{
	float fVectorAngles[3];
	float fVectorOrigin[3];
	float fVectorBuffer[3];
	float fVectorStart[3];
	float fDistance;

	GetClientEyePosition(iClient, fVectorOrigin);
	GetClientEyeAngles(iClient, fVectorAngles);

	Handle hTrace = TR_TraceRayFilterEx(fVectorOrigin, fVectorAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(hTrace))
	{
		TR_GetEndPosition(fVectorStart, hTrace);
		GetVectorDistance(fVectorOrigin, fVectorStart, false);
		fDistance = -35.0;
		GetAngleVectors(fVectorAngles, fVectorBuffer, NULL_VECTOR, NULL_VECTOR);
		g_fPosition[0] = fVectorStart[0] + (fVectorBuffer[0]*fDistance);
		g_fPosition[1] = fVectorStart[1] + (fVectorBuffer[1]*fDistance);
		g_fPosition[2] = fVectorStart[2] + (fVectorBuffer[2]*fDistance);
	}
	else
	{
		CloseHandle(hTrace);
		return false;
	}

	CloseHandle(hTrace);
	return true;
}

// Function: Trace Entity, Filter Player
public bool TraceEntityFilterPlayer(int iEntity, int iContentsMask)
{
	return iEntity > GetMaxClients() || !iEntity;
}