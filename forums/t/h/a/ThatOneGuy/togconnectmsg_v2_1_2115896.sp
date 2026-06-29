#pragma semicolon 1
#define PLUGIN_VERSION "2.1"
#include <sourcemod>
#include <autoexecconfig>	//https://github.com/Impact123/AutoExecConfig
#include <sdktools>
#include <regex>
#include <morecolors>
#undef REQUIRE_PLUGIN

new Handle:hMainEnabled = INVALID_HANDLE;			//enable plugin cvar
new Handle:g_hSettings  = INVALID_HANDLE;			//kv handle
new Handle:hEnableDelay = INVALID_HANDLE;			//enable delay on map change cvar
new Handle:hDelayTime = INVALID_HANDLE;			//cvar for length of delay
new Handle:hDelayTime_Monitor = INVALID_HANDLE;	//timer handle for delay

new iMainEnabled;									//enable plugin integer
new iEnableDelay;									//hEnableDelay integer
new iDelayTime;									//hDelayTime integer
new iDelay = 0;									//if = 1, player connections are ignored. If = 0, plugin will continue. Set to 1 on map start (if iEnableDelay = 1), then the timer sets it to 0.

public Plugin:myinfo =
{
	name = "TOG's Connect Messages v2.1",
	author = "That One Guy",
	description = "Adds customizable connect messages",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("togconnectmsg_v2");
	AutoExecConfig_CreateConVar("tcm_version", PLUGIN_VERSION, "TOGs Connect Message: Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	hMainEnabled = AutoExecConfig_CreateConVar("tcm_enabled", "1", "Enable/disable entire plugin. (0 = Disabled, 1 = Enabled).", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hMainEnabled, OnCVarChange);
	iMainEnabled = GetConVarInt(hMainEnabled);
	
	hEnableDelay = AutoExecConfig_CreateConVar("tcm_enabledelay", "0", "Enables skipping of connect announcements after map change until the time set by tcm_delay.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(hEnableDelay, OnCVarChange);
	iEnableDelay = GetConVarInt(hEnableDelay);
	
	hDelayTime = AutoExecConfig_CreateConVar("tcm_delay", "30", "Amount of time (in seconds) after map start until connect messages are enabled.");
	HookConVarChange(hDelayTime, OnCVarChange);
	iDelayTime = GetConVarInt(hDelayTime);
	
	RegAdminCmd("sm_reloadtcm", Command_Reload, ADMFLAG_BAN, "Reloads setups.");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}

public OnMapStart()
{
	if(!iMainEnabled)
		return;

	if(iEnableDelay)
	{
		iDelay = 1;
		new Float:DelayTime = float(iDelayTime);
		hDelayTime_Monitor = CreateTimer(DelayTime, DelayTimer_Monitor, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		iDelay = 0;
	}
	
	ParseSetups();
}

public OnMapEnd()		//kill/invalidate all timers/handles on map end
{
	if(hDelayTime_Monitor != INVALID_HANDLE)
	{
		KillTimer(hDelayTime_Monitor);
		hDelayTime_Monitor = INVALID_HANDLE;
	}
}

public Action:DelayTimer_Monitor(Handle:timer)
{
	if(!iMainEnabled || !hEnableDelay)
	{
		hDelayTime_Monitor = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	hDelayTime_Monitor = INVALID_HANDLE;
	
	iDelay = 0;
	
	return Plugin_Continue;
}

ParseSetups()
{	
	g_hSettings = CreateKeyValues("Setups");
	
	decl String:sPath[256];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/tog_connectmsg.txt");
	
	FileToKeyValues(g_hSettings, sPath);
}

public Action:Command_Reload(client, args)
{
	ParseSetups();
	ReplyToCommand(client, "Setups have been reloaded!");
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{		
	new String:sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	
	if(!iDelay)
	{
		ParseSetups();
		
		if(!IsClientInGame(client) || IsFakeClient(client))
		{
			return;
		}
		
		new String:sSectionName[30];			//setup name
		new String:sSectionApplied[30];		//final setup name used for client
		new String:sEnabled[2];				//setup enabled
		new String:sFlags[30];				//flags required for connect announce
		new iSet = -1;							//set to 1 if a setup has been applied
		new String:sCenter[2];				//center msg toggle
		new String:sChat[2];					//chat msg toggle
		new String:sColor[7];					//only needed if chat used
		new String:sTag[30];					//if not used, announce with no tag
		
		new AdminId:id = GetUserAdmin(client);
		
		decl String:sClientSteamID[64];
		GetClientAuthString(client, sClientSteamID, sizeof(sClientSteamID));
		
		new iCenter = -1;
		new iChat = -1;
		
		if(KvGotoFirstSubKey(g_hSettings))
		{
			do
			{
				KvGetString(g_hSettings, "enabled",  sEnabled,  sizeof(sEnabled), "1");
				KvGetString(g_hSettings, "flags", sFlags, sizeof(sFlags), "public");
				new iEnabled = StringToInt(sEnabled);
				
				KvGetSectionName(g_hSettings, sSectionName, sizeof(sSectionName));
				
				if(iSet == -1)		//if client doesnt already match any previous setups
				{
					if(iEnabled)		//if setup is enabled
					{
						if(StrEqual(sSectionName, sClientSteamID))
						{
							sSectionApplied = sSectionName;
							KvGetString(g_hSettings, "center",  sCenter,  sizeof(sCenter), "1");
							KvGetString(g_hSettings, "chat",  sChat,  sizeof(sChat), "1");
							KvGetString(g_hSettings, "color",  sColor,  sizeof(sColor), "FFFFFF");
							KvGetString(g_hSettings, "tag", sTag, sizeof(sTag), "[TagNotSet]");
							
							iSet = 1;		//mark as having found a valid connect msg
							
							iCenter = StringToInt(sCenter);
							iChat = StringToInt(sChat);
						}
						else if(HasFlags(sFlags, id))		//if admin flags apply to client or if section name is = to clients steam ID
						{
							if(!StrContains(sSectionName, "STEAM_", true) == false)
							{
								//finish getting setup
								sSectionApplied = sSectionName;
								KvGetString(g_hSettings, "center",  sCenter,  sizeof(sCenter), "1");
								KvGetString(g_hSettings, "chat",  sChat,  sizeof(sChat), "1");
								KvGetString(g_hSettings, "color",  sColor,  sizeof(sColor), "FFFFFF");
								KvGetString(g_hSettings, "tag", sTag, sizeof(sTag), "[TagNotSet]");
								
								iSet = 1;		//mark as having found a valid connect msg
								
								iCenter = StringToInt(sCenter);
								iChat = StringToInt(sChat);
							}
						}
						else if(StrContains(sFlags, "public", true) != -1)
						{
							//finish getting setup
							sSectionApplied = sSectionName;
							KvGetString(g_hSettings, "center",  sCenter,  sizeof(sCenter), "0");
							KvGetString(g_hSettings, "chat",  sChat,  sizeof(sChat), "0");
							KvGetString(g_hSettings, "color",  sColor,  sizeof(sColor), "FFFFFF");
							KvGetString(g_hSettings, "tag", sTag, sizeof(sTag), "[Tag]");
							
							iSet = 1;		//mark as having found a valid connect msg
							
							iCenter = StringToInt(sCenter);
							iChat = StringToInt(sChat);
						}
					}
				}
			} while (KvGotoNextKey(g_hSettings, false));
			KvGoBack(g_hSettings);
		}
		CloseHandle(g_hSettings);
		
		if(iSet == 1)
		{
			ConnectMsg(sName, iCenter, iChat, sColor, sTag);
		}
	}
}

bool:HasFlags(String:sFlags[], AdminId:id)
{
	if (id != INVALID_ADMIN_ID)
	{
		new count, found, flags = ReadFlagString(sFlags);
		for (new i = 0; i <= 20; i++)
		{
			if (flags & (1<<i))
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

ConnectMsg(String:sName[], iCenter, iChat, String:sColor[], String:sTag[])
{	
	decl String:strHex[16];
	strcopy(strHex, sizeof(strHex), sColor);
	ReplaceString(strHex, sizeof(strHex), "#", "", false);
	
	if(iCenter)
	{
		PrintCenterTextAll("%s %s Connected", sTag, sName);
	}
	if(iChat)
	{
		PrintToChatAll("\x07%s%s %s Connected", strHex, sTag, sName);
	}
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == hMainEnabled)
	{
		iMainEnabled = StringToInt(newvalue);
	}
	if(cvar == hEnableDelay)
	{
		iEnableDelay = StringToInt(newvalue);
	}
	if(cvar == hDelayTime)
	{
		iDelayTime = StringToInt(newvalue);
	}
}