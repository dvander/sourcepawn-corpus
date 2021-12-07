/* simple_teleport
* 
* 	DESCRIPTION
* 		Allow authorized people to teleport people to saved locations.  Players must have admin flag custom1 or overidden to have access to "allow_teleport" command.
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.1.0	*	Initial Release
* 
* 	TO DO List
* 		Maybe add a blink command to save the location where the player is looking?
* 
* 	KNOWN ISSUES
* 		None that I could find during my testing
* 
* 	REQUESTS
* 		Suggest something
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define 	PLUGIN_VERSION 		"0.0.1.0"

new bool:PlayerCanTeleport[MAXPLAYERS+1];
new Float:SavedLocation[MAXPLAYERS+1][3];
new Float:SavedAngles[MAXPLAYERS+1][3];
	
public Plugin:myinfo = 
{
	name = "Simple Teleport",
	author = "TnTSCS aka ClarkKent",
	description = "plugin description",
	version = PLUGIN_VERSION,
	url = "http://www.dhgamers.com"
};

public OnPluginStart()
{
	new Handle:hRandom; // KyleS HATES handles
	
	HookConVarChange((hRandom = CreateConVar("sm_simpleteleport_version", PLUGIN_VERSION, 
	"Version of \"Simple Teleport\"", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD)), OnVersionChanged);
	
	CloseHandle(hRandom); // KyleS HATES Handles
	
	RegConsoleCmd("sm_getloc", Cmd_GetLoc, "Displays your current location");
	RegConsoleCmd("sm_saveloc", Cmd_SaveLoc, "Saves your current location for future telporting");
	RegConsoleCmd("sm_teleport", Cmd_Teleport, "Teleports target to saved location");
	
	CheckPlayers();
}

public OnClientPostAdminCheck(client)
{
	if (CheckCommandAccess(client, "allow_teleport", ADMFLAG_CUSTOM1))
	{
		PlayerCanTeleport[client] = true;
	}
	else
	{
		PlayerCanTeleport[client] = false;
	}
	
	ClearPlayerFloats(client);
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		PlayerCanTeleport[client] = false;
		ClearPlayerFloats(client);
	}	
}

public Action:Cmd_GetLoc(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] Command is in-game only");
		
		return Plugin_Handled;
	}
	
	if (args > 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_getloc");
		
		return Plugin_Handled;
	}
	
	new Float:Location[3];
	
	GetClientAbsOrigin(client, Location);
	
	ReplyToCommand(client, "\x02Location: \x03%.3f  %.3f  %.3f", Location[0], Location[1], Location[2]);
	
	return Plugin_Handled;
}

public Action:Cmd_SaveLoc(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] Command is in-game only");
		
		return Plugin_Handled;
	}
	
	if (args > 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_saveloc");
		
		return Plugin_Handled;
	}
	
	GetClientAbsOrigin(client, SavedLocation[client]);
	GetClientAbsAngles(client, SavedAngles[client]);
	
	ReplyToCommand(client, "\x02Location Saved: \x03%.3f  %.3f  %.3f", SavedLocation[client][0], SavedLocation[client][1], SavedLocation[client][2]);
	
	return Plugin_Handled;
}

public Action:Cmd_Teleport(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] Command is in-game only");
		
		return Plugin_Handled;
	}
	
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_teleport <target>");
		
		return Plugin_Handled;
	}
	
	new String:target[MAX_NAME_LENGTH];
	new String:target_name[MAX_NAME_LENGTH];
	
	new target_list[MAXPLAYERS];
	new target_count;
	new bool:tn_is_ml;	

	GetCmdArg(1, target, sizeof(target));

	if ((target_count = ProcessTargetString( 
			target,
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
		if (target_list[i] == -1)
		{
			return Plugin_Handled;
		}
		
		TeleportEntity(i, SavedLocation[client], SavedAngles[client], NULL_VECTOR);
		ReplyToCommand(client, "\x02Teleported %N to saved location: \x03%.3f %.3f %.3f", i, SavedLocation[client][0], SavedLocation[client][1], SavedLocation[client][2]);
	}
	
	return Plugin_Handled;
}

ClearPlayerFloats(client)
{
	SavedLocation[client][0] = 0.0;
	SavedLocation[client][1] = 0.0;
	SavedLocation[client][2] = 0.0;
	SavedAngles[client][0] = 0.0;
	SavedAngles[client][1] = 0.0;
	SavedAngles[client][2] = 0.0;
}

CheckPlayers()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (CheckCommandAccess(i, "allow_teleport", ADMFLAG_CUSTOM1))
		{
			PlayerCanTeleport[i] = true;
		}
		else
		{
			PlayerCanTeleport[i] = false;
		}
		
		ClearPlayerFloats(i);
	}
}

public OnVersionChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
	{
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}