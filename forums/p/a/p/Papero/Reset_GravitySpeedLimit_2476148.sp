 //Compiler Options
//#pragma newdecls required
#pragma semicolon 1
#pragma tabsize 0

//Defines

#define DEBUG
#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VERSION "1.10"
//Includes

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <warden>
#include <autoexecconfig>
#include <mystocks>
#include <colors>

//Variables
float g_VelocityLimit = 350.0;
Handle g_ConVar_Limit;

ConVar gc_sAdminFlag;
ConVar gc_sWardenEnable;
char g_sAdminFlag[32];
char nameAdmin[32];
char nameTPlayer[32];

//Plugin info
public Plugin myinfo = 
{
	name = "ResetPlugin_SpeedLimit", 
	author = PLUGIN_AUTHOR, 
	description = "Allow players to reset their speed/gravity and limit bhop speed with an CVar (Thanks to LumiStance)", 
	version = PLUGIN_VERSION, 
	url = "csitajb.cf"
};

//Plugin Code

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	//ConVars
	AutoExecConfig_SetFile("ResetPlugin");
	AutoExecConfig_SetCreateFile(true);
	g_ConVar_Limit = AutoExecConfig_CreateConVar("sm_slowhop_limit", "350.0", "Maximum velocity a play is allowed when jumping. 0 Disables limiting.");
	gc_sAdminFlag = AutoExecConfig_CreateConVar("sm_admflag_forcecomms", "a", "Flag req for forcecomms, /public for all clients");
	gc_sWardenEnable = AutoExecConfig_CreateConVar("sm_forcecomms_warden", "1", "Enable force comms for warden. 1 = True !1 = False");
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	//Commands
	RegConsoleCmd("sm_frg", Command_FResetGravity, "Command to force gravity reset");
	RegConsoleCmd("sm_frs", Command_FResetSpeed, "Command to force speed reset");
	RegConsoleCmd("sm_rs", Command_RSpeed, "Command to reset speed");
	RegConsoleCmd("sm_rg", Command_RGravity, "Commando to reset gravity");
	RegAdminCmd("sm_rfresh", Command_Refresh, ADMFLAG_CONFIG, "Refresh CVars");
	//Hooks
	HookEvent("player_jump", Event_PlayerJump);
	//Find
	gc_sAdminFlag.GetString(g_sAdminFlag, sizeof(g_sAdminFlag));
	
}

public Action Command_FResetSpeed(int client, int args)
{
	if (gc_sWardenEnable.BoolValue) {
		if (warden_iswarden(client))
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			int target = FindTarget(client, arg1);
			if (args != 1)
			{
				ReplyToCommand(client, "[SM]Usage: sm_frs <target>");
			}
			else if (target <= 0)
			{
				//			ReplyToTargetError(client, COMMAND_TARGET_NOT_IN_GAME);
			}
			else if (IsPlayerAlive(target))
			{
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
				GetClientName(client, nameAdmin, 32);
				PrintToChat(target, "[SM]You speed was resetted by warden", nameAdmin);
				GetClientName(target, nameTPlayer, 32);
				ReplyToCommand(client, "[SM]Successfully resetted speed of %s!", nameTPlayer);
			}
			else
			{
				ReplyToTargetError(client, COMMAND_TARGET_NOT_ALIVE);
			}
		}
	}
	else if (CheckVipFlag(client, g_sAdminFlag))
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		int target = FindTarget(client, arg1);
		if (args != 1)
		{
			ReplyToCommand(client, "[SM]Usage: sm_frs <target>");
		}
		else if (target <= 0)
		{
			//			ReplyToTargetError(client, COMMAND_TARGET_NOT_IN_GAME);
		}
		else if (IsPlayerAlive(target))
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
			GetClientName(client, nameAdmin, 32);
			PrintToChat(target, "[SM]You speed was resetted by %s", nameAdmin);
			GetClientName(target, nameTPlayer, 32);
			ReplyToCommand(client, "[SM]Successfully resetted speed of %s!", nameTPlayer);
		}
		else
		{
			ReplyToTargetError(client, COMMAND_TARGET_NOT_ALIVE);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM]You don't have access to this command!");
	}
	
}

public Action Command_FResetGravity(client, args)
{
	if (warden_iswarden(client))
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		int target = FindTarget(client, arg1);
		if (args != 1)
		{
			ReplyToCommand(client, "[SM]Usage: sm_frg <target>");
		}
		else if (target <= 0)
		{
			//		ReplyToTargetError(client, COMMAND_TARGET_NOT_IN_GAME);
		}
		else if (IsPlayerAlive(target))
		{
			SetEntityGravity(target, 1.0);
			GetClientName(client, nameAdmin, 32);
			PrintToChat(target, "[SM]You gravity was resetted by %s", nameAdmin);
			GetClientName(target, nameTPlayer, 32);
			ReplyToCommand(client, "[SM]Successfully resetted gravity of %s!", nameTPlayer);
		}
		else
		{
			ReplyToTargetError(client, COMMAND_TARGET_NOT_ALIVE);
		}
	}
	else if (CheckVipFlag(client, g_sAdminFlag))
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		int target = FindTarget(client, arg1);
		if (args != 1)
		{
			ReplyToCommand(client, "[SM]Usage: sm_frg <target>");
		}
		else if (target <= 0)
		{
			//		ReplyToTargetError(client, COMMAND_TARGET_NOT_IN_GAME);
		}
		else if (IsPlayerAlive(target))
		{
			SetEntityGravity(target, 1.0);
			GetClientName(client, nameAdmin, 32);
			PrintToChat(target, "[SM]You gravity was resetted by warden", nameAdmin);
			GetClientName(target, nameTPlayer, 32);
			ReplyToCommand(client, "[SM]Successfully resetted gravity of %s!", nameTPlayer);
		}
		else
		{
			ReplyToTargetError(client, COMMAND_TARGET_NOT_ALIVE);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM]You don't have access to this command!");
	}
}
public Action Command_RGravity(client, args)
{
	if (IsPlayerAlive(client))
	{
		SetEntityGravity(client, 1.0);
		ReplyToCommand(client, "[SM]Your gravity was resetted");
	}
	else
	{
		ReplyToCommand(client, "[SM]You need to be alive");
	}
}

public Action Command_RSpeed(client, args)
{
	if (IsPlayerAlive(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
		ReplyToCommand(client, "[SM] You speed was resetted");
	}
	else
	{
		ReplyToCommand(client, "[SM]You need to be alive");
	}
}





public void OnConfigsExecuted()
{
	RefreshCvarCache();
}

public Action Command_Refresh(client, args)
{
	RefreshCvarCache();
}

stock void RefreshCvarCache()
{
	g_VelocityLimit = GetConVarFloat(g_ConVar_Limit);
}


public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	
	if (g_VelocityLimit)
		CreateTimer(0.1, Event_PostJump, GetClientOfUserId(GetEventInt(event, "userid")));
}

public Action Event_PostJump(Handle timer, any client_index)
{
	if (IsValidClientReset(client_index))
	{
		// Get present velocity vectors
		float vVel[3];
		GetEntPropVector(client_index, Prop_Data, "m_vecVelocity", vVel);
		
		// Determine how much each vector must be scaled for the magnitude to equal the limit
		// scale = limit / (vx^2 + vy^2)^0.5)
		// Derived from Pythagorean theorem, where the hypotenuse represents the magnitude of velocity,
		// and the two legs represent the x and y velocity components.
		// As a side effect, velocity component signs are also handled.
		float scale = FloatDiv(g_VelocityLimit, SquareRoot(FloatAdd(Pow(vVel[0], 2.0), Pow(vVel[1], 2.0))));
		
		// A scale < 1 indicates a magnitude > limit
		if (scale < 1.0)
		{
			// Reduce each vector by the appropriate amount
			vVel[0] = FloatMul(vVel[0], scale);
			vVel[1] = FloatMul(vVel[1], scale);
			
			// Impart new velocity onto player
			TeleportEntity(client_index, NULL_VECTOR, NULL_VECTOR, vVel);
		}
	}
}

stock bool IsValidClientReset(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client) || IsClientSourceTV(client) || IsClientReplay(client) || (!IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
} 