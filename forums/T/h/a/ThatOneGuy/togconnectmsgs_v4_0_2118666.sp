#pragma semicolon 1
#define PLUGIN_VERSION "4.0"
#include <sourcemod>
#include <autoexecconfig>
#include <sdktools>
#include <morecolors>
#undef REQUIRE_PLUGIN

new Handle:g_hMainEnabled = INVALID_HANDLE;			//enable plugin cvar
new Handle:g_hSettings  = INVALID_HANDLE;				//kv handle
new Handle:g_hEnableDelay = INVALID_HANDLE;			//enable delay on map change cvar
new Handle:g_hDelayTime = INVALID_HANDLE;				//cvar for length of delay
new Handle:g_hDelayTime_Monitor = INVALID_HANDLE;	//timer handle for delay

new g_iMainEnabled;									//enable plugin integer
new g_iEnableDelay;									//g_hEnableDelay integer
new g_iDelayTime;										//g_hDelayTime integer
new g_iDelay = 0;										//if = 1, player connections are ignored. If = 0, plugin will continue. Set to 1 on map start (if g_iEnableDelay = 1), then the timer sets it to 0.

//setup variables
new String:g_sMessage[MAXPLAYERS+1][300];				//message read from kv line
new String:g_sCenterMsg[MAXPLAYERS+1][300];		//message to display in center
new String:g_sFormattedMsg[MAXPLAYERS+1][300];	//message to display in chat
new g_iSet[MAXPLAYERS+1] = -1;							//set to 1 if a setup has been applied
new g_iConnect[MAXPLAYERS+1];							//shows when player connects
new g_iDisconnect[MAXPLAYERS+1];						//shows when player disconnects
new g_iCenter[MAXPLAYERS+1] = -1;						//displays message in center of screen
new g_iChat[MAXPLAYERS+1] = -1;						//displays message in chat
new g_iIsConnectMsg[MAXPLAYERS+1] = 0;				//tells function if message should be a connect msg
new g_iIsDisconnectMsg[MAXPLAYERS+1] = 0;				//tells function if message should be a disconnect msg

public Plugin:myinfo =
{
	name = "TOG's Connect Messages v4.0",
	author = "That One Guy",
	description = "Adds customizable connect and disconnect messages",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("togconnectmsgs_v4");
	AutoExecConfig_CreateConVar("tcm_version", PLUGIN_VERSION, "TOGs Connect Message: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hMainEnabled = AutoExecConfig_CreateConVar("tcm_enabled", "1", "Enable/disable entire plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hMainEnabled, OnCVarChange);
	g_iMainEnabled = GetConVarInt(g_hMainEnabled);
	
	g_hEnableDelay = AutoExecConfig_CreateConVar("tcm_enabledelay", "0", "Enables skipping of connect announcements after map change until the time set by tcm_delay.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnableDelay, OnCVarChange);
	g_iEnableDelay = GetConVarInt(g_hEnableDelay);
	
	g_hDelayTime = AutoExecConfig_CreateConVar("tcm_delay", "45", "Amount of time after map start until connect messages are enabled.");
	HookConVarChange(g_hDelayTime, OnCVarChange);
	g_iDelayTime = GetConVarInt(g_hDelayTime);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public OnMapStart()
{
	if(!g_iMainEnabled)
		return;

	if(g_iEnableDelay)
	{
		g_iDelay = 1;
		new Float:fDelayTime = float(g_iDelayTime);
		g_hDelayTime_Monitor = CreateTimer(fDelayTime, DelayTimer_Monitor, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		g_iDelay = 0;
	}
	
	ParseSetups();
}

public OnMapEnd()		//kill/invalidate all timers/handles on map end
{
	if(g_hDelayTime_Monitor != INVALID_HANDLE)
	{
		KillTimer(g_hDelayTime_Monitor);
		g_hDelayTime_Monitor = INVALID_HANDLE;
	}
}

public Action:DelayTimer_Monitor(Handle:timer)
{
	if(!g_iMainEnabled || !g_hEnableDelay)
	{
		g_hDelayTime_Monitor = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	g_hDelayTime_Monitor = INVALID_HANDLE;
	
	g_iDelay = 0;
	
	return Plugin_Continue;
}

ParseSetups()
{	
	g_hSettings = CreateKeyValues("Setups");
	
	decl String:sPath[256];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tog_connectmsgs.txt");
	
	FileToKeyValues(g_hSettings, sPath);
}

public bool:IsValidClient(client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsFakeClient(client))
	{
		return false;
	}
	return true;
}

public OnClientPostAdminCheck(client)
{
	if(!IsValidClient(client))
	{
		return;
	}
	
	g_iIsDisconnectMsg[client] = 0;
	g_iIsConnectMsg[client] = 1;
	
	if(!g_iDelay)	//if the map start delay is not enabled and current
	{
		RunSetups(client);
		
		if((g_iSet[client] == 1) && g_iConnect[client])
		{
			ShowMsg(client);
		}
	}
	
	//reset whether or not it is a connect/disconnect
	g_iIsConnectMsg[client] = 0;
}

public OnClientDisconnect(client)
{
	if(!IsValidClient(client))
	{
		return;
	}
	
	g_iIsConnectMsg[client] = 0;
	g_iIsDisconnectMsg[client] = 1;
	
	if(!g_iDelay)	//if the map start delay is not enabled and current
	{
		RunSetups(client);
		
		if((g_iSet[client] == 1) && g_iDisconnect[client])
		{
			ShowMsg(client);
		}
	}
	
	//reset whether or not it is a connect/disconnect
	g_iIsDisconnectMsg[client] = 0;
}

stock bool:HasFlags(client, String:sFlags[])
{
	new AdminId:id = GetUserAdmin(client);
	
	if (id != INVALID_ADMIN_ID)
	{
		new count, found, flags = ReadFlagString(sFlags);
		for (new i = 0; i <= 20; i++)
		{
			if(flags & (1<<i))
			{
				count++;

				if (GetAdminFlag(id, AdminFlag:i))
				{
					found++;
				}
			}
		}

		if (count == found)
		{
			return true;
		}
	}

	return false;
}

RunSetups(client)
{
	ParseSetups();
	
	new iIgnoreConnect[MAXPLAYERS+1] = 0;					//used to skip connect messages, even if an applicable one is found
	new iIgnoreDisconnect[MAXPLAYERS+1] = 0;				//used to skip disconnect messages, even if an applicable one is found
	decl String:sName[MAX_NAME_LENGTH];	//clients name
	decl String:sSteamID[MAX_NAME_LENGTH];		//clients name
	decl String:sSectionName[45];			//setup name
	decl String:sFlags[30];				//flags required for connect announce
	decl String:sChatColor[7];				//only needed if chat used
	decl String:sTagColor[7];				//only needed if tag used in chat
	decl String:sTag[300];					//if not used, announce with no tag

	//reset global variables
	g_iConnect[client] = 0;
	g_iDisconnect[client] = 0;
	iIgnoreConnect[client] = 0;
	iIgnoreDisconnect[client] = 0;
	g_iCenter[client] = 0;
	g_iChat[client] = 0;
	g_iSet[client] = 0;
	
	GetClientName(client, sName, sizeof(sName));
	GetClientAuthString(client, sSteamID, sizeof(sSteamID));
	
	if(KvGotoFirstSubKey(g_hSettings))
	{
		do
		{
			if(!g_iSet[client])		//if client doesnt already match any previous setups - 0 = none, 1 = normal setup, 2 = ignore
			{
				KvGetSectionName(g_hSettings, sSectionName, sizeof(sSectionName));
				g_iConnect[client] = KvGetNum(g_hSettings, "connectmsg", 0);
				g_iDisconnect[client] = KvGetNum(g_hSettings, "disconnectmsg", 0);
				iIgnoreConnect[client] = KvGetNum(g_hSettings, "ignoreconnect", 0);
				iIgnoreDisconnect[client] = KvGetNum(g_hSettings, "ignoredisconnect", 0);
				KvGetString(g_hSettings, "flags", sFlags, sizeof(sFlags), "public");

				if((g_iConnect[client] && g_iIsConnectMsg[client]) || (g_iDisconnect[client] && g_iIsDisconnectMsg[client]) || (iIgnoreConnect[client] && g_iIsConnectMsg[client]) || (iIgnoreDisconnect[client] && g_iIsDisconnectMsg[client]))	//if the section is an applicable connect or disconnect message
				{
					if(StrEqual(sSectionName, sSteamID))		//if section name is the clients steam ID
					{
						if((iIgnoreConnect[client] && g_iIsConnectMsg[client]) || (iIgnoreDisconnect[client] && g_iIsDisconnectMsg[client]))	//if the section is set for ignoring messages
						{
							g_iSet[client] = 2;
							return;
						}
						else
						{
							//finish getting setup
							g_iCenter[client] = KvGetNum(g_hSettings, "center", 1);
							g_iChat[client] = KvGetNum(g_hSettings, "chat", 1);
							KvGetString(g_hSettings, "chatcolor", sChatColor, sizeof(sChatColor), "FFFFFF");
							KvGetString(g_hSettings, "tag", sTag, sizeof(sTag), "[TagNotSet]");
							KvGetString(g_hSettings, "tagcolor", sTagColor, sizeof(sTagColor), "FFFFFF");
							KvGetString(g_hSettings, "message", g_sMessage[client], sizeof(g_sMessage[]), "{tag} {playername} Connected/Disconnected");

							decl String:sBuffer[300];
							
							//copy g_sMessage to sBuffer and g_sCenterMsg before editing
							//g_sMessage is the original text - used in debug later
							//g_sCenterMsg is after replacing {tag} and {playername} - used for center msg
							//sBuffer will be used to format the chat msg
							strcopy(sBuffer, sizeof(sBuffer), g_sMessage[client]);
							strcopy(g_sCenterMsg[client], sizeof(g_sCenterMsg[]), g_sMessage[client]);

							//replace strings in g_sCenterMsg so that it is ready for center display
							ReplaceString(g_sCenterMsg[client], sizeof(g_sCenterMsg[]), "{tag}", sTag, false);
							ReplaceString(g_sCenterMsg[client], sizeof(g_sCenterMsg[]), "{playername}", sName, false);

							//ready chat colors and tag colors
							ReplaceString(sChatColor, sizeof(sChatColor), "#", "", false);	//just in case they add it in, despite being told not to
							ReplaceString(sTagColor, sizeof(sTagColor), "#", "", false);

							//format tag
							decl String:sFormattedTag[300];
							Format(sFormattedTag, sizeof(sFormattedTag), "\x07%s%s\x07%s", sTagColor, sTag, sChatColor);	//sets color to sTagColor, adds tag, then sets color back to sChatColor
							
							//format entire message
							ReplaceString(sFormattedTag, sizeof(sFormattedTag), "{playername}", sName, false);	//if tag includes {playername}, replace with clients name
							ReplaceString(sBuffer, sizeof(sBuffer), "{tag}", sFormattedTag, false);
							ReplaceString(sBuffer, sizeof(sBuffer), "{playername}", sName, false);

							Format(g_sFormattedMsg[client], sizeof(g_sFormattedMsg[]), "\x07%s%s ", sChatColor, sBuffer);
							
							g_iSet[client] = 1;		//mark as having found a valid connect msg
						}
					}
					else if(HasFlags(client, sFlags))		//if the client has the required flags for the section
					{
						if(StrContains(sSectionName, "STEAM_", true) == -1)
						{					
							if((iIgnoreConnect[client] && g_iIsConnectMsg[client]) || (iIgnoreDisconnect[client] && g_iIsDisconnectMsg[client]))	//if the section is set for ignoring messages
							{
								g_iSet[client] = 2;
								return;
							}
							else
							{
								//finish getting setup
								g_iCenter[client] = KvGetNum(g_hSettings, "center", 1);
								g_iChat[client] = KvGetNum(g_hSettings, "chat", 1);
								KvGetString(g_hSettings, "chatcolor", sChatColor, sizeof(sChatColor), "FFFFFF");
								KvGetString(g_hSettings, "tag", sTag, sizeof(sTag), "[TagNotSet]");
								KvGetString(g_hSettings, "tagcolor", sTagColor, sizeof(sTagColor), "FFFFFF");
								KvGetString(g_hSettings, "message", g_sMessage[client], sizeof(g_sMessage[]), "{tag} {playername} Connected/Disconnected");

								decl String:sBuffer[300];
								
								//copy g_sMessage to sBuffer and g_sCenterMsg before editing
								//g_sMessage is the original text - used in debug later
								//g_sCenterMsg is after replacing {tag} and {playername} - used for center msg
								//sBuffer will be used to format the chat msg
								strcopy(sBuffer, sizeof(sBuffer), g_sMessage[client]);
								strcopy(g_sCenterMsg[client], sizeof(g_sCenterMsg[]), g_sMessage[client]);

								//replace strings in g_sCenterMsg so that it is ready for center display
								ReplaceString(g_sCenterMsg[client], sizeof(g_sCenterMsg[]), "{tag}", sTag, false);
								ReplaceString(g_sCenterMsg[client], sizeof(g_sCenterMsg[]), "{playername}", sName, false);

								//ready chat colors and tag colors
								ReplaceString(sChatColor, sizeof(sChatColor), "#", "", false);	//just in case they add it in, despite being told not to
								ReplaceString(sTagColor, sizeof(sTagColor), "#", "", false);

								//format tag
								decl String:sFormattedTag[300];
								Format(sFormattedTag, sizeof(sFormattedTag), "\x07%s%s\x07%s", sTagColor, sTag, sChatColor);	//sets color to sTagColor, adds tag, then sets color back to sChatColor
								
								//format entire message
								ReplaceString(sFormattedTag, sizeof(sFormattedTag), "{playername}", sName, false);	//if tag includes {playername}, replace with clients name
								ReplaceString(sBuffer, sizeof(sBuffer), "{tag}", sFormattedTag, false);
								ReplaceString(sBuffer, sizeof(sBuffer), "{playername}", sName, false);

								Format(g_sFormattedMsg[client], sizeof(g_sFormattedMsg[]), "\x07%s%s ", sChatColor, sBuffer);
								
								g_iSet[client] = 1;		//mark as having found a valid connect msg
							}
						}
					}
					else if(StrContains(sFlags, "public", true) != -1)	//if the section is available to the public
					{
						if(StrContains(sSectionName, "STEAM_", true) == -1)
						{
							if((iIgnoreConnect[client] && g_iIsConnectMsg[client]) || (iIgnoreDisconnect[client] && g_iIsDisconnectMsg[client]))	//if the section is set for ignoring messages
							{
								g_iSet[client] = 2;
								return;
							}
							else
							{
								//finish getting setup
								g_iCenter[client] = KvGetNum(g_hSettings, "center", 1);
								g_iChat[client] = KvGetNum(g_hSettings, "chat", 1);
								KvGetString(g_hSettings, "chatcolor", sChatColor, sizeof(sChatColor), "FFFFFF");
								KvGetString(g_hSettings, "tag", sTag, sizeof(sTag), "[TagNotSet]");
								KvGetString(g_hSettings, "tagcolor", sTagColor, sizeof(sTagColor), "FFFFFF");
								KvGetString(g_hSettings, "message", g_sMessage[client], sizeof(g_sMessage[]), "{tag} {playername} Connected/Disconnected");

								decl String:sBuffer[300];
								
								//copy g_sMessage to sBuffer and g_sCenterMsg before editing
								//g_sMessage is the original text - used in debug later
								//g_sCenterMsg is after replacing {tag} and {playername} - used for center msg
								//sBuffer will be used to format the chat msg
								strcopy(sBuffer, sizeof(sBuffer), g_sMessage[client]);
								strcopy(g_sCenterMsg[client], sizeof(g_sCenterMsg[]), g_sMessage[client]);

								//replace strings in g_sCenterMsg so that it is ready for center display
								ReplaceString(g_sCenterMsg[client], sizeof(g_sCenterMsg[]), "{tag}", sTag, false);
								ReplaceString(g_sCenterMsg[client], sizeof(g_sCenterMsg[]), "{playername}", sName, false);

								//ready chat colors and tag colors
								ReplaceString(sChatColor, sizeof(sChatColor), "#", "", false);	//just in case they add it in, despite being told not to
								ReplaceString(sTagColor, sizeof(sTagColor), "#", "", false);

								//format tag
								decl String:sFormattedTag[300];
								Format(sFormattedTag, sizeof(sFormattedTag), "\x07%s%s\x07%s", sTagColor, sTag, sChatColor);	//sets color to sTagColor, adds tag, then sets color back to sChatColor
								
								//format entire message
								ReplaceString(sFormattedTag, sizeof(sFormattedTag), "{playername}", sName, false);	//if tag includes {playername}, replace with clients name
								ReplaceString(sBuffer, sizeof(sBuffer), "{tag}", sFormattedTag, false);
								ReplaceString(sBuffer, sizeof(sBuffer), "{playername}", sName, false);

								Format(g_sFormattedMsg[client], sizeof(g_sFormattedMsg[]), "\x07%s%s ", sChatColor, sBuffer);
								
								g_iSet[client] = 1;		//mark as having found a valid connect msg
							}
						}
					}
				}
			}
			else
			{
				break;	//break loop to avoid excess processing if a setup is found
			}
		} while (KvGotoNextKey(g_hSettings, false));
		KvGoBack(g_hSettings);
	}
	CloseHandle(g_hSettings);
}

ShowMsg(any:client)
{
	if(g_iCenter[client])
	{
		PrintCenterTextAll("%s", g_sCenterMsg[client]);
	}
	if(g_iChat[client])
	{
		PrintToChatAll("%s", g_sFormattedMsg[client]);
	}
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hMainEnabled)
	{
		g_iMainEnabled = StringToInt(newvalue);
	}
	if(cvar == g_hEnableDelay)
	{
		g_iEnableDelay = StringToInt(newvalue);
	}
	if(cvar == g_hDelayTime)
	{
		g_iDelayTime = StringToInt(newvalue);
	}
}

/*
Changelog
4.0
*Increased msg buffers to 300 to try to fix partial msgs happening
*Recoded most of plugin to avoid global variables and keep within single functions. This avoids needlessly using resources and having to create arrays for all players.
*Removed admin menu include....not sure why that was in there.
*Recoded everything to use sizeof() instead of actual numbers to allow more flexibility.
*Added a break to the loops to avoid excess loops (although most of it wouldnt process due to one of the first lines anyways, still, this is better)
*/