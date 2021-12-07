#include <sourcemod>
public Plugin:myinfo = {
	name = "LinkManager for Sourcemod",
	author = "sharkdeed",
	description = "Allows players to share, view Web URLs by using commands and ingame MOTDPanel.",
	url = ""
}

/******************DEFINES******************/
#define CHAT_PREFIX					"[\x04LM\x01]"
#define CONSOLE_PREFIX				"[LM]"
#define INVALID_KEY					"INVALID_KEY"
#define KV_KEY_ENABLED				"Enabled"
#define KV_KEY_SHARENOTIFICATION	"ShareNotification"
#define KV_KEY_WEBURL				"WebURL"
#define KV_KEY_FILENAME				"FileName"
#define KV_KEY_FILEPARAMETER		"Parameter"
#define LINK_LENGTH					256

/******************GLOBALS******************/
new bool:g_Enabled =				false;
new bool:g_ShareNotification = 		false;
new String:g_pLink[MAXPLAYERS + 1][LINK_LENGTH];
new String:g_WebURL[LINK_LENGTH];
new String:g_FileName[32];
new String:g_FileParameter[16];
new String:g_sPath[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	RegConsoleCmd("sm_slink", cmd_slink);
	RegConsoleCmd("sm_vlink", cmd_vlink);
	RegConsoleCmd("sm_clink", cmd_clink);
	RegAdminCmd("lm_enabled", acmd_enabled, ADMFLAG_SLAY, "lm_enabled");
	RegAdminCmd("lm_notification", acmd_notification, ADMFLAG_SLAY, "lm_notification");
	loadSettings();
}
/* Loads the settings file */
public loadSettings()
{
	BuildPath(Path_SM, g_sPath, sizeof(g_sPath), "configs/linkmanager_settings.txt");
	KeyValues kv = new KeyValues("LinkManager");
	kv.ImportFromFile(g_sPath);
	if(!kv.GotoFirstSubKey())
		return;
	g_Enabled = bool:kv.GetNum(KV_KEY_ENABLED);
	g_ShareNotification = bool:kv.GetNum(KV_KEY_SHARENOTIFICATION);
	kv.GetString(KV_KEY_WEBURL, g_WebURL, sizeof(g_WebURL), INVALID_KEY);
	kv.GetString(KV_KEY_FILENAME, g_FileName, sizeof(g_FileName), INVALID_KEY);
	kv.GetString(KV_KEY_FILEPARAMETER, g_FileParameter, sizeof(g_FileParameter), INVALID_KEY);
	delete kv;
}
/* Handles the lm_enabled command */
public Action acmd_enabled(client, args)
{
	new c_arg = checkBooleanParams(client, args, "lm_enabled", g_Enabled);
	if(c_arg == -1)
		return Plugin_Handled;
	decl String:sSendParam[16];
	IntToString(c_arg, sSendParam, sizeof(sSendParam));
	g_Enabled = bool:c_arg;
	changeKvKey(KV_KEY_ENABLED, sSendParam);
	return Plugin_Handled;
}
/* Handles the lm_notification command */
public Action acmd_notification(client, args)
{
	new c_arg = checkBooleanParams(client, args, "lm_notification", g_ShareNotification);
	if(c_arg == -1)
		return Plugin_Handled;
	decl String:sSendParam[16];
	IntToString(c_arg, sSendParam, sizeof(sSendParam));
	g_ShareNotification = bool:c_arg;
	changeKvKey(KV_KEY_SHARENOTIFICATION, sSendParam);
	return Plugin_Handled;
}
/* Checks if the given parameters are valid boolean.
 * client = client id
 * args = user given parameter
 * sCommand = executed command
 * bCurrent = current value of the executed command
 */
public checkBooleanParams(client, args, const String:sCommand[], bool:bCurrent)
{
	decl String:sDefaultResponse[] = "%s %s = %i // Usage: %s <0|1> 0 disables. 1 activates";
	if(args < 1)
	{
		PrintToConsole(client, sDefaultResponse, CONSOLE_PREFIX, sCommand, bCurrent, sCommand);
		return -1;
	}
	decl String:c_sArg[16];
	GetCmdArg(1, c_sArg, sizeof(c_sArg));
	new c_arg = StringToInt(c_sArg);
	if(!StrEqual(c_sArg, "0") && !StrEqual(c_sArg, "1"))
	{
		PrintToConsole(client, sDefaultResponse, CONSOLE_PREFIX, sCommand, bCurrent, sCommand);
		return -1;
	}
	else
		return c_arg;
}
/* Handles the sm_slink command */
public Action cmd_slink(client, args)
{
	if(!g_Enabled) return Plugin_Handled;
	if(args < 1)
	{
		PrintToChat(client, "%s Usage: !slink <link without http:// or https://>", CHAT_PREFIX);
		PrintToConsole(client, "%s Usage: sm_slink <link without http:// or https://>", CONSOLE_PREFIX);
		return Plugin_Handled;
	}
	decl String:sLink[LINK_LENGTH];
	GetCmdArg(1, sLink, sizeof(sLink));
	if(!checkHttpPrefix(sLink))
	{
		PrintToChat(client, "%s Please post your link without http:// or https://", CHAT_PREFIX);
		return Plugin_Handled;
	}
	Format(sLink, sizeof(sLink), "%s/%s?%s=http://%s", g_WebURL, g_FileName, g_FileParameter, sLink);
	g_pLink[client] = sLink;
	PrintToChat(client, "%s Link has been shared.", CHAT_PREFIX);
	if(g_ShareNotification)
	{
		decl String:sPlayer[32];
		GetClientName(client, sPlayer, sizeof(sPlayer));
		PrintToChatAll("%s %s has just shared a link. Use !vlink %s(or first few characters) to view the link.", CHAT_PREFIX, sPlayer, sPlayer);
	}
	return Plugin_Handled;
}
/* Handles the sm_vlink command */
public Action cmd_vlink(client,args)
{
	if(!g_Enabled) return Plugin_Handled;
	decl String:userName[64];
	GetCmdArg(1, userName, sizeof(userName));
	new id = findUser(userName);
	if(id == 0)
	{
		PrintToChat(client, "%s Couldn't find the user.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	if(StrEqual(g_pLink[id], ""))
	{
		decl String:sPlayer[32];
		GetClientName(id, sPlayer, sizeof(sPlayer));
		PrintToChat(client, "%s %s hasn't share any link", CHAT_PREFIX, sPlayer);
	} 
	ShowMOTDPanel(client, "LinkManager", g_pLink[id], MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}
/* Handles the sm_clink command */
public Action cmd_clink(client, args)
{
	if(!g_Enabled) return Plugin_Handled;
	g_pLink[client] = "";
	PrintToChat(client, "%s Link has been deleted.", CHAT_PREFIX);
	return Plugin_Handled;
}
/* Checks if the user given url posted with http:// prefix 
 * sUrl = user given Web URL.
 */
public checkHttpPrefix(const String:sUrl[])
{
	decl String:prefix[5];
	strcopy(prefix, sizeof(prefix), sUrl);
	if(StrEqual(prefix, "http"))
		return 0;
	return 1;
}
/* Searches and finds the user by username or usernames first few characters */
public findUser(const String:userName[])
{
	decl String:clientName[64];
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i))
			continue;
		GetClientName(i, clientName, sizeof(clientName));
		if(StrContains(clientName, userName) != -1)
			return i;
	}
	return 0;
}
/* Handles the keyvalue changes */
public changeKvKey(const String:keyName[], const String:keyValue[])
{
	KeyValues kv = new KeyValues("LinkManager");
	kv.ImportFromFile(g_sPath);
	if(!kv.GotoFirstSubKey())
		return;
	kv.SetString(keyName, keyValue);
	kv.Rewind();
	kv.ExportToFile(g_sPath);
	delete kv;
}