/*
 * Bunnyhop Statistics API - Plugin
 * by: shavit
 *
 * This file is part of Bunnyhop Statistics API.
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
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <bhopstats>

#pragma newdecls required
#pragma semicolon 1

Handle gH_Forwards_OnJumpPressed = null;
Handle gH_Forwards_OnJumpReleased = null;
Handle gH_Forwards_OnTouchGround = null;
Handle gH_Forwards_OnLeaveGround = null;

bool gB_OnGround[MAXPLAYERS+1];
bool gB_PlayerTouchingGround[MAXPLAYERS+1];

int gI_Scrolls[MAXPLAYERS+1];
int gI_Buttons[MAXPLAYERS+1];
bool gB_JumpHeld[MAXPLAYERS+1];

int gI_Jumps[MAXPLAYERS+1];
int gI_PerfectJumps[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Bunnyhop Statistics API",
	author = "shavit",
	description = "A SourceMod API that provides bhop related statistics for use in other plugins.",
	version = BHOPSTATS_VERSION,
	url = "https://github.com/shavitush/bhopstats"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// natives
	CreateNative("Bunnyhop_GetScrollCount", Native_GetScrollCount);
	CreateNative("Bunnyhop_IsOnGround", Native_IsOnGround);
	CreateNative("Bunnyhop_IsHoldingJump", Native_IsHoldingJump);
	CreateNative("Bunnyhop_GetPerfectJumps", Native_GetPerfectJumps);
	CreateNative("Bunnyhop_ResetPerfectJumps", Native_ResetPerfectJumps);

	// registers library, check "bool LibraryExists(const char[] name)" in order to use with other plugins
	RegPluginLibrary("bhopstats");

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("bhopstats_version", BHOPSTATS_VERSION, "Plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	gH_Forwards_OnJumpPressed = CreateGlobalForward("Bunnyhop_OnJumpPressed", ET_Event, Param_Cell, Param_Cell);
	gH_Forwards_OnJumpReleased = CreateGlobalForward("Bunnyhop_OnJumpReleased", ET_Event, Param_Cell, Param_Cell);
	gH_Forwards_OnTouchGround = CreateGlobalForward("Bunnyhop_OnTouchGround", ET_Event, Param_Cell);
	gH_Forwards_OnLeaveGround = CreateGlobalForward("Bunnyhop_OnLeaveGround", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	gB_OnGround[client] = false;
	gB_PlayerTouchingGround[client] = false;

	gI_Scrolls[client] = 0;
	gI_Buttons[client] = 0;
	gB_JumpHeld[client] = false;

	gI_Jumps[client] = 0;
	gI_PerfectJumps[client] = 0;

	SDKHook(client, SDKHook_PostThinkPost, PostThinkPost);
}

public int Native_GetScrollCount(Handle handler, int numParams)
{
	return gI_Scrolls[GetNativeCell(1)];
}

public int Native_IsOnGround(Handle handler, int numParams)
{
	return view_as<int>(gB_OnGround[GetNativeCell(1)]);
}

public int Native_IsHoldingJump(Handle handler, int numParams)
{
	return view_as<int>(gI_Buttons[GetNativeCell(1)] & IN_JUMP);
}

public int Native_GetPerfectJumps(Handle handler, int numParams)
{
	int client = GetNativeCell(1);

	return view_as<int>((float(gI_PerfectJumps[client]) / gI_Jumps[client]) * 100.0);
}

public int Native_ResetPerfectJumps(Handle handler, int numParams)
{
	int client = GetNativeCell(1);

	gI_Jumps[client] = 0;
	gI_PerfectJumps[client] = 0;
}

public void PostThinkPost(int client)
{
	if(!IsPlayerAlive(client))
	{
		return;
	}

	int buttons = GetClientButtons(client);
	bool bOldOnGround = gB_OnGround[client];

	int iGroundEntity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	bool bOnLadder = (GetEntityMoveType(client) == MOVETYPE_LADDER);
	gB_OnGround[client] = (iGroundEntity != -1 || GetEntProp(client, Prop_Send, "m_nWaterLevel") >= 2 || bOnLadder);

	gB_JumpHeld[client] = (buttons & IN_JUMP && !(gI_Buttons[client] & IN_JUMP));

	if(gB_PlayerTouchingGround[client] && gB_OnGround[client])
	{
		Call_StartForward(gH_Forwards_OnTouchGround);
		Call_PushCell(client);
		Call_Finish();

		gB_PlayerTouchingGround[client] = false;
	}

	else if(!gB_PlayerTouchingGround[client] && ((gB_JumpHeld[client] && iGroundEntity != -1) || iGroundEntity == -1 || bOnLadder))
	{
		Call_StartForward(gH_Forwards_OnLeaveGround);
		Call_PushCell(client);
		Call_PushCell(gB_JumpHeld[client]);
		Call_PushCell(bOnLadder);
		Call_Finish();

		gB_PlayerTouchingGround[client] = true;
		gI_Scrolls[client] = 0;
	}

	if(gB_JumpHeld[client])
	{
		gI_Scrolls[client]++;

		Call_StartForward(gH_Forwards_OnJumpPressed);
		Call_PushCell(client);
		Call_PushCell(gB_OnGround[client]);
		Call_Finish();

		if(gB_OnGround[client])
		{
			gI_Jumps[client]++;

			if(!bOldOnGround)
			{
				gI_PerfectJumps[client]++;
			}
		}
	}

	else if(gI_Buttons[client] & IN_JUMP && !(buttons & IN_JUMP))
	{
		Call_StartForward(gH_Forwards_OnJumpReleased);
		Call_PushCell(client);
		Call_PushCell(gB_OnGround[client]);
		Call_Finish();
	}

	gI_Buttons[client] = buttons;
}
