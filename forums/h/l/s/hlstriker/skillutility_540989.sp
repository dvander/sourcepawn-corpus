/*	=============================================
*	- NAME:
*	  + FF Skill Utility
*
*	- DESCRIPTION:
*	  + This plugin adds commands to help players in skill type maps.
* 	
* 	
*	-------------
*	Server cvars:
*	-------------
*	- sv_cliptime <seconds>
*	 + The number of seconds to allow noclip when a user types '/clipon'.
*	
*	- sv_helpmsg <0 or 1>
*	 + 0 Turns help messages off, 1 turns them on.
*	
*	- sv_helpmsgtime <seconds>
*	 + The number of seconds in between each help message that displays.
* 	
*	- sv_skillutility <0 or 1>
*	 + 0 Turns plugin off, 1 turns plugin on.
*	
* 	
*	----------------
*	Client commands:
*	----------------
*	- say saveme
*	 + Lets a player save their position they are standing at.
*	
*	- say posme
*	 + Lets a player return to the position they saved at using 'saveme'.
*	
*	- say /clipon
*	 + Lets a player gain noclip for a time in seconds specified by a cvar.
* 	 + After the time runs out the player is teleported back to where they started noclip at.
* 	
*	- say /clipoff
*	 + If the player is using '/clipon' then this will return them back to where
* 	 + they started it if the time hasn't run out yet.
* 	
* 	
*	---------------
*	Admin commands:
*	---------------
*	- say /goto <PlayerName>
*	 + Lets an admin teleport to the specified players location.
* 	
* 	
*	----------
*	Changelog:
*	----------
*	Version 1.0 ( 10-10-2007 )
*	-- Initial release.
*	
*	Version 2.0 ( 09-09-2008 )
*	-- Rewrote a lot of code for better optimization and compatibility with FF and SM versions.
*	-- Removed blocking of +attack and +use as this is no longer possible at the moment.
*	-- Added checks if player is on ground and not ducking before using saveme.
* 	-- Added blocking interaction with some entities when using /clipon.
*  	-- Added help message displaying to use /clipoff for turning noclip off.
*  	-- Added sv_skillutility cvar to enable/disable the plugin.
*	-- Fixed a for statement that would leave off the last player.
* 	-- Changed MAX_PLAYERS from 32 down to 22 (max FF player limit).
* 	
*	Version 2.1 ( 11-29-2008 )
*	-- Resets players saved position on spawn (thanks Lt. Llama).
* 	
*	Version 2.2 ( 01-27-2009 )
*	-- No longer removes clients saved position on spawn unless they changed class.
*	-- Fixed a problem with clients collision value when turning clip off.
*	-- When using posme/clipoff the clients velocity is set to 0.
*	-- When using saveme/clipon the clients angles are now saved.
*	
*	Version 2.3 ( 02-02-2009 )
*	-- Added color to the messages when using the commands.
*	-- Fixed the error when someone talks using server (thanks PartialSchism).
* 	
*	Version 2.4 ( 02-06-2009 )
*	-- Added a new client command for admins (say /goto <PlayerName>).
*	-- Fixed the message beep when using commands.
* 	
*	Version 2.5 ( 03-05-2009 )
*	-- Fixed the SayText function.
* 	
*	Version 2.6 ( 03-09-2009 )
*	-- Fixed a bug on users clip reset.
* 	
*	Version 2.7 ( 12-17-2011 )
*	-- Fixed crashing servers in the latest FF version (GetClientEyeAngles() seems to have wrong offset).
* 	-- Updated to use MaxClients variable instead of GetMaxClients().
* 	
*/

#include <sourcemod>
#include <sdktools_sound>
#include <sdktools_functions>

#define VERSION "2.7"
public Plugin:myinfo = 
{
	name = "Skill Utility",
	author = "hlstriker",
	description = "Commands to help with skill maps",
	version = VERSION,
	url = "None"
}

#define MAX_PLAYERS 22

// Main Variables
#define SOUND_CHAT "common/talk.wav"
#define SOUND_TELE "Misc/unagi.wav"
new Float:g_flSavedPos[MAX_PLAYERS+1][3];
new Float:g_flSavedPosClip[MAX_PLAYERS+1][3];
new Float:g_flSavedAngles[MAX_PLAYERS+1][3];
new Float:g_flSavedAnglesClip[MAX_PLAYERS+1][3];
new bool:g_mIsClipped[MAX_PLAYERS+1];
new g_iPlayerColNum[MAX_PLAYERS+1];
new g_iLastClass[MAX_PLAYERS+1];

// Timer variables
#define TIMER_HELPMSG_ID 2672
new Handle:g_hTimer[MAX_PLAYERS+1];
new Handle:g_hMsgTimer;
new g_iOldTime;

// CVar Variables
new Handle:g_hCliptime;
new Handle:g_hHelpMsg;
new Handle:g_hHelpMsgTime;
new Handle:g_hEnabled;

public OnPluginStart()
{
	CreateConVar("sv_ffskillutilityver", VERSION, "Skill Utility Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hCliptime = CreateConVar("sv_cliptime", "120", "Set the number of seconds users get noclip.");
	g_hHelpMsg = CreateConVar("sv_helpmsg", "1", "Set to 1 to turn help msgs on, set to 0 to turn them off.");
	g_hHelpMsgTime = CreateConVar("sv_helpmsgtime", "60", "Set the number of seconds the help message displays.");
	g_hEnabled = CreateConVar("sv_skillutility", "1", "Enable/Disable the Skill Utility plugin.");
	
	HookEvent("player_death", hook_death, EventHookMode_Post);
	HookEvent("player_spawn", hook_spawn, EventHookMode_Post);
	
	RegConsoleCmd("say", hook_say);
}

public OnMapStart()
{
	PrecacheSound(SOUND_TELE);
	PrecacheSound(SOUND_CHAT);
	g_hMsgTimer = CreateTimer(GetConVarFloat(g_hHelpMsgTime), ShowHelpMsg, TIMER_HELPMSG_ID, TIMER_REPEAT);
	g_iOldTime = GetConVarInt(g_hHelpMsgTime);
}

public OnClientPutInServer(iClient)
{
	g_mIsClipped[iClient] = false;
	g_flSavedPos[iClient] = Float:{0.0,0.0,0.0};
	g_flSavedPosClip[iClient] = Float:{0.0,0.0,0.0};
}

public Action:ShowHelpMsg(Handle:hTimer)
{
	if(GetConVarInt(g_hHelpMsgTime) != g_iOldTime)
	{
		if(g_hMsgTimer != INVALID_HANDLE)
		{
			KillTimer(g_hMsgTimer);
			g_hMsgTimer = INVALID_HANDLE;
		}
		g_iOldTime = GetConVarInt(g_hHelpMsgTime);
		g_hMsgTimer = CreateTimer(GetConVarFloat(g_hHelpMsgTime), ShowHelpMsg, TIMER_HELPMSG_ID, TIMER_REPEAT);
	}
	
	if(GetConVarInt(g_hHelpMsg) > 0)
	{
		static iRandNum;
		iRandNum = GetRandomInt(1, 3);
		switch(iRandNum)
		{
			case 1: SendDialogToAll("Type /clipon to enable noclip for %i seconds.", GetConVarInt(g_hCliptime));
			case 2: SendDialogToAll("Type saveme to save your position, and posme to go back.");
			case 3: SendDialogToAll("Type /clipoff to turn noclip off.");
		}
	}
}

SendDialogToAll(String:szText[], any:...)
{
	decl String:szMessage[128];
	VFormat(szMessage, sizeof(szMessage), szText, 2);
	
	static iRandNum1, iRandNum2, iRandNum3;
	iRandNum1 = GetRandomInt(1, 255);
	iRandNum2 = GetRandomInt(1, 255);
	iRandNum3 = GetRandomInt(1, 255);
	
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			new Handle:kv = CreateKeyValues("Stuff", "title", szMessage);
			KvSetColor(kv, "color", iRandNum1, iRandNum2, iRandNum3, 255);
			KvSetNum(kv, "level", 1);
			KvSetNum(kv, "time", 10);
			
			CreateDialog(i, kv, DialogType_Msg);
			
			CloseHandle(kv);
		}
	}
}

public hook_death(Handle:hEvent, const String:szEventName[], bool:mDontBroadcast)
{
	static iVictim;
	iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(g_mIsClipped[iVictim])
	{
		if(g_hTimer[iVictim] != INVALID_HANDLE)
		{
			KillTimer(g_hTimer[iVictim]);
			g_hTimer[iVictim] = INVALID_HANDLE;
		}
		g_mIsClipped[iVictim] = false;
	}
}

public hook_spawn(Handle:hEvent, const String:szEventName[], bool:mDontBroadcast)
{
	static iClient, iClass;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	iClass = GetEntProp(iClient, Prop_Send, "m_iClassStatus");
	
	if(iClass != 0)
	{
		if(iClass != g_iLastClass[iClient])
			g_flSavedPos[iClient] = Float:{0.0,0.0,0.0};
		g_iLastClass[iClient] = iClass;
	}
}

public Action:NoclipReset(Handle:hTimer, any:iClient)
{
	if(g_mIsClipped[iClient])
		RemoveNoclip(iClient);
}

public Action:hook_say(iClient, iArgs)
{
	if(!(GetConVarInt(g_hEnabled) > 0) || iClient < 1)
		return Plugin_Continue;
	
	decl String:szArg1[32];
	GetCmdArg(1, szArg1, 32);
	
	if(!IsPlayerAlive(iClient))
	{
		if(StrEqual(szArg1, "saveme", false) || StrEqual(szArg1, "posme", false))
		{
			PrintToChat(iClient, "[Error] You must be alive to do this.");
			return Plugin_Handled;
		}
	}
	else
	{
		if((szArg1[0] == '/') && (StrContains(szArg1, "/goto", false) != -1))
		{
			new AdminId:iAdmin = GetUserAdmin(iClient);
			if(iAdmin == INVALID_ADMIN_ID)
				return Plugin_Continue;
			
			if(!GetAdminFlag(iAdmin, Admin_Ban))
				return Plugin_Continue;
			
			new String:szSplit[4][32];
			ExplodeString(szArg1, " ", szSplit, sizeof(szSplit)-1, sizeof(szSplit[])-1);
			if(StrEqual(szSplit[0], "/goto", false))
			{
				new String:szName[32], Float:flLocation[3];
				for(new i=1; i<=MaxClients; i++)
				{
					if(!IsClientInGame(i))
						continue;
					
					GetClientName(i, szName, sizeof(szName)-1);
					if(StrContains(szName, szSplit[1], false) != -1)
					{
						if(!IsPlayerAlive(i))
						{
							PrintToChat(iClient, "[Error] You can only teleport to alive players.");
							return Plugin_Handled;
						}
						
						if(iClient == i)
						{
							PrintToChat(iClient, "[Error] You cannot teleport to yourself.");
							return Plugin_Handled;
						}
						
						GetClientAbsOrigin(i, flLocation);
						EmitSoundToClient(iClient, SOUND_TELE);
						flLocation[0] += 12;
						flLocation[1] += 12;
						flLocation[2] += 12;
						TeleportEntity(iClient, flLocation, NULL_VECTOR, Float:{0.0,0.0,0.0});
						
						PrintToChat(iClient, "You have been teleported to \"%s\"'s location.", szName);
						
						return Plugin_Handled;
					}
				}
				
				PrintToChat(iClient, "[Error] Client containing \"%s\" not found.", szSplit[1]);
				
				return Plugin_Handled;
			}
		}
		if(StrEqual(szArg1, "/clipon", false))
		{
			if(!g_mIsClipped[iClient])
			{
				g_mIsClipped[iClient] = true;
				
				GetClientAbsOrigin(iClient, g_flSavedPosClip[iClient]);
				g_flSavedAnglesClip[iClient][0] = GetEntPropFloat(iClient, Prop_Send, "m_angEyeAngles[0]");
				g_flSavedAnglesClip[iClient][1] = GetEntPropFloat(iClient, Prop_Send, "m_angEyeAngles[1]");
				
				g_iPlayerColNum[iClient] = GetEntProp(iClient, Prop_Data, "m_CollisionGroup");
				SetEntProp(iClient, Prop_Data, "m_CollisionGroup", 0);
				SetEntProp(iClient, Prop_Send, "movetype", 8);
				
				PrintToChat(iClient, "Noclip is enabled for %i seconds. Type /clipoff to get back faster.", GetConVarInt(g_hCliptime));
				
				g_hTimer[iClient] = CreateTimer(GetConVarFloat(g_hCliptime), NoclipReset, iClient);
				
				return Plugin_Handled;
			}
			else
			{
				PrintToChat(iClient, "[Error] You already have noclip enabled.");
				return Plugin_Handled;
			}
		}
		else if(StrEqual(szArg1, "/clipoff", false))
		{
			if(g_mIsClipped[iClient])
			{
				if(g_hTimer[iClient] != INVALID_HANDLE)
				{
					KillTimer(g_hTimer[iClient]);
					g_hTimer[iClient] = INVALID_HANDLE;
				}
				
				RemoveNoclip(iClient);
				
				return Plugin_Handled;
			}
			else
			{
				PrintToChat(iClient, "[Error] You must turn noclip on first.");
				return Plugin_Handled;
			}
		}
		else if(StrEqual(szArg1, "saveme", false))
		{
			if(!g_mIsClipped[iClient])
			{
				if(!(GetEntityFlags(iClient) & FL_ONGROUND))
				{
					PrintToChat(iClient, "[Error] You must be on the ground to save your position.");
					return Plugin_Handled;
				}
				
				static iButtons;
				iButtons = GetClientButtons(iClient);
				if(iButtons & IN_DUCK)
				{
					PrintToChat(iClient, "[Error] You can't duck while trying to save your position.");
					return Plugin_Handled;
				}
				
				GetClientAbsOrigin(iClient, g_flSavedPos[iClient]);
				g_flSavedAngles[iClient][0] = GetEntPropFloat(iClient, Prop_Send, "m_angEyeAngles[0]");
				g_flSavedAngles[iClient][1] = GetEntPropFloat(iClient, Prop_Send, "m_angEyeAngles[1]");
				
				PrintToChat(iClient, "Your position has been saved.");
				return Plugin_Handled;
			}
			else
			{
				PrintToChat(iClient, "[Error] You cannot save your position while using /clipon.");
				return Plugin_Handled;
			}
		}
		else if(StrEqual(szArg1, "posme", false))
		{
			if(FloatCompare(g_flSavedPos[iClient][0], 0.0) && FloatCompare(g_flSavedPos[iClient][1], 0.0) && FloatCompare(g_flSavedPos[iClient][2], 0.0))
			{
				TeleportEntity(iClient, g_flSavedPos[iClient], g_flSavedAngles[iClient], Float:{0.0,0.0,0.0});
				PrintToChat(iClient, "You have been restored to your saved position.");
				return Plugin_Handled;
			}
			else
			{
				PrintToChat(iClient, "[Error] You must save your position first.");
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

RemoveNoclip(iClient)
{
	if(!IsClientInGame(iClient))
		return;
	
	g_mIsClipped[iClient] = false;
	
	SetEntProp(iClient, Prop_Data, "m_CollisionGroup", g_iPlayerColNum[iClient]);
	SetEntProp(iClient, Prop_Send, "movetype", 2);
	TeleportEntity(iClient, g_flSavedPosClip[iClient], g_flSavedAnglesClip[iClient], Float:{0.0,0.0,0.0});
	
	PrintToChat(iClient, "Noclip is turned off and you have returned to your starting location.");
}