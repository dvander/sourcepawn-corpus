#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define NAME "Silent Name Change"
#define VERSION "0.0.7"
#define CSS 0
#define OTHER 1

new Handle:g_hNameTrie;
new UserMsg:g_umSayText2;
new g_iMod;

public Plugin:myinfo = 
{
	name = NAME,
	author = "meng",
	description = "Gives admins ability to change their name silently.",
	version = VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart()
{
	CreateConVar("silentnamechange_version", VERSION, NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	decl String:sMod[64];
	GetGameFolderName(sMod, sizeof(sMod));
	if (StrContains(sMod, "cstrike", false) != -1)
		g_iMod = CSS;
	else
		g_iMod = OTHER;
	g_hNameTrie = CreateTrie();
	RegAdminCmd("sm_silentnamechange", AdminCmdSilentNameChange, ADMFLAG_BAN);
	g_umSayText2 = GetUserMessageId("SayText2");
	HookUserMessage(g_umSayText2, UserMessageHook, true);
}

public OnMapStart()
{
	ClearTrie(g_hNameTrie);
}

public Action:AdminCmdSilentNameChange(client, args)
{
	if (!args || (args > 2))
	{
		ReplyToCommand(client, "[SM] Usage: sm_silentnamechange \"newname\" <1/0>");
		return Plugin_Handled;
	}
	decl String:sOGName[64], String:sArg1[64], String:sArg2[8];
	GetClientName(client, sOGName, sizeof(sOGName));
	GetCmdArg(1, sArg1, sizeof(sArg1));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	SetTrieString(g_hNameTrie, sOGName, sArg2);
	SetClientInfo(client, "name", sArg1);
	return Plugin_Handled;
}

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:sUserMess[96];
	BfReadString(bf, sUserMess, sizeof(sUserMess));
	BfReadString(bf, sUserMess, sizeof(sUserMess));
	if (StrContains(sUserMess, "Name_Change") != -1)
	{
		decl String:sBuffer1[16];
		BfReadString(bf, sUserMess, sizeof(sUserMess));
		if (GetTrieString(g_hNameTrie, sUserMess, sBuffer1, sizeof(sBuffer1)))
		{
			if (StrEqual(sBuffer1, "1"))
			{
				decl String:sBuffer2[96];
				Format(sBuffer2, sizeof(sBuffer2), "%s%s left the game (Disconnect by user.)", (g_iMod == CSS) ? "" : "Player", sUserMess);
				new Handle:hDataPack1 = CreateDataPack();
				WritePackString(hDataPack1, sBuffer2);
				CreateTimer(GetRandomFloat(0.5, 3.5), PrintToChatAllDelayed, hDataPack1);
				BfReadString(bf, sUserMess, sizeof(sUserMess));
				Format(sBuffer2, sizeof(sBuffer2), "%s%s has joined the game", (g_iMod == CSS) ? "" : "Player", sUserMess);
				new Handle:hDataPack2 = CreateDataPack();
				WritePackString(hDataPack2, sBuffer2);
				CreateTimer(GetRandomFloat(0.5, 3.5), PrintToChatAllDelayed, hDataPack2);
			}
			RemoveFromTrie(g_hNameTrie, sUserMess);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:PrintToChatAllDelayed(Handle:timer, any:data)
{
	decl String:sChatMessage[96];
	ResetPack(data);
	ReadPackString(data, sChatMessage, sizeof(sChatMessage));
	CloseHandle(data);
	PrintToChatAll(sChatMessage);
}