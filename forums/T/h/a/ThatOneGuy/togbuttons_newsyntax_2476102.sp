/* put the line below after all of the includes!
#pragma newdecls required
*/

#pragma semicolon 1
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <autoexecconfig>
#include <sdktools>

ConVar g_hAdminFlag = null;
char g_sAdminFlag[30];

public Plugin myinfo =
{
	name = "TOG Button Notifications",
	author = "That One Guy",
	description = "Notifies admins of who presses buttons",
	version = PLUGIN_VERSION,
	url = "http://www.togcoding.tech"
}

public void OnPluginStart()
{
	AutoExecConfig_SetFile("togbuttons");
	AutoExecConfig_CreateConVar("tb_version", PLUGIN_VERSION, "TOG Button Notifications: Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hAdminFlag = AutoExecConfig_CreateConVar("tb_adminflag", "b", "Only players with this flag will receive the button info msgs (set to \"public\" for everyone to see it).", _);
	g_hAdminFlag.GetString(g_sAdminFlag, sizeof(g_sAdminFlag));
	g_hAdminFlag.AddChangeHook(OnCVarChange);
	
	HookEntityOutput("func_button", "OnIn", FuncButtonOutput);
	HookEntityOutput("func_rot_button", "OnIn", FuncButtonOutput);
}

public void OnCVarChange(ConVar hCVar, const char[] sOldValue, const char[] sNewValue)
{
	if(hCVar == g_hAdminFlag)
	{
		g_hAdminFlag.GetString(g_sAdminFlag, sizeof(g_sAdminFlag));
	}
}

public void FuncButtonOutput(const char[] sOutput, int iButtonID, int iActivator, float fDelay)
{
	int iHammerID = GetEntProp(iButtonID, Prop_Data, "m_iHammerID");
	int iOriginOffset = FindSendPropInfo("CBasePlayer", "m_vecOrigin");
	float a_fEntPos[3];
	GetEntDataVector(iButtonID, iOriginOffset, a_fEntPos);
	int iEntityPos[3];
	iEntityPos[0] = RoundFloat(a_fEntPos[0]);
	iEntityPos[1] = RoundFloat(a_fEntPos[1]);
	iEntityPos[2] = RoundFloat(a_fEntPos[2]);
	
	char sName[100];
	if(!IsValidClient(iActivator, true))
	{
		Format(sName, sizeof(sName), "CONSOLE");
	}
	else
	{
		GetClientAuthId(iActivator, AuthId_Steam2, sName, sizeof(sName));
		Format(sName, sizeof(sName), "%N (%s)", iActivator, sName);
	}
	
	char sButtonName[MAX_NAME_LENGTH];
	GetEntPropString(iButtonID, Prop_Data, "m_iName", sButtonName, sizeof(sButtonName));
	if(StrEqual(sButtonName, "", false))
	{
		sButtonName = "<no name>";
	}
	
	MsgAdmins_Console(g_sAdminFlag, "---------------------- TOG Buttons ----------------------");
	MsgAdmins_Console(g_sAdminFlag, "%s has pressed button %s (HID: %i, EID: %i).", sName, sButtonName, iHammerID, iButtonID);
	MsgAdmins_Console(g_sAdminFlag, "Button Origin: x = %i ; y = %i ; z = %i", iEntityPos[0], iEntityPos[1], iEntityPos[2]);
	MsgAdmins_Console(g_sAdminFlag, "--------------------------------------------------");
}

void MsgAdmins_Console(char[] sFlags, char[] sMsg, any ...)
{
	char sFormattedMsg[256];
	VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 3);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(HasFlags(i, sFlags))
			{
				PrintToConsole(i, "%s", sFormattedMsg);
			}
		}
	}
}

bool IsValidClient(int client, bool bAllowBots = false)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}
	return true;
}

bool HasFlags(int client, char[] sFlags)
{
	if(StrEqual(sFlags, "public", false) || StrEqual(sFlags, "", false))
	{
		return true;
	}
	else if(StrEqual(sFlags, "none", false))	//useful for some plugins
	{
		return false;
	}
	else if(!client)	//if rcon
	{
		return true;
	}
	else if(CheckCommandAccess(client, "sm_not_a_command", ADMFLAG_ROOT, true))
	{
		return true;
	}
	
	AdminId id = GetUserAdmin(client);
	if(id == INVALID_ADMIN_ID)
	{
		return false;
	}
	int flags, clientflags;
	clientflags = GetUserFlagBits(client);
	
	if(StrContains(sFlags, ";", false) != -1) //check if multiple strings
	{
		int i = 0, iStrCount = 0;
		while(sFlags[i] != '\0')
		{
			if(sFlags[i++] == ';')
			{
				iStrCount++;
			}
		}
		iStrCount++; //add one more for stuff after last comma
		
		char[][] a_sTempArray = new char[iStrCount][30];
		ExplodeString(sFlags, ";", a_sTempArray, iStrCount, 30);
		bool bMatching = true;
		
		for(i = 0; i < iStrCount; i++)
		{
			bMatching = true;
			flags = ReadFlagString(a_sTempArray[i]);
			for(int j = 0; j <= 20; j++)
			{
				if(bMatching)	//if still matching, continue loop
				{
					if(flags & (1<<j))
					{
						if(!(clientflags & (1<<j)))
						{
							bMatching = false;
						}
					}
				}
			}
			if(bMatching)
			{
				return true;
			}
		}
		return false;
	}
	else
	{
		flags = ReadFlagString(sFlags);
		for(int i = 0; i <= 20; i++)
		{
			if(flags & (1<<i))
			{
				if(!(clientflags & (1<<i)))
				{
					return false;
				}
			}
		}
		return true;
	}
}
