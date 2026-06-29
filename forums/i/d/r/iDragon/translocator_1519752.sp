/* Credit to GODJonez for thinking about making it for CS:S.
* He created his own plugin in Eventscripts:
* http://addons.eventscripts.com/addons/view/translocator
* Because his plugin is not supported any more and his plugin is for ES, I created my own version of this plugin for SM users!
*/

#include <sourcemod>
#include <sdktools>

// Plugin name...
#define MODNAME		"Translocator"
// For the translocator entity.
#define ADD_OUTPUT "OnUser1 !self:Kill::1.5:1"
// I Need big array size for the special players.
#define MAX_SPECIAL_PLAYERS_PER_MAP 500
// Translocator model path
#define MODELPATH "models/props_c17/streetsign005b.mdl"

// Admin access flag for the admin commands
#define ACCESS_FLAG ADMFLAG_KICK
// Plugin version
#define PLUGIN_VERSION   "1.0"

public Plugin:myinfo = {
    name 		= "Translocator",
    author  	= "iDragon",
    description = "Unreal Tournament style Translocators for Counter Strike Source!",
    version 	= PLUGIN_VERSION,
    url 		= " "
};

// Handles for convars and etc...
new Handle:g_CvarEnabled = INVALID_HANDLE;
new Handle:g_CvarThrowTime = INVALID_HANDLE;
new Handle:g_hPluginVersion = INVALID_HANDLE;

// Arrays for translocators ...
new bool:g_clientUsedTranslocator[MAXPLAYERS+1] = {false, ...};
new g_clientTranslocatorEnt[MAXPLAYERS+1] = {-1, ...};
new bool:g_clientTranslocatorCanUse[MAXPLAYERS+1] = {true, ...};
new g_specialTranslocatorColor[MAX_SPECIAL_PLAYERS_PER_MAP][7];
new g_CurrentSpecialPlayers = 0;
/* Special translocator color array's indexes:
	0 - userid
	1 - T red
	2 - T green
	3 - T blue
	4 - CT red
	5 - CT green
	6 - CT blue
*/

// For the velocity
new const Float:g_fSpin[3] = {4877.4, 0.0, 0.0};

public OnPluginStart()
{
	// Load translations for ProcessTargetString() command...
	LoadTranslations("common.phrases");

	// Plugin cvars.
	g_CvarEnabled = CreateConVar("sm_translocator_enable", "1", "Enable or disable translocator plugin: 0 - Disable, 1 - Enable.");
	g_CvarThrowTime = CreateConVar("sm_translocator_throw_time", "2", "In seconds: how long to wait until client will be able throw his translocator again?");
	
	// Version...
	g_hPluginVersion = CreateConVar("sm_translocator_version", PLUGIN_VERSION, "Translocator version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(g_hPluginVersion, PLUGIN_VERSION);
	
	// Auto-Generate this plugin config.
	AutoExecConfig(true, "sm_translocator");
	
	// Hook enable convar...
	HookConVarChange(g_CvarEnabled, OnPluginStatusChanged);
	// Hook Version changed...
	HookConVarChange(g_hPluginVersion, VersionHasBeenChanged);
	
	// Admin commands
	RegAdminCmd("sm_trans",
		Command_Trans,
		ACCESS_FLAG,
		"Translocator plugin admin command.");
	
	// Players commands
	RegConsoleCmd("trans_throw", Command_ThrowTranslocator);
	RegConsoleCmd("trans_use", Command_UseTranslocator);
	RegConsoleCmd("+trans_cam", Command_ShowTranslocatorCamera);
	RegConsoleCmd("-trans_cam", Command_UnShowTransCamera);
	RegConsoleCmd("sm_trhelp", Command_TrHelp);
	
	HookEvent("round_start", Event_RoundStart);
	
	g_CurrentSpecialPlayers = 0;
}

public VersionHasBeenChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

public OnPluginStatusChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 1) // Plugin has been enabled! Need to sign everyone to the arrays.
	{
		new maxClients = GetMaxClients();
		for (new i=1; i<=maxClients;i++)
		{
			g_clientUsedTranslocator[i] = false;
			g_clientTranslocatorEnt[i] = -1;
		}
		PrintToChatAll("\x04[%s]:\x03 Plugin has been enabled!", MODNAME);
	}
	else // Plugin has been disbaled...
		PrintToChatAll("\x04[%s]:\x04 Plugin has been disabled!", MODNAME);
}

public Action:Command_Trans(client, args)
{
	if (args < 1)
	{
		PrintToChat(client, "\x04[%s]:\x03 To enable / disable this plugin:", MODNAME);
		PrintToChat(client, "\x04[%s]: \x03Usage: \x01sm_trans <num> (0-Disable, 1-Enable)", MODNAME);
		PrintToChat(client, "\x04[%s]:\x03 Or to set player's translocator color:", MODNAME);
		PrintToChat(client, "\x04[%s]:\x03Usage:\x01 sm_trans player t_red t_green t_blue ct_red ct_green ct_blue", MODNAME);
		return Plugin_Handled;
	}
	
	if (args < 7)
	{
		decl String:status[2];
		GetCmdArg(1, status, sizeof(status));
		new statusNum = StringToInt(status);
		if ((statusNum == 1) || (statusNum == 0))
			SetConVarString(g_CvarEnabled, status);
	}
	else
	{
		decl String:searchFor[64], String:target_name[64];
		decl String:t_red[3], String:t_blue[3], String:t_green[3], String:ct_red[3], String:ct_blue[3], String:ct_green[3];
		new targetsArr[64], found = 0;
		new bool:isML;
		
		GetCmdArg(1, searchFor, sizeof(searchFor));
		GetCmdArg(2, t_red, sizeof(t_red));
		GetCmdArg(3, t_green, sizeof(t_green));
		GetCmdArg(4, t_blue, sizeof(t_blue));
		GetCmdArg(5, ct_red, sizeof(ct_red));
		GetCmdArg(6, ct_green, sizeof(ct_green));
		GetCmdArg(7, ct_blue, sizeof(ct_blue));
		
		// Test to see if the args are a good colors (color >= 0 && color <= 255)
		new tRed = StringToInt(t_red), tBlue = StringToInt(t_blue), tGreen = StringToInt(t_green);
		new ctRed = StringToInt(ct_red), ctBlue = StringToInt(ct_blue), ctGreen = StringToInt(ct_green);
		if (((tRed > 255) || (tRed < 0) || (tBlue > 255) || (tBlue < 0) || (tGreen > 255) || (tGreen < 0)) || ((ctRed > 255) || (ctRed < 0) || (ctBlue > 255) || (ctBlue < 0) || (ctGreen > 255) || (ctGreen < 0)))
		{
			PrintToChat(client, "\x04[%s]:\x03 Color must be between 0-255 !", MODNAME);
			return Plugin_Handled;
		}
	/* Special translocator color array's indexes:
		0 - userid
		1 - T red
		2 - T green
		3 - T blue
		4 - CT red
		5 - CT green
		6 - CT blue
	*/
		found = ProcessTargetString(searchFor, client ,targetsArr, sizeof(targetsArr), 0, target_name, sizeof(target_name), isML);
		if (found > 0) // Target is found!
		{
			new userid, exist;
			for (new target = 0; target < found; target++)
			{
				exist = -1;
				userid = GetClientUserId(targetsArr[target]);
				for (new special = 0; special < g_CurrentSpecialPlayers; special++) // Check to see if this player already in the special list...
				{
					if (userid == g_specialTranslocatorColor[special][0])
					{
						exist = special;
						break;
					}
				}
				
				if (exist != -1) // The player is already in the list, so I just need to update his colors.
				{
					g_specialTranslocatorColor[exist][0] = userid;
					g_specialTranslocatorColor[exist][1] = tRed;
					g_specialTranslocatorColor[exist][2] = tGreen;
					g_specialTranslocatorColor[exist][3] = tBlue;
					g_specialTranslocatorColor[exist][4] = ctRed;
					g_specialTranslocatorColor[exist][5] = ctGreen;
					g_specialTranslocatorColor[exist][6] = ctBlue;
				}
				else // Need to add new player to the array...
				{
					g_specialTranslocatorColor[g_CurrentSpecialPlayers][0] = userid;
					g_specialTranslocatorColor[g_CurrentSpecialPlayers][1] = tRed;
					g_specialTranslocatorColor[g_CurrentSpecialPlayers][2] = tGreen;
					g_specialTranslocatorColor[g_CurrentSpecialPlayers][3] = tBlue;
					g_specialTranslocatorColor[g_CurrentSpecialPlayers][4] = ctRed;
					g_specialTranslocatorColor[g_CurrentSpecialPlayers][5] = ctGreen;
					g_specialTranslocatorColor[g_CurrentSpecialPlayers][6] = ctBlue;
					
					g_CurrentSpecialPlayers++;
				}
			}
			PrintToChat(client,"\x04[%s]:\x03 %s has now special translocator color!", MODNAME, searchFor);
		}
		else 
			PrintToChat(client,"\x04[%s]:\x03Couldn't find %s in the server...", MODNAME, searchFor);
	}

	return Plugin_Handled;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_CvarEnabled) == 1) // Plugin is enabled - Clients array will be reseted!
	{
		new maxClients = GetMaxClients();
		for (new i=1; i<=maxClients;i++)
		{
			g_clientUsedTranslocator[i] = false;
			g_clientTranslocatorEnt[i] = -1;
		}
	}
}

public Action:Command_ThrowTranslocator(client, args)
{
	if (GetConVarInt(g_CvarEnabled) == 1)
	{
		if (!IsFakeClient(client) && IsPlayerAlive(client))
		{
			if (!g_clientTranslocatorCanUse[client]) // Client can't throw his translocator yet!
			{
				if (GetConVarInt(g_CvarThrowTime) <= 0)
					PrintToChat(client, "\x04[%s]:\x03 You need to wait\x01 1\x03 seconds between any throw!", MODNAME);
				else
					PrintToChat(client, "\x04[%s]:\x03 You need to wait\x01 %d \x03seconds between any throw!", MODNAME, GetConVarInt(g_CvarThrowTime));
					
				return Plugin_Handled;
			}
			
			new ent;
			if(g_clientUsedTranslocator[client] && (g_clientTranslocatorEnt[client] != -1)) // Translocator is already exists! There is no need to create a new one!
				ent = g_clientTranslocatorEnt[client];
			else
				ent = CreateEntityByName("prop_physics");
		
			if (ent == -1)
			{
				PrintToChatAll("\x04[%s]: \x03ERROR Accourd while trying to create the translocator!", MODNAME);
				return Plugin_Handled;
			}
			if(!IsModelPrecached(MODELPATH))
				PrecacheModel(MODELPATH);

			if(!IsValidEntity(ent))
			{
				PrintToChat(client, "\x04[%s]: \x03ERROR! Wrong entity number... please retry! or wait for the next round.", MODNAME);
				return Plugin_Handled;
			}
			
			SetEntityModel(ent, MODELPATH);
			DispatchSpawn(ent);
			
			new userid = GetClientUserId(client);
			new found = -1;
			for (new i=0;i < g_CurrentSpecialPlayers; i++)
			{
				if (userid == g_specialTranslocatorColor[i][0])
				{
					found = i;
					break;
				}
			}
			
			if (found != -1) // This client has special translocator color!
			{
				if(GetClientTeam(client) == 2)
					SetEntityRenderColor(ent, g_specialTranslocatorColor[found][1], g_specialTranslocatorColor[found][2], g_specialTranslocatorColor[found][3]);
				else if(GetClientTeam(client) == 3)
					SetEntityRenderColor(ent, g_specialTranslocatorColor[found][4], g_specialTranslocatorColor[found][5], g_specialTranslocatorColor[found][6]);
			}
			else
			{
				if(GetClientTeam(client) == 2)
					SetEntityRenderColor(ent, 255, 0, 0);
				else if(GetClientTeam(client) == 3)
					SetEntityRenderColor(ent, 0, 0, 255);
			}
			
			// Thanks to knife-throw plugin. :)
			SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
			SetVariantString(ADD_OUTPUT);
			AcceptEntityInput(ent, "AddOutput");
			
			AcceptEntityInput(ent, "DisableShadow");
			SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
			SetEntProp(ent, Prop_Data, "m_iHealth", 16777216);
			SetEntProp(ent, Prop_Data, "m_iMaxHealth", 16777216);
			SetEntProp(ent, Prop_Data, "m_nSolidType", MOVETYPE_VPHYSICS);
			
			static Float:fPos[3], Float:fAng[3], Float:fVel[3], Float:fPVel[3];
			GetClientEyePosition(client, fPos);
			GetClientEyeAngles(client, fAng);
			GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(fVel, 1250.0); // (1000.0 + (250.0 * 5))
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVel);
			AddVectors(fVel, fPVel, fVel);
			SetEntPropVector(ent, Prop_Data, "m_vecAngVelocity", g_fSpin);
			SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.2);
			TeleportEntity(ent, fPos, fAng, fVel);
			// --------------
			
			g_clientTranslocatorEnt[client] = ent;
			g_clientUsedTranslocator[client] = true;
			
			g_clientTranslocatorCanUse[client] = false;
			if (GetConVarInt(g_CvarThrowTime) <= 0)
				CreateTimer(1.0, AllowClientToThrowTranslocator, client);
			else
				CreateTimer(GetConVarFloat(g_CvarThrowTime), AllowClientToThrowTranslocator, client);
			
	//		PrintToChat(client, "You used translocator!");
		 }
		 else
			PrintToChat(client, "\x04[%s]:\x03 You must be alive to use this command!", MODNAME);
		
		return Plugin_Handled;
	}
	else
		PrintToChat(client, "\x04[%s]:\x03 Translocator plugin is disabled! sm_trans 1 to enable it", MODNAME);
	
	return Plugin_Continue;
}

public Action:AllowClientToThrowTranslocator(Handle:timer, any:client)
{
	if (!g_clientTranslocatorCanUse[client])
		g_clientTranslocatorCanUse[client] = true;
}

public Action:Command_UseTranslocator(client, args)
{
	if (GetConVarInt(g_CvarEnabled) == 1)
	{
		if (!IsFakeClient(client) && IsPlayerAlive(client))
		{
			if(g_clientUsedTranslocator[client] && (g_clientTranslocatorEnt[client] != -1)) // The client is already used his translocator and the translocator exists!
			{
				new Float:entPos[3];
				GetEntPropVector(g_clientTranslocatorEnt[client], Prop_Send, "m_vecOrigin", entPos);
				TeleportEntity(client, entPos, NULL_VECTOR, NULL_VECTOR);
		//		PrintToChat(client, "\x04[%s]: \x03You have been teleported to your trans", MODNAME);
			}
			else
				PrintToChat(client, "\x04[%s]: \x03You need to use \x01trans_throw \x03before trying to use it", MODNAME);
		}
		return Plugin_Handled;
	}
	else
		PrintToChat(client, "\x04[%s]:\x03 Translocator plugin is disabled! sm_trans 1 to enable it", MODNAME);
	
	return Plugin_Continue;
}

public Action:Command_ShowTranslocatorCamera(client, args)
{
	if (GetConVarInt(g_CvarEnabled) == 1)
	{
		if (!IsFakeClient(client) && IsPlayerAlive(client))
		{
			if(g_clientUsedTranslocator[client] && (g_clientTranslocatorEnt[client] != -1))
			{
				if(IsValidEntity(g_clientTranslocatorEnt[client]))
					SetClientViewEntity(client, g_clientTranslocatorEnt[client]);
				
			}
			else
				PrintToChat(client, "\x04[%s]: \x03You need to use \x01trans_throw \x03before trying to use the camera", MODNAME);
		}
		return Plugin_Handled;
	}
	else
		PrintToChat(client, "\x04[%s]:\x03 Translocator plugin is disabled! sm_trans 1 to enable it", MODNAME);
	
	return Plugin_Continue;
}

public Action:Command_UnShowTransCamera(client, args)
{
	if (!IsFakeClient(client) && IsPlayerAlive(client))
	{
		if(g_clientUsedTranslocator[client] && (g_clientTranslocatorEnt[client] != -1))
		{
			SetClientViewEntity(client, client);
		}
	}
	return Plugin_Handled;
}

public Action:Command_TrHelp(client, args)
{
	if (GetConVarInt(g_CvarEnabled) == 1)
	{
		PrintToChat(client, "\x04[%s]:\x03 Commands:", MODNAME);
		PrintToChat(client, "\x04[%s]:\x01 trans_throw \x03- To throw the translocator.", MODNAME);
		PrintToChat(client, "\x04[%s]:\x01 trans_use \x03- To teleport to the translocator.", MODNAME);
		PrintToChat(client, "\x04[%s]:\x01 +trans_cam \x03- To see through the translocator.", MODNAME);
		PrintToChat(client, "\x04[%s]:\x03 Bind them, example:\x01 bind v trans_throw\x03 When you'll press v the translocator will be thrown.", MODNAME);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
	{
		g_clientUsedTranslocator[client] = false;
		g_clientTranslocatorEnt[client] = -1;
	}
}

public OnClientDisconnect(client)
{
	if(!IsFakeClient(client))
	{
		if(g_clientUsedTranslocator[client] == true)
		{
			if(IsValidEdict(g_clientTranslocatorEnt[client]))
				RemoveEdict(g_clientTranslocatorEnt[client]);
		}
		g_clientUsedTranslocator[client] = false;
		g_clientTranslocatorEnt[client] = -1;
	}
}

public OnMapStart()
{
	if(!IsModelPrecached(MODELPATH))
		PrecacheModel(MODELPATH);
		
	g_CurrentSpecialPlayers = 0;
}
