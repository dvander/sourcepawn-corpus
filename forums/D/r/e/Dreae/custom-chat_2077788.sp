#include <sourcemod>
#include <scp>
#include <clientprefs>
#include <steamtools>
#include <sdktools>
#include <cstrike>
#pragma semicolon 1

#define PLUGIN_VERSION		"1.4.67"

new Handle:ChangeClanTag = INVALID_HANDLE;
new Handle:tagDb = INVALID_HANDLE;
new Handle:colorForward = INVALID_HANDLE;
new Handle:nameForward = INVALID_HANDLE;
new Handle:tagForward = INVALID_HANDLE;
new Handle:configFile = INVALID_HANDLE;
new Handle:configColors = INVALID_HANDLE;
new Handle:hColorsFlag = INVALID_HANDLE;
new String:lTag[MAXPLAYERS + 1][12];
new String:tag[MAXPLAYERS + 1][256];
new String:tagColor[MAXPLAYERS + 1][12];
new String:usernameColor[MAXPLAYERS + 1][12];
new String:chatColor[MAXPLAYERS + 1][12];
new Handle:groupStatus[MAXPLAYERS + 1] = INVALID_HANDLE;
new Handle:sectionArray[64] = INVALID_HANDLE;
new Handle:colorsArray[64] = INVALID_HANDLE;
new Handle:checkTag[MAXPLAYERS + 1] = INVALID_HANDLE;
new AdminFlag:ColorsFlag;
new iUsernameColor[MAXPLAYERS + 1];
new iChatColor[MAXPLAYERS + 1];
new iTagColor[MAXPLAYERS + 1];
new bool:g_bLate = false;


public Plugin:myinfo = {
	name        = "Customize Chat",
	author      = "John Smith",
	description = "Players select their own tags for use in chat",
	version     = PLUGIN_VERSION,
	url         = "http://dreaescantina.com"
};

public OnPluginStart()
{
	decl String:error[256];
	tagDb = SQL_Connect("storage-local", false, error, sizeof(error));
	
	if(tagDb == INVALID_HANDLE)
	{
		LogError("[Custom-Chat] Unable to connect to database (%s)", error);
		return;
	}
	
	SQL_LockDatabase(tagDb);
	if(!SQL_FastQuery(tagDb, "CREATE TABLE IF NOT EXISTS tags (steamid varchar(255) PRIMARY KEY, tag varchar(12) NULL, chatcolor INT NULL DEFAULT -1, namecolor INT NULL DEFAULT -1, tagcolor INT NULL DEFAULT -1);"))
	{
		LogError("[Custom-Chat] Cannot create tag database.");
	}
	SQL_FastQuery(tagDb, "ALTER TABLE tags ADD COLUMN chatcolor INT NULL DEFAULT -1;");
	SQL_FastQuery(tagDb, "ALTER TABLE tags ADD COLUMN namecolor INT NULL DEFAULT -1;");
	SQL_FastQuery(tagDb, "ALTER TABLE tags ADD COLUMN tagcolor INT NULL DEFAULT -1;");
	SQL_UnlockDatabase(tagDb);
	
	LoadTranslations("common.phrases");
	colorForward = CreateGlobalForward("OnChatColor", ET_Event, Param_Cell);
	nameForward = CreateGlobalForward("OnNameColor", ET_Event, Param_Cell);
	tagForward = CreateGlobalForward("OnTagApplied", ET_Event, Param_Cell);
	LoadConfig();
	RegConsoleCmd("sm_tags", Command_Tags);
	RegConsoleCmd("sm_chatcolors", Command_Colors);
	hColorsFlag = CreateConVar("sm_custom_colorflag", "s", "Flag for the !chatcolors command", FCVAR_PLUGIN | FCVAR_PROTECTED);
	ChangeClanTag = CreateConVar("sm_custom_clantag", "0.0","Should custom-chat change client's clantag", FCVAR_PLUGIN);
	HookConVarChange(hColorsFlag, ColorFlagChange);
	
	if(g_bLate == true)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public OnMapStart()
{
	decl String:flag[2];
	GetConVarString(hColorsFlag, flag, sizeof(flag));
	FindFlagByChar(flag[0], ColorsFlag);
}

public ColorFlagChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	FindFlagByChar(newVal[0], ColorsFlag);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLate = late;
	
	return APLRes_Success;
}

public OnClientPutInServer(client)
{
	iUsernameColor[client] = -1;
	iTagColor[client] = -1;
	iChatColor[client] = -1;
	Format(tagColor[client], sizeof(tagColor[]), "");
	Format(chatColor[client], sizeof(chatColor[]), "");
	Format(usernameColor[client], sizeof(usernameColor[]), "");
	GetClientTag(client);
	for(new c = 0; c < 64; c++)
	{
		if(sectionArray[c] != INVALID_HANDLE)
		{
			new steamgroup;
			steamgroup = GetArrayCell(sectionArray[c], 4);
			if(steamgroup > 0)
			{
				Steam_RequestGroupStatus(client, steamgroup);
			}
		}
	}
}

public Action:Timer_ClientLoaded(Handle:timer, any:client)
{
	new bool:valid = false;
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	new AdminId:admin = GetUserAdmin(client);
	new iPos = StringToInt(lTag[client]);
	decl String:array_auth[32];
	new String:array_flag[2];
	new array_immunity, steamgroup;
	new AdminFlag:flag;
	if(iPos != -1)
	{
		if(sectionArray[iPos] != INVALID_HANDLE)
		{
			GetArrayString(sectionArray[iPos], 1, array_auth, sizeof(array_auth));
			array_immunity = GetArrayCell(sectionArray[iPos], 2);
			GetArrayString(sectionArray[iPos], 3, array_flag, sizeof(array_flag));
			FindFlagByChar(array_flag[0], flag);
			steamgroup = GetArrayCell(sectionArray[iPos], 4);
			if(StrEqual(auth, array_auth, false) || StrEqual(array_auth, "default", false))
			{
				valid = true;
			}
			else if(GetAdminImmunityLevel(admin) == array_immunity && array_immunity != 0)
			{
				valid = true;
			}
			else if(GetAdminFlag(admin, flag) && !StrEqual(array_flag, ""))
			{
				valid = true;
			}
			else if(InGroup(client, steamgroup))
			{
				valid = true;
			}
			if(valid == true)
			{
				SetTag(client, iPos);
			}
		}
	}
	if(valid == false)
	{
		new i = 0;
		do
		{
			GetArrayString(sectionArray[i], 1, array_auth, sizeof(array_auth));
			array_immunity = GetArrayCell(sectionArray[i], 2);
			steamgroup = GetArrayCell(sectionArray[i], 4);
			if(StrEqual(auth, array_auth, false) || StrEqual("default", array_auth, false))
			{	
				SetTag(client, i);
				break;
			}
			else if(GetAdminImmunityLevel(admin) == array_immunity && array_immunity != 0)
			{
				SetTag(client, i);
				break;
			}
			else if(InGroup(client, steamgroup))
			{
				SetTag(client, i);
				break;
			}
			i++;
		} while(i < 32);
	}
	if(!StrEqual(tag[client], ""))
	{
		CreateTimer(2.0, Timer_PutInGame, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

GetClientTag(client)
{
	decl String:steamid[64];
	decl String:query[255];
	GetClientAuthString(client, steamid, sizeof(steamid));
	Format(query, sizeof(query), "SELECT * FROM tags WHERE steamid = '%s';", steamid);
	SQL_TQuery(tagDb, LoadPlayer_Callback, query, client);
}

public LoadPlayer_Callback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	iTagColor[data] = -1;
	iChatColor[data] = -1;
	iUsernameColor[data] = -1;
	if(hndl == INVALID_HANDLE)
	{
		LogError("[Custom-Chat] Query failed! %s", error);
		return;
	}
	if(!SQL_FetchRow(hndl))
	{
		Format(lTag[data], sizeof(lTag[]), "-1");
		decl String:query[255];
		decl String:steamid[64];
		GetClientAuthString(data, steamid, sizeof(steamid));
		Format(query, sizeof(query), "INSERT INTO tags (steamid, tag, chatcolor, namecolor, tagcolor) VALUES ('%s', '%s', '-1', '-1', '-1');", steamid, lTag[data]);
		SQL_TQuery(tagDb, T_ErrorHandle, query);
	}
	else
	{
		SQL_FetchString(hndl, 1, lTag[data], sizeof(lTag[]));
		iChatColor[data] = SQL_FetchInt(hndl, 2);
		iUsernameColor[data] = SQL_FetchInt(hndl, 3);
		iTagColor[data] = SQL_FetchInt(hndl, 4);
	}
	CreateTimer(2.0, Timer_ClientLoaded, data, TIMER_FLAG_NO_MAPCHANGE);

}


public OnClientDisconnect(client)
{
	decl String:query[255];
	decl String:steamid[64];
	GetClientAuthString(client, steamid, sizeof(steamid));
	Format(query, sizeof(query), "UPDATE tags SET tag = '%s', chatcolor = '%i', namecolor = '%i', tagcolor = '%i' WHERE steamid = '%s'", lTag[client], iChatColor[client], iUsernameColor[client], iTagColor[client], steamid);
	SQL_TQuery(tagDb, T_ErrorHandle, query);
	if(checkTag[client] != INVALID_HANDLE)
	{
		KillTimer(checkTag[client]);
		checkTag[client] = INVALID_HANDLE;
	}
	if(groupStatus[client] != INVALID_HANDLE)
	{
		CloseHandle(groupStatus[client]);
		groupStatus[client] = INVALID_HANDLE;
	}
}

public Action:Timer_PutInGame(Handle:timer, any:data)
{
	if(GetConVarInt(ChangeClanTag) == 1)
	{
		CS_SetClientClanTag(data, tag[data]);
		if(checkTag[data] == INVALID_HANDLE)
		{
			checkTag[data] = CreateTimer(5.0, Timer_CheckTag, data, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		}	
	}
}

public Steam_GroupStatusResult(client, groupAccountID, bool:groupMember, bool:groupOfficer)
{
	if(groupMember == true)
	{
		if(groupStatus[client] == INVALID_HANDLE)
		{
			groupStatus[client] = CreateArray(64);
		}
		PrintToServer("%N is a member of %i", client, groupAccountID);
		PushArrayCell(groupStatus[client], groupAccountID);
	}
}

public Action:Timer_CheckTag(Handle:timer, any:data)
{
	if(IsClientInGame(data))
	{
		decl String:bTag[64];
		CS_GetClientClanTag(data, bTag, sizeof(bTag));
		if(!StrEqual(bTag, tag[data]))
		{
			CS_SetClientClanTag(data, tag[data]);
		}
	}
}
	

public LoadConfig()
{
	if(configFile != INVALID_HANDLE) {
		CloseHandle(configFile);
		configFile = INVALID_HANDLE;
	}
	if(configColors != INVALID_HANDLE){
		CloseHandle(configColors);
		configColors = INVALID_HANDLE;
	}
	configFile = CreateKeyValues("available_tags");
	configColors = CreateKeyValues("available_colors");
	decl String:path[64];
	decl String:path2[64];
	BuildPath(Path_SM, path, sizeof(path), "configs/custom-colors.cfg");
	BuildPath(Path_SM, path2, sizeof(path2), "configs/custom-chat.cfg");
	if(!FileToKeyValues(configFile, path2)) {
		SetFailState("Config file missing");
	}
	if(!FileToKeyValues(configColors, path)) {
		SetFailState("Config file missing");
	}
	new i = 0;
	KvRewind(configFile);
	KvGotoFirstSubKey(configFile);
	do
	{
		decl String:section[64];
		KvGetSectionName(configFile, section, sizeof(section));
		sectionArray[i] = CreateArray(256);
		PushArrayString(sectionArray[i], section);
		decl String:flag[2];
		decl String:auth[32];
		new group;
		new immunity;
		KvGetString(configFile, "flag", flag, sizeof(flag));
		immunity = KvGetNum(configFile, "immunity");
		KvGetString(configFile, "steamid", auth, sizeof(auth));
		group = KvGetNum(configFile, "steamgroup");
		PushArrayString(sectionArray[i], auth);
		PushArrayCell(sectionArray[i], immunity);
		PushArrayString(sectionArray[i], flag);
		PushArrayCell(sectionArray[i], group);
		decl String:_tag[256];
		decl String:clientTagColor[12];
		decl String:clientNameColor[12];
		decl String:clientChatColor[12];
		KvGetString(configFile, "tag", _tag, sizeof(_tag));
		KvGetString(configFile, "tagcolor", clientTagColor, sizeof(clientTagColor));
		KvGetString(configFile, "namecolor", clientNameColor, sizeof(clientNameColor));
		KvGetString(configFile, "textcolor", clientChatColor, sizeof(clientChatColor));
		ReplaceString(_tag, sizeof(_tag), "#", "\x07");
		PushArrayString(sectionArray[i], _tag);
		PushArrayString(sectionArray[i], clientTagColor);
		PushArrayString(sectionArray[i], clientNameColor);
		PushArrayString(sectionArray[i], clientChatColor);
		i++;
	} while(KvGotoNextKey(configFile));
	i = 0;
	KvRewind(configColors);
	KvGotoFirstSubKey(configColors);
	do
	{
		decl String:section[64];
		KvGetSectionName(configColors, section, sizeof(section));
		colorsArray[i] = CreateArray(64);
		PushArrayString(colorsArray[i], section);
		decl String:color[12];
		KvGetString(configColors, "color", color, sizeof(color));
		PushArrayString(colorsArray[i], color);
		i++;
	} while(KvGotoNextKey(configColors));
}

public Action:Command_Tags(client, args)
{
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	new String:tags[64][64];
	new AdminId:admin = GetUserAdmin(client);
	for(new i = 0; i < 64; i++)
	{
		if(sectionArray[i] != INVALID_HANDLE)
		{
			decl String:array_auth[32];
			new String:array_flag[2];
			new array_immunity, steamgroup;
			new AdminFlag:flag;
			GetArrayString(sectionArray[i], 1, array_auth, sizeof(array_auth));
			array_immunity = GetArrayCell(sectionArray[i], 2);
			GetArrayString(sectionArray[i], 3, array_flag, sizeof(array_flag));
			steamgroup = GetArrayCell(sectionArray[i], 4);
			FindFlagByChar(array_flag[0], flag);
			if(StrEqual(auth, array_auth, false) || StrEqual("default", array_auth, false))
			{
				GetArrayString(sectionArray[i], 0, tags[i], sizeof(tags[]));
			}
			else if(GetAdminImmunityLevel(admin) == array_immunity && array_immunity != 0)
			{
				GetArrayString(sectionArray[i], 0, tags[i], sizeof(tags[]));
			}
			else if(GetAdminFlag(admin, flag) && !StrEqual(array_flag, ""))
			{
				GetArrayString(sectionArray[i], 0, tags[i], sizeof(tags[]));
			}
			else if(InGroup(client, steamgroup))
			{
				GetArrayString(sectionArray[i], 0, tags[i], sizeof(tags[]));
			}
		}
	}
	new Handle:menu = CreateMenu(TagMenu);
	SetMenuTitle(menu, "Select a Tag:");
	for(new i = 0; i < 64; i++)
	{
		if(strlen(tags[i]) > 0)
		{
			new String:sPos[8];
			IntToString(i, sPos, sizeof(sPos));
			AddMenuItem(menu, sPos, tags[i]);
		}
	}
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

public Action:Command_Colors(client, args)
{
	new AdminId:admin = GetUserAdmin(client);
	if(GetAdminFlag(admin, ColorsFlag) || GetAdminFlag(admin, Admin_Kick))
	{
		new Handle:menu = CreateMenu(ColorMenu);
		SetMenuTitle(menu, "Select a Color to Change:");
		AddMenuItem(menu, "name", "Name");
		AddMenuItem(menu, "chat", "Chat");
		AddMenuItem(menu, "tag", "Tag");
		DisplayMenu(menu, client, 20);
	}
	else
	{
		ReplyToCommand(client, "[Custom-Chat] You do not have access to that command");
	}
	return Plugin_Handled;
}

public ColorMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		new String:colors[64][12];
		for(new i = 0; i < 64; i++)
		{
			if(colorsArray[i] != INVALID_HANDLE)
			{
				GetArrayString(colorsArray[i], 0, colors[i], sizeof(colors[]));
			}
		}
		new Handle:_menu = INVALID_HANDLE;
		if(StrEqual(info, "name"))
		{
			_menu = CreateMenu(NameColorMenu);
			SetMenuTitle(_menu, "Select a Color:");
			AddMenuItem(_menu, "default", "Default");
			for(new i = 0; i < 64; i++)
			{
				if(strlen(colors[i]) > 0)
				{
					new String:sPos[8];
					IntToString(i, sPos, sizeof(sPos));
					AddMenuItem(_menu, sPos, colors[i]);
				}	
			}
		}
		else if(StrEqual(info, "tag"))
		{
			_menu = CreateMenu(TagColorMenu);
			SetMenuTitle(_menu, "Select a Color:");
			AddMenuItem(_menu, "default", "Default");
			for(new i = 0; i < 64; i++)
			{
				if(strlen(colors[i]) > 0)
				{
					new String:sPos[8];
					IntToString(i, sPos, sizeof(sPos));
					AddMenuItem(_menu, sPos, colors[i]);
				}	
			}
		}
		else if(StrEqual(info, "chat"))
		{
			_menu = CreateMenu(ChatColorMenu);
			SetMenuTitle(_menu, "Select a Color:");
			AddMenuItem(_menu, "default", "Default");
			for(new i = 0; i < 64; i++)
			{
				if(strlen(colors[i]) > 0)
				{
					new String:sPos[8];
					IntToString(i, sPos, sizeof(sPos));
					AddMenuItem(_menu, sPos, colors[i]);
				}	
			}
		}
		DisplayMenu(_menu, param1, 20);
	}
}

public NameColorMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:info[32];
		new TagPos;
		TagPos = StringToInt(lTag[param1]);
		GetMenuItem(menu, param2, info, sizeof(info));
		if(!StrEqual(info, "default"))
		{
			new iPos;
			iPos = StringToInt(info);
			iUsernameColor[param1] = iPos;
		}
		else
		{
			iUsernameColor[param1] = -1;
		}
		SetTag(param1, TagPos);
	}
}

public TagColorMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:info[32];
		new TagPos;
		TagPos = StringToInt(lTag[param1]);
		GetMenuItem(menu, param2, info, sizeof(info));
		if(!StrEqual(info, "default"))
		{
			new iPos;
			iPos = StringToInt(info);
			iTagColor[param1] = iPos;
		}
		else
		{
			iTagColor[param1] = -1;
		}
		SetTag(param1, TagPos);
	}
}

public ChatColorMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:info[32];
		new TagPos;
		TagPos = StringToInt(lTag[param1]);
		GetMenuItem(menu, param2, info, sizeof(info));
		if(!StrEqual(info, "default"))
		{
			new iPos;
			iPos = StringToInt(info);
			iChatColor[param1] = iPos;
		}
		else
		{
			iChatColor[param1] = -1;
		}
		SetTag(param1, TagPos);
	}
}

public TagMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		decl String:info[32];
		new iPos;
		GetMenuItem(menu, param2, info, sizeof(info));
		Format(lTag[param1], sizeof(lTag[]), info);
		iPos = StringToInt(info);
		SetTag(param1, iPos);
	}
}
public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[]) {
	if(NameForward(author)) {
		if(StrEqual(usernameColor[author], "G", false)) {
			Format(name, MAXLENGTH_NAME, "\x04%s", name);
		} else if(StrEqual(usernameColor[author], "O", false)) {
			Format(name, MAXLENGTH_NAME, "\x05%s", name);
		} else if(strlen(usernameColor[author]) == 6) {
			Format(name, MAXLENGTH_NAME, "\x07%s%s", usernameColor[author], name);
		} else if(strlen(usernameColor[author]) == 8) {
			Format(name, MAXLENGTH_NAME, "\x08%s%s", usernameColor[author], name);
		} else {
			Format(name, MAXLENGTH_NAME, "\x03%s", name); // team color by default!
		}
	} else {
		Format(name, MAXLENGTH_NAME, "\x03%s", name); // team color by default!
	}
	if(TagForward(author)) {
		if(strlen(tag[author]) > 0) {
			if(StrEqual(tagColor[author], "T", false)) {
				Format(name, MAXLENGTH_NAME, "\x03%s%s", tag[author], name);
			} else if(StrEqual(tagColor[author], "G", false)) {
				Format(name, MAXLENGTH_NAME, "\x04%s%s", tag[author], name);
			} else if(StrEqual(tagColor[author], "O", false)) {
				Format(name, MAXLENGTH_NAME, "\x05%s%s", tag[author], name);
			} else if(strlen(tagColor[author]) == 6) {
				Format(name, MAXLENGTH_NAME, "\x07%s%s%s", tagColor[author], tag[author], name);
			} else if(strlen(tagColor[author]) == 8) {
				Format(name, MAXLENGTH_NAME, "\x08%s%s%s", tagColor[author], tag[author], name);
			} else {
				Format(name, MAXLENGTH_NAME, "\x01%s%s", tag[author], name);
			}
		}
	}
	if(strlen(chatColor[author]) > 0 && ColorForward(author)) {
		new MaxMessageLength = MAXLENGTH_MESSAGE - strlen(name) - 5; // MAXLENGTH_MESSAGE = maximum characters in a chat message, including name. Subtract the characters in the name, and 5 to account for the colon, spaces, and null terminator
		if(StrEqual(chatColor[author], "T", false)) {
			Format(message, MaxMessageLength, "\x03%s", message);
		} else if(StrEqual(chatColor[author], "G", false)) {
			Format(message, MaxMessageLength, "\x04%s", message);
		} else if(StrEqual(chatColor[author], "O", false)) {
			Format(message, MaxMessageLength, "\x05%s", message);
		} else if(strlen(chatColor[author]) == 6) {
			Format(message, MaxMessageLength, "\x07%s%s", chatColor[author], message);
		} else if(strlen(chatColor[author]) == 8) {
			Format(message, MaxMessageLength, "\x08%s%s", chatColor[author], message);
		}
	}
	return Plugin_Changed;
}


bool:ColorForward(author) {
	new Action:result = Plugin_Continue;
	Call_StartForward(colorForward);
	Call_PushCell(author);
	Call_Finish(result);
	if(result == Plugin_Handled || result == Plugin_Stop) {
		return false;
	}
	return true;
}

bool:NameForward(author) {
	new Action:result = Plugin_Continue;
	Call_StartForward(nameForward);
	Call_PushCell(author);
	Call_Finish(result);
	if(result == Plugin_Handled || result == Plugin_Stop) {
		return false;
	}
	return true;
}

bool:TagForward(author) {
	new Action:result = Plugin_Continue;
	Call_StartForward(tagForward);
	Call_PushCell(author);
	Call_Finish(result);
	if(result == Plugin_Handled || result == Plugin_Stop) {
		return false;
	}
	return true;
}

SetTag(client, iPos)
{
	GetArrayString(sectionArray[iPos], 5, tag[client], sizeof(tag[]));
	new AdminId:admin = GetUserAdmin(client);
	if(GetConVarInt(ChangeClanTag) == 1 && IsClientInGame(client))
	{
		CS_SetClientClanTag(client, tag[client]);
	}
	if(!GetAdminFlag(admin, ColorsFlag) && !GetAdminFlag(admin, Admin_Kick))
	{
		iTagColor[client] = -1;
		iUsernameColor[client] = -1;
		iChatColor[client] = -1;
	}
	if(iTagColor[client] == -1)
	{
		GetArrayString(sectionArray[iPos], 6, tagColor[client], sizeof(tagColor[]));
	}
	else
	{
		GetArrayString(colorsArray[iTagColor[client]], 1, tagColor[client], sizeof(tagColor[]));
	}
	if(iUsernameColor[client] == -1)
	{
		GetArrayString(sectionArray[iPos], 7, usernameColor[client], sizeof(usernameColor[]));
	}
	else
	{
		GetArrayString(colorsArray[iUsernameColor[client]], 1, usernameColor[client], sizeof(usernameColor[]));
	}
	if(iChatColor[client] == -1)
	{
		GetArrayString(sectionArray[iPos], 8, chatColor[client], sizeof(chatColor[]));
	}
	else
	{
		GetArrayString(colorsArray[iChatColor[client]], 1, chatColor[client], sizeof(chatColor[]));
	}
	ReplaceString(tagColor[client], sizeof(tagColor[]), "#", "");
	ReplaceString(usernameColor[client], sizeof(usernameColor[]), "#", "");
	ReplaceString(chatColor[client], sizeof(chatColor[]), "#", "");
}

public T_ErrorHandle(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("[Custom-Chat] Query failure: %s", error);
	}
}

public bool:InGroup(client, steamgroup)
{
	if(groupStatus[client] != INVALID_HANDLE)
	{
		for(new i = 0; i < GetArraySize(groupStatus[client]); i++)
		{
			new _steamgroup;
			_steamgroup = GetArrayCell(groupStatus[client], i);
			if(_steamgroup == steamgroup)
			{
				return true;
			}
		}
	}
	return false;
}