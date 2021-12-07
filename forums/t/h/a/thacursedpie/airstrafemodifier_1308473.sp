/////////////////////////////////////////////////////////
//
//            Airstrafe Modifier
//              by thaCURSEDpie
//
//			  2010-09-24
//
//            v0.1.0
//
//
//             For Skyride. Hope you enjoy it ;).
//
//
/////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////
//
//         Includes
//
////////////////////////////////////////////////////////
#pragma semicolon 1

#define PLUGIN_VERSION "0.1.0"

#include <sourcemod>
#include <sdktools>


/////////////////////////////////////////////////////////
//
//         Global variables
//
/////////////////////////////////////////////////////////
new Handle:Enabled = INVALID_HANDLE;
new Handle:multiplier = INVALID_HANDLE;
new Handle:multiplierArea = INVALID_HANDLE;

new bool:modEnabled = true;

new Float:blockRectangle[2][2];
new Float:airstrafeMultiplier = 1.0;
new Float:multiplierArray[33];
new Float:areaMultiplier = 0.0;


/////////////////////////////////////////////////////////
//
//         Mod description
//
/////////////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name = "Airstrafe Modifier",
	author = "thaCURSEDpie",
	description = "Adjust airstrafing, or disable it.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}


/////////////////////////////////////////////////////////
//
//         OnPluginStart
//
//         Notes:
//          Initialize all the cvars and hook their
//          change.
//
/////////////////////////////////////////////////////////
public OnPluginStart()
{
	CreateConVar("airstrafe_version", PLUGIN_VERSION, "Airstrafe Blocker by thaCURSEDpie", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	Enabled = CreateConVar("airstrafe_enabled", "1", "Enable / disable the plugin", FCVAR_PLUGIN); 
	multiplier = CreateConVar("airstrafe_multiplier", "1", "Airstrafe multiplier to apply to joining clients. 0 = no airstrafe, 1 = standard, 2 = twice as much, etc.", FCVAR_PLUGIN);
	multiplierArea = CreateConVar("airstrafe_areamultiplier", "0", "Multiplier to use in the designated area", FCVAR_PLUGIN);
    
    
	modEnabled = GetConVarBool(Enabled);
	airstrafeMultiplier = GetConVarFloat(multiplier);
	areaMultiplier = GetConVarFloat(multiplierArea);
    
	HookConVarChange(multiplierArea, OnAreaMultiplierChanged);
	HookConVarChange(Enabled, OnEnabledChanged);
	HookConVarChange(multiplier, OnMultiplierChanged);
    
	RegAdminCmd("sm_airstrafe_mult", CmdAirstrafeMult, ADMFLAG_SLAY, "Usage: sm_airstrafe_mult <#userid|name> <multiplier>");
	RegAdminCmd("sm_airstrafe_area", CmdAirstrafeArea, ADMFLAG_BAN, "Usage: sm_airstrafe_area <x1> <y1> <x2> <y2>");
}


public OnMapStart()
{
    blockRectangle[0][0] = 0.0;
    blockRectangle[0][1] = 0.0;
    blockRectangle[1][0] = 0.0;
    blockRectangle[1][1] = 0.0;
}


/////////////////////////////////////////////////////////
//
//         OnCvarChange
//
//         Notes:
//          Change the respective variables on cvar
//          change.
/////////////////////////////////////////////////////////
public OnEnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    modEnabled = GetConVarBool(Enabled);
}

public OnMultiplierChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    airstrafeMultiplier = GetConVarFloat(multiplier);
}

public OnAreaMultiplierChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    areaMultiplier = GetConVarFloat(multiplierArea);
}


/////////////////////////////////////////////////////////
//
//         CmdAirstrafeMult
//
//         Notes:
//          Changes a specific player's airstrafe mult.
//          
/////////////////////////////////////////////////////////
public Action:CmdAirstrafeMult(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_airstrafe_mult <#userid|name> <multiplier>");
		return Plugin_Handled;
	}
    
	decl String:arg[65];
	decl String:arg2[65];
    
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, arg2, sizeof(arg2));
    
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
    
	for (new i = 0; i < target_count; i++)
	{
		multiplierArray[target_list[i]] = StringToFloat(arg2);
	}
    
	return Plugin_Handled;
}

/////////////////////////////////////////////////////////
//
//         CmdAirstrafeArea
//
//         Notes:
//          Change the 'special' area
//          
/////////////////////////////////////////////////////////
public Action:CmdAirstrafeArea(client, args)
{
    if (args < 4)
    {
        ReplyToCommand(client, "[SM] Usage: sm_airstrafe_area <x1> <y1> <x2> <y2>");
        return Plugin_Handled;
    }
    
    decl String:arg[65];
    decl String:arg2[65];
    decl String:arg3[65];
    decl String:arg4[65];
	
    GetCmdArg(1, arg, sizeof(arg));
    GetCmdArg(2, arg2, sizeof(arg2));
    GetCmdArg(3, arg3, sizeof(arg3));
    GetCmdArg(4, arg4, sizeof(arg4));
    
    new Float:x1 = StringToFloat(arg);
    new Float:x2 = StringToFloat(arg3);
    new Float:y1 = StringToFloat(arg2);
    new Float:y2 = StringToFloat(arg4);
	
    if ((x1 == x2) || (y1 == y2))
    {
        ReplyToCommand(client, "[SM] You need to specify two opposite points of a rectangle!");
        return Plugin_Handled;
    }
	
    if ((x1 < x2) && (y1 < y2))
    {
        blockRectangle[0][0] = x1;
        blockRectangle[0][1] = y1;
        blockRectangle[1][0] = x2;
        blockRectangle[1][1] = y2;
    }
    else if ((x1 > x2) && (y1 > y2))
    {
        blockRectangle[0][0] = x2;
        blockRectangle[0][1] = y2;
        blockRectangle[1][0] = x1;
        blockRectangle[1][1] = y1;
    }
    else if ((x1 > x2) && (y1 < y2))
    {
        blockRectangle[0][0] = x2;
        blockRectangle[0][1] = y1;
        blockRectangle[1][0] = x1;
        blockRectangle[1][1] = y2;
    }
    else if ((x1 < x2) && (y1 > y2))
    {
        blockRectangle[0][0] = x1;
        blockRectangle[0][1] = y2;
        blockRectangle[1][0] = x2;
        blockRectangle[1][1] = y1;
    }
    return Plugin_Handled;
}


/////////////////////////////////////////////////////////
//
//         OnClientPutInServer
//
//         Notes:
//          sets the appropriate multiplier for 
//          clients entering the server
//
//
/////////////////////////////////////////////////////////
public OnClientPutInServer(client)
{
    multiplierArray[client] = airstrafeMultiplier;
}


/////////////////////////////////////////////////////////
//
//         OnPlayerRunCmd
//
//         Notes:
//          block left or right movement if needed
//
//
/////////////////////////////////////////////////////////
public Action:OnPlayerRunCmd (client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    if (modEnabled)
    {       
		if ((buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT))
		{
			new Float:tempMultiplier = multiplierArray[client];
			
			new Float:tempVector[3];
				
			
			// We get the player position
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", tempVector);

			// We check if the point is in the rectangle
			if (((tempVector[0] < blockRectangle[0][0]) || (tempVector[0] > blockRectangle[1][0]) || (tempVector[1] < blockRectangle[0][1]) || (tempVector[1] > blockRectangle[1][1])) == false)
			{
				if (multiplierArray[client] == airstrafeMultiplier)
				{
					tempMultiplier = areaMultiplier;
				}
			}
			
			
			// We now get the ground entity of the player
			//  0 = World (aka on ground) | -1 = In air | Any other positive value = CBaseEntity pointer to the entity below player.
			new GroundEntity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity"); 
			
			// We check if the player is in the air. If he is:
			if (GroundEntity == -1)
			{		       
				// Block left and right movement
				vel[0] *= tempMultiplier;
				vel[1] *= tempMultiplier;
			}
		}
    }
    return Plugin_Continue;
}