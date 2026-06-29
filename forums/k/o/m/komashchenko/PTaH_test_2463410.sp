#pragma semicolon 1
#include <PTaH>

public void OnPluginStart() 
{
	PTaH(PTaH_ExecuteStringCommand, Hook, ExecuteStringCommand);
	PTaH(PTaH_OnClientConnect, Hook, OnClientConnectPre);
	PTaH(PTaH_GiveNamedItemPre, Hook, GiveNamedItemPre);
	PTaH(PTaH_MapContentList, Hook, MapContentList);
	PTaH(PTaH_WeaponCanUse, Hook, WeaponCanUse);
	PTaH(PTaH_ConsolePrint, Hook, ConsolePrint);
	PTaH(PTaH_SetPlayerModel, Hook, SetPlayerModel);
	PTaH(PTaH_ServerConsolePrint, Hook, ServerConsolePrint);
	RegConsoleCmd("ptah", ptah_);
}

	
public Action ptah_(int iClient, int args)
{
	char buf[64];
	
	AddrInfo addr;
	int res = PTaH_GetAddrInfo("forums.alliedmods.net", AF_UNSPEC, addr);
	if(res == 0)
	{
		PrintToChatAll("GetAddrInfo - forums.alliedmods.net");
		AddrInfo p;
		for(p = addr; p; p = p.NextIP)
		{
			p.GetIP(buf, sizeof(buf));
			PrintToChatAll("%s %s", p.Family == 2 ? "IP":"IP6", buf);
		}
		addr.ClearMem();
	}
	else
	{
		PTaH_Gai_StrError(res, buf, sizeof(buf));
		PrintToChatAll("GetAddrInfo - %d %s", res, buf);
	}
	
	PTaH_MD5File("addons/metamod.vdf", buf, sizeof(buf));
	PrintToChatAll("HASH - addons/metamod.vdf - %s", buf);
	return Plugin_Handled;
}

public Action ExecuteStringCommand(int iClient, char sMessage[512])
{
	//Blocking command status
	static char sMessage2[512];
	sMessage2 = sMessage;
	//Remove space and tabs (commands its passed in the original form without a slew of front space and tab and etc) "   		status   "
	TrimString(sMessage2); 
	// Client could write "status 3453 4534 5456 2354"
	if(StrContains(sMessage2, "status") == 0)
	{
		PrintToChatAll("%N Introduced command status", iClient);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnClientConnectPre(const char[] sName, char sPassword[128], const char[] sIp, const char[] sSteamID, char rejectReason[512])
{
	LogMessage("OnClientConnectPre %s %s %s", sName, sIp, sSteamID);
	return Plugin_Continue;
}

//We are doing the same thing as https://forums.alliedmods.net/showthread.php?t=236199 (do not forget say thank you to Dr!fter)
public Action GiveNamedItemPre(int iClient, char sClassname[64], CEconItemView &Item)
{
	if(!Item || !Item.IsCustomItemView())
	{
		CEconItemDefinition ItemDefinition = PTaH_GetItemDefinitionByName(sClassname);
		if(ItemDefinition)
		{
			int iTeam = GetClientTeam(iClient);
			int iLoadoutSlot = ItemDefinition.GetLoadoutSlot();
			CEconItemView Item2 = PTaH_GetItemInLoadout(iClient, iTeam, iLoadoutSlot);
			if(!Item2.IsCustomItemView())
			{
				Item2 = PTaH_GetItemInLoadout(iClient, iTeam == 2 ? 3:2, iLoadoutSlot);
				//									Fix the problem when its gave tec9 instead five-seven
				if(Item2.IsCustomItemView() && ItemDefinition.GetDefinitionIndex() == Item2.GetItemDefinition().GetDefinitionIndex())
				{
					Item = Item2;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

//Blocking loading .nav files
public Action MapContentList(char sFile[128])
{
	if(StrContains(sFile, ".nav") != -1) return Plugin_Handled;
	return Plugin_Continue;
}

//Allowing Counter-terrorist pick up C4
public bool WeaponCanUse(int iClient, int iEnt, bool CanUse)
{
	static char sClassname[64];
	GetEdictClassname(iEnt, sClassname, sizeof(sClassname));
	if(StrEqual(sClassname, "weapon_c4")) return true;
	return CanUse;
}

//Withdraw in the chat client that writes to the console
public Action ConsolePrint(int iClient, char sMessage[512])
{
	PrintToChat(iClient, sMessage);
	return Plugin_Continue;
}

public void SetPlayerModel(int iClient, const char[] sModel)
{
	PrintToChatAll("%N Set Model %s", iClient, sModel);
}

//Block out messages that contain DataTable warning
public Action ServerConsolePrint(const char[] sMessage)
{
	if (StrContains(sMessage, "DataTable warning") != -1) return Plugin_Handled;
	return Plugin_Continue;
}