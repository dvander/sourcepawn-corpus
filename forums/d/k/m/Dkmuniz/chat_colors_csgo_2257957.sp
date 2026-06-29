#include <sourcemod>
#include <scp>
#undef REQUIRE_PLUGIN
#include <updater>
#pragma semicolon 1

new bool:color[MAXPLAYERS+1];
new String:tag[MAXPLAYERS+1][40];
new String:tag_Color[MAXPLAYERS+1][20];
new String:name_Color[MAXPLAYERS+1][20];
new String:chat_Color[MAXPLAYERS+1][20];
new Handle:p_Updates = INVALID_HANDLE;
new Handle:kv;
new Handle:g_hColorsArray;
new Handle:configReloadedForward;

#define vers "1.2"

public Plugin:myinfo =
{
	name        = "Chat Colors CSGO",
	author      = "Phoenix - Феникс",
	version = vers,
	url = "http://zizt.ru/ http://hlmod.ru/"
}

public OnPluginStart()
{
	decl String:game[80];
	GetGameFolderName(game, 80);
	if (!StrEqual(game, "csgo")) SetFailState("[Chat Colors CSGO] - плагин только для сервера CSGO");
	if (LibraryExists("updater")) Updater_AddPlugin("http://zizt.ru/plugins/chat_colors/version");
	RegAdminCmd("sm_reloadcc", Command_Reload, ADMFLAG_CONFIG);
	configReloadedForward = CreateGlobalForward("CCC_OnConfigReloaded", ET_Ignore);
	p_Updates = CreateConVar("sm_chat_colors_updates", "1", "Автоматическое обновление плагина (при наличии Updater) желательно неотключать.", FCVAR_NONE, true, 0.0, true, 1.0);
	AutoExecConfig(true, "sm_chat_colors");
	
	g_hColorsArray = CreateTrie();
	SetTrieString(g_hColorsArray, "{DEFAULT}", "\x01");
	SetTrieString(g_hColorsArray, "{RED}", "\x02");
	SetTrieString(g_hColorsArray, "{TEAM}", "\x03");
	SetTrieString(g_hColorsArray, "{GREEN}", "\x04");
	SetTrieString(g_hColorsArray, "{LIME}", "\x05");
	SetTrieString(g_hColorsArray, "{LIGHTGREEN}", "\x06");
	SetTrieString(g_hColorsArray, "{LIGHTRED}", "\x07");
	SetTrieString(g_hColorsArray, "{GRAY}", "\x08");
	SetTrieString(g_hColorsArray, "{LIGHTOLIVE}", "\x09");
	SetTrieString(g_hColorsArray, "{OLIVE}", "\x10");
	SetTrieString(g_hColorsArray, "{PURPLE}", "\x0E");
	SetTrieString(g_hColorsArray, "{LIGHTBLUE}", "\x0B");
	SetTrieString(g_hColorsArray, "{BLUE}", "\x0C");
	
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater")) Updater_AddPlugin("http://zizt.ru/plugins/chat_colors/version");
}

public Action:Updater_OnPluginChecking()
{
	if (GetConVarBool(p_Updates)) return Plugin_Continue;
	return Plugin_Handled;
}


public Action:Command_Reload(client, args)
{
	LoadkKv();
	for(new i = 1; i <= MaxClients; i++) 
	{
		if(!IsClientInGame(i) || IsFakeClient(i)) continue;
		color[i] = false;
		OnClientPostAdminCheck(i);
	}
	ReplyToCommand(client, "[Chat Colors CSGO] - Cores foram atualizadas");
	return Plugin_Handled;
}

public OnConfigsExecuted() LoadkKv();

LoadkKv()
{
	if(kv != INVALID_HANDLE) CloseHandle(kv);
	kv = CreateKeyValues("chat_colors_csgo");
	decl String:path[64];
	BuildPath(Path_SM, path, sizeof(path), "configs/chat_colors_csgo.txt");
	if(!FileToKeyValues(kv, path)) SetFailState("[Chat Colors CSGO] - Missing file");
	
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i)) {
			continue;
		}
		OnClientPostAdminCheck(i);
	}
}

public OnClientPostAdminCheck(client)
{
	color[client] = false;
	if(!IsFakeClient(client))
	{
		decl String:auth[32];
		GetClientAuthString(client, auth, sizeof(auth));
		KvRewind(kv);
		if(KvJumpToKey(kv, auth))
		{
			color[client] = true;
			KvGetString(kv, "tag", tag[client], sizeof(tag[]));
			KvGetString(kv, "tag_Color", tag_Color[client], sizeof(tag_Color[]));
			KvGetString(kv, "name_Color", name_Color[client], sizeof(name_Color[]));
			KvGetString(kv, "chat_Color", chat_Color[client], sizeof(chat_Color[]));
		}
		else if(KvGotoFirstSubKey(kv))
		{
			decl String:section[32];
			do
			{
				if(KvGetSectionName(kv, section, sizeof(section)) && section[0] && strncmp(section, "STEAM", 5, true) != 0)
				{
					for(new i = 0; i < sizeof(section); i++) section[i] = CharToLower(section[i]);
					if(GetUserFlagBits(client) & ReadFlagString(section))
					{
						color[client] = true;
						KvGetString(kv, "tag", tag[client], sizeof(tag[]));
						KvGetString(kv, "tag_Color", tag_Color[client], sizeof(tag_Color[]));
						KvGetString(kv, "name_Color", name_Color[client], sizeof(name_Color[]));
						KvGetString(kv, "chat_Color", chat_Color[client], sizeof(chat_Color[]));	
						return;
					}
				}
			}
			while KvGotoNextKey(kv);
		}
	}
}

public Action:OnChatMessage(&client, Handle:recipients, String:name[], String:message[])
{
	if(color[client])
	{
		Format(name, MAXLENGTH_NAME, " %s%s%s%s", tag_Color[client], tag[client], name_Color[client], name);
		Format(message, (MAXLENGTH_MESSAGE - strlen(name) - 5), "%s%s", chat_Color[client], message);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
