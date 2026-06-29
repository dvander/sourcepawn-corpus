#pragma semicolon 1
#pragma newdecls required

#include <SteamWorks>

static const char
	PL_NAME[]	= "Supreme Redirect System",
	PL_VER[]	= "1.2.0_27.03.2025";

ArrayList
	hName,
	hAddress;
Menu
	hMenu;
int
	iMode,
	iNum;
char
	szCurrentIP[24];

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Uses the new 'redirect' command to make a player join a different server.",
	author		= "Mitchell, DoopieWop, Grey83",
	url			= "https://forums.alliedmods.net/showthread.php?t=258010"
}

public void OnPluginStart()
{
	CreateConVar("sm_supremeredirect_version", PL_VER, PL_NAME, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cvar = CreateConVar( "sm_supremeredirect_showaddress", "0", "Set to 1 to show the address of the server as a disabled item, 2 to let the player connect to the current server.", _, true, _, true, 2.0);
	cvar.AddChangeHook(CVarChange);
	iMode = cvar.IntValue;

	AutoExecConfig();

	RegConsoleCmd("sm_servers",  Cmd_Redirect);
	RegConsoleCmd("sm_redirect", Cmd_Redirect);
	RegConsoleCmd("sm_direct",   Cmd_Redirect);
}

public void CVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMode = cvar.IntValue;
}
public Action Cmd_Redirect(int client, int args)
{
	if(client && IsClientInGame(client) && hMenu) DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public void OnMapStart()
{
	//Could probably use steam tools or something and use this as a fall back method.
	// this doesnt work if youre using docker or similar. using steamworks now
	int ipaddr[4];
	SteamWorks_GetPublicIP(ipaddr);

	char buffer[PLATFORM_MAX_PATH];
	//GetConVarString(FindConVar("ip"), sHostIP, 32);
	FindConVar("hostport").GetString(buffer, 6);	// max value = 65535
	FormatEx(szCurrentIP, sizeof(szCurrentIP), "%d.%d.%d.%d:%s", ipaddr[0], ipaddr[1], ipaddr[2], ipaddr[3], buffer);

	iNum = 0;

	if(hMenu)    CloseHandle(hMenu);
	hMenu = new Menu(Menu_Redirect);

	if(hName)    CloseHandle(hName);
	if(hAddress) CloseHandle(hAddress);
	hName = new ArrayList(ByteCountToCells(32)), hAddress = new ArrayList(ByteCountToCells(22));	// "255.255.255.255:65535" = 22 chars

	BuildPath(Path_SM, buffer, sizeof(buffer),"configs/redirect.cfg");
	SMCParser smc = new SMCParser();
	SMC_SetReaders(smc, NewSection, KeyValue, EndSection);
	SMC_ParseFile(smc, buffer);
	CloseHandle(smc);

	if(!hAddress.Length)
	{
		LogError("No valid servers in the \"%s\" (%i invalid)!", buffer, iNum);
		CloseHandle(hMenu);
		hMenu = null;
	}
	else
	{
		hMenu.SetTitle("Server Redirect (%i servers):", hAddress.Length);
		hMenu.ExitButton = true;
	}

	PrintToServer("[%s] Servers found in the configuration file: %i valid, %i invalid.", PL_NAME, hAddress.Length, iNum - hAddress.Length);
}

public int Menu_Redirect(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char buffer[32];
		hAddress.GetString(param, buffer, sizeof(buffer));
		ClientCommand(client, "redirect %s", buffer);
		DisplayAskConnectBox(client, 45.0, buffer);

		hName.GetString(param, buffer, sizeof(buffer));
		PrintToChatAll("%N wants to move to server \"%s\"", client, buffer);
	}
	return 0;
}

public SMCResult KeyValue(SMCParser smc, const char[] name, const char[] address, bool key_quotes, bool value_quotes)
{
	++iNum;

	if(strlen(address) < 9)	// 1.2.3.4:5
	{
		LogError("Server \"%s\" have invalid address \"%s\" (too short)!", name, address);
		return SMCParse_Continue;
	}

	int i = -1, prev, len, num;
	char buffer[32];
	while(address[++i])
	{
		if(!IsCharNumeric(address[i]) && address[i] != '.' && address[i] != ':')	// "255.255.255.255:65535"
		{
			LogError("Server \"%s\" have invalid address \"%s\" (not IP:port)!", name, address);
			return SMCParse_Continue;
		}

		if(address[i] == '.' || address[i] == ':')	// IP check
		{
			if(++num > 4 || (address[i] == ':' && num != 4))
			{
				LogError("Server \"%s\" have invalid IP \"%s\" (position #%i)!", name, address, i);
				return SMCParse_Continue;
			}

			if((len = i - prev) < 1 || len > 3)
			{
				LogError("Server \"%s\" have invalid IP \"%s\" (positions #%i - #%i)!", name, address, prev, i);
				return SMCParse_Continue;
			}

			len++;
			FormatEx(buffer, 6, address[prev]);
			buffer[len] = 0;
			if((len = StringToInt(buffer)) < 0 || len > 255)
			{
				LogError("Server \"%s\" have invalid IP \"%s\" (value \"%s\" at positions #%i - #%i)!", name, address, buffer, prev, i);
				return SMCParse_Continue;
			}

			prev = i + 1;
		}
	}

	FormatEx(buffer, 8, address[prev]);
	if((len = StringToInt(buffer)) < 1 || len > 65535)	// port check
	{
		LogError("Server \"%s\" have invalid port \"%s\" (value \"%s\")!", name, address, buffer);
		return SMCParse_Continue;
	}

	FormatEx(buffer, sizeof(buffer), name[0] ? name : address);

	bool same = !strcmp(address, szCurrentIP);
	if(same && !iMode)
		return SMCParse_Continue;

	hMenu.AddItem("", buffer, same && iMode == 1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hAddress.PushString(address);
	hName.PushString(buffer);

	return SMCParse_Continue;
}

public SMCResult NewSection(SMCParser smc, const char[] name, bool opt_quotes) { return SMCParse_Continue; }

public SMCResult EndSection(SMCParser smc) { return SMCParse_Continue; }