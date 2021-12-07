#include <chat-processor>

#pragma semicolon 1

bool colors[MAXPLAYERS+1], all;
char tag[MAXPLAYERS+1][40], tag_Color[MAXPLAYERS+1][20], name_Color[MAXPLAYERS+1][20], chat_Color[MAXPLAYERS+1][20];
KeyValues kv;
StringMap Stweap;

#define vers "1.4"

public Plugin:myinfo =
{
	name = "Chat Colors CSGO",
	author = "Pheonix (˙·, ",
	version = vers,
	url = "http://zizt.ru/ http://hlmod.ru/"
}

public OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO) SetFailState("[Chat Colors CSGO] - Plugin only for CSGO");
	RegAdminCmd("sm_reloadcc", Command_Reload, ADMFLAG_CONFIG);
	
	Stweap = new StringMap();
	Stweap.SetString("DEFAULT", "\x01");
	Stweap.SetString("RED", "\x02");
	Stweap.SetString("TEAM", "\x03");
	Stweap.SetString("GREEN", "\x04");
	Stweap.SetString("LIME", "\x05");
	Stweap.SetString("LIGHTGREEN", "\x06");
	Stweap.SetString("LIGHTRED", "\x07");
	Stweap.SetString("GRAY", "\x08");
	Stweap.SetString("LIGHTOLIVE", "\x09");
	Stweap.SetString("OLIVE", "\x10");
	Stweap.SetString("PURPLE", "\x0E");
	Stweap.SetString("LIGHTBLUE", "\x0B");
	Stweap.SetString("BLUE", "\x0C");
}

public Action Command_Reload(int iClient, int args)
{
	LoadkKv();
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(!IsClientInGame(i) || IsFakeClient(i)) continue;
		OnClientPostAdminCheck(i);
	}
	ReplyToCommand(iClient, "[Chat Colors CSGO] - Configurations reloaded successfully");
	return Plugin_Handled;
}

public void OnMapStart()
{
	LoadkKv();
}

void LoadkKv()
{
	all = false;
	if(kv) delete kv;
	kv = new KeyValues("chat_colors_csgo");
	if(!kv.ImportFromFile("addons/sourcemod/configs/chat_colors_csgo.ini")) SetFailState("[Chat Colors CSGO] - The configurations was not founded");
	if(kv.JumpToKey("ALL")) all = true;
}

public void OnClientPostAdminCheck(int iClient)
{
	colors[iClient] = false;
	if(!IsFakeClient(iClient))
	{
		static char auth[32];
		static AdminId iId;
		GetClientAuthId(iClient, AuthId_Steam2, auth, sizeof(auth));
		kv.Rewind();
		if(kv.JumpToKey(auth))
		{
			SetColor(iClient);
			return;
		}
		if((iId = GetUserAdmin(iClient)) != INVALID_ADMIN_ID && GetAdminGroup(iId, 0, auth, sizeof(auth)) != INVALID_GROUP_ID)
		{
			Format(auth, sizeof(auth), "#%s", auth);
			if(kv.JumpToKey(auth))
			{
				SetColor(iClient);
				return;
			}
		}
		kv.GotoFirstSubKey();
		do
		{
			if(kv.GetSectionName(auth, sizeof(auth)) && auth[0] == '@')
			{
				for(int i = 1; i < sizeof(auth); i++) auth[i] = CharToLower(auth[i]);
				if(GetUserFlagBits(iClient) & ReadFlagString(auth[1]))
				{
					SetColor(iClient);
					return;
				}
			}
		}
		while kv.GotoNextKey();
		if(all)
		{
			kv.Rewind();
			kv.JumpToKey("ALL");
			SetColor(iClient);
		}
	}
}

public Action OnChatMessage(int& iClient, ArrayList recipients, eChatFlags& flag, char[] name, char[] message, bool& bProcessColors, bool& bRemoveColors)
{
	if(colors[iClient])
	{
		Format(name, MAXLENGTH_NAME, " %s%s%s%s", tag_Color[iClient], tag[iClient], name_Color[iClient], name);
		Format(message, (MAXLENGTH_MESSAGE - strlen(name) - 5), "%s%s", chat_Color[iClient], message);
		bProcessColors = false;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

void SetColor(int iClient)
{
	colors[iClient] = true;
	kv.GetString("tag", tag[iClient], sizeof(tag[]));
	kv.GetString("tag_Color", tag_Color[iClient], sizeof(tag_Color[]));
	kv.GetString("name_Color", name_Color[iClient], sizeof(name_Color[]));
	kv.GetString("chat_Color", chat_Color[iClient], sizeof(chat_Color[]));
	if(tag_Color[iClient][0]) Stweap.GetString(tag_Color[iClient], tag_Color[iClient], sizeof(tag_Color[]));
	if(name_Color[iClient][0]) Stweap.GetString(name_Color[iClient], name_Color[iClient], sizeof(name_Color[]));
	if(chat_Color[iClient][0]) Stweap.GetString(chat_Color[iClient], chat_Color[iClient], sizeof(chat_Color[]));
}