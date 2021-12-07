#pragma semicolon 1
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <autoexecconfig>
#include <sdktools>

new Handle:g_hAdminFlag = INVALID_HANDLE;
new String:g_sAdminFlag[30];

public Plugin:myinfo =
{
	name = "TOG Button Notifications",
	author = "That One Guy",
	description = "Notifies admins of who presses buttons",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=188078"
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("togbuttons");
	AutoExecConfig_CreateConVar("tb_version", PLUGIN_VERSION, "TOG Button Notifications: Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hAdminFlag = AutoExecConfig_CreateConVar("tb_adminflag", "b", "Only players with this flag will receive the button info msgs (set to \"public\" for everyone to see it).");
	HookConVarChange(g_hAdminFlag, OnCVarChange);
	GetConVarString(g_hAdminFlag, g_sAdminFlag, sizeof(g_sAdminFlag));
	
	HookEntityOutput("func_button", "OnIn", FuncButtonOutput);
	HookEntityOutput("func_rot_button", "OnIn", FuncButtonOutput);
	
	RegConsoleCmd("sm_ident", Cmd_ID);
}

public OnCVarChange(Handle:hCVar, const String:sOldValue[], const String:sNewValue[])
{
	if(hCVar == g_hAdminFlag)
	{
		GetConVarString(g_hAdminFlag, g_sAdminFlag, sizeof(g_sAdminFlag));
	}
}

public FuncButtonOutput(const String:sOutput[], iButtonID, iActivator, Float:fDelay)
{
	new iHammerID = GetEntProp(iButtonID, Prop_Data, "m_iHammerID");
	new iOriginOffset = FindSendPropInfo("CBasePlayer", "m_vecOrigin");
	new Float:a_fEntPos[3];
	GetEntDataVector(iButtonID, iOriginOffset, a_fEntPos);
	new iEntityPos[3];
	iEntityPos[0] = RoundFloat(a_fEntPos[0]);
	iEntityPos[1] = RoundFloat(a_fEntPos[1]);
	iEntityPos[2] = RoundFloat(a_fEntPos[2]);
	
	decl String:sName[100];
	if(!IsValidClient(iActivator, true))
	{
		Format(sName, sizeof(sName), "CONSOLE");
	}
	else
	{
		GetClientAuthId(iActivator, AuthId_Steam2, sName, sizeof(sName));
		Format(sName, sizeof(sName), "%N (%s)", iActivator, sName);
	}
	
	decl String:sButtonName[MAX_NAME_LENGTH];
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

MsgAdmins_Console(String:sFlags[], String:sMsg[], any:...)
{
	decl String:sFormattedMsg[256];
	VFormat(sFormattedMsg, sizeof(sFormattedMsg), sMsg, 3);
	for(new i = 1; i <= MaxClients; i++)
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

public Action:Cmd_ID(client, iArgs)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "You must be in game to use this command!");
		return Plugin_Handled;
	}
	
	if(!HasFlags(client, g_sAdminFlag))
	{
		ReplyToCommand(client, " \x03You do not have access to this command!");
		return Plugin_Handled;
	}
	
	new iEntID = GetClientAimTarget(client, false);
	if(iEntID != -1)
	{
		ID_Ent(client, iEntID);
	}
	else
	{
		PrintToChat(client, " \x03No entities found at crosshair aim.");
	}
	return Plugin_Handled;
}

ID_Ent(client, iEntID)
{
	//Hammer ID
	new iHammerID = GetEntProp(iEntID, Prop_Data, "m_iHammerID");
	//Name
	decl String:sButtonName[MAX_NAME_LENGTH];
	sButtonName[0] = '\0';
	GetEntPropString(iEntID, Prop_Data, "m_iName", sButtonName, sizeof(sButtonName));
	if(strcmp(sButtonName, "") == 0)
	{
		sButtonName = "<no name>";
	}
	//Class
	decl String:sClassName[128];
	GetEntityClassname(iEntID, sClassName, sizeof(sClassName));
	//Location
	new iOrigin = FindSendPropInfo("CBasePlayer", "m_vecOrigin");
	new Float:a_fEntityPos[3];
	GetEntDataVector(iEntID, iOrigin, a_fEntityPos);
	new a_iEntityPos[3];
	a_iEntityPos[0] = RoundFloat(a_fEntityPos[0]);
	a_iEntityPos[1] = RoundFloat(a_fEntityPos[1]);
	a_iEntityPos[2] = RoundFloat(a_fEntityPos[2]);

	PrintToChat(client, " \x03Entity Name: %s, Class: %s\nEntityID: %i, HammerID: %i\nOrigin: x = %i ; y = %i ; z = %i", sButtonName, sClassName, iEntID, iHammerID, a_iEntityPos[0], a_iEntityPos[1], a_iEntityPos[2]);
}

bool:IsValidClient(client, bool:bAllowBots = false)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}
	return true;
}

bool:HasFlags(client, String:sFlags[])
{
	if(StrEqual(sFlags, "public", false) || StrEqual(sFlags, "", false))
	{
		return true;
	}
	
	if(StrEqual(sFlags, "none", false))
	{
		return false;
	}
	
	new AdminId:id = GetUserAdmin(client);
	if(id == INVALID_ADMIN_ID)
	{
		return false;
	}
	
	if(CheckCommandAccess(client, "sm_not_a_command", ADMFLAG_ROOT, true))
	{
		return true;
	}
	new iCount, iFound, flags;
	if(StrContains(sFlags, ";", false) != -1) //check if multiple strings
	{
		new c = 0, iStrCount = 0;
		while(sFlags[c] != '\0')
		{
			if(sFlags[c++] == ';')
			{
				iStrCount++;
			}
		}
		iStrCount++; //add one more for IP after last comma
		decl String:sTempArray[iStrCount][30];
		ExplodeString(sFlags, ";", sTempArray, iStrCount, 30);
		
		for(new i = 0; i < iStrCount; i++)
		{
			flags = ReadFlagString(sTempArray[i]);
			iCount = 0;
			iFound = 0;
			for(new j = 0; j <= 20; j++)
			{
				if(flags & (1<<j))
				{
					iCount++;

					if(GetAdminFlag(id, AdminFlag:j))
					{
						iFound++;
					}
				}
			}
			
			if(iCount == iFound)
			{
				return true;
			}
		}
	}
	else
	{
		flags = ReadFlagString(sFlags);
		iCount = 0;
		iFound = 0;
		for(new i = 0; i <= 20; i++)
		{
			if(flags & (1<<i))
			{
				iCount++;

				if(GetAdminFlag(id, AdminFlag:i))
				{
					iFound++;
				}
			}
		}

		if(iCount == iFound)
		{
			return true;
		}
	}
	return false;
}