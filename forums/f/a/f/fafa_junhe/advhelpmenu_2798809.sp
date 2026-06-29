#pragma semicolon 1

#include <sourcemod>
#include <json>
#include <menus>
#define PLUGIN_VERSION "0.1"
#define MAX_READ_BYTE 8192
Handle g_hConfigFile;
Handle g_cConfigFilePath;
Handle g_hMenuLists[20];
int g_hParent[20];
char shortcuts[20][10][10];
Handle g_hMapList;
int g_iAdminFlags[20];
char g_sMaplistName[32];
public Plugin infos =
{
	name = "Advanced Help Menu",
	author = "fafa_junhe",
	description = "Display a help menu.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

enum SectionType
{
	Type_Menu,
	Type_MapList,
	Type_Text,
	Type_Motd,
	Type_Error
}

bool StringToBool(char[] buffer){
	return StrEqual(buffer, "true") ? true : false;
}

stock SectionType GetMenuType(JSON_Object obj){
	char type[64];
	obj.GetString("type", type, sizeof(type));
	if (StrEqual(type, "menu")){
		return Type_Menu;
	}
	else if (StrEqual(type, "text")) {
		return Type_Text;
	}
	else if (StrEqual(type, "maplist")) {
		return Type_MapList;
	}
	else if (StrEqual(type, "motd")){
		return Type_Motd;
	}
	return Type_Error;
}
void SetupMaplist(){
	g_hMapList = CreateMenu(Menu_Handle, MENU_ACTIONS_DEFAULT);
	Handle mapArray = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	ReadMapList(mapArray);
	if (g_sMaplistName[0] != '\0')
		SetMenuTitle(g_hMapList, g_sMaplistName);
	else
		SetMenuTitle(g_hMapList, "maplist");
	
	SetMenuExitButton(g_hMapList, true);
	if (mapArray != INVALID_HANDLE){		
		char mapname[64];
		for (new i = 0; i < GetArraySize(mapArray); ++i) {
			GetArrayString(mapArray, i, mapname, sizeof(mapname));
			char buffer[64];
			Format(buffer, sizeof(buffer), "say %s", mapname);
			AddMenuItem(g_hMapList, buffer, mapname);
		}
		
	}
	else{
		AddMenuItem(g_hMapList, "", "Error on getting maplist", ITEMDRAW_DISABLED);
	}

}
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	for (int i = 0; i < 10; i++){
		if(shortcuts[i][0][0] == '\0'){
			continue;
		}
		for (int j = 0; j < 10; j++){
			if(shortcuts[i][j][0] == '\0'){
				continue;
			}
			if(StrEqual(sArgs, shortcuts[i][j]))	{
				MenuShow(client, i);
				if(strstarts(sArgs, "/")){
					return Plugin_Handled;
				}
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}


void  MenuShow(int client, int indexs){
	PrintToServer("show menu %i to %N ", indexs, client);
	if(g_iAdminFlags[indexs] != 0){
		if (GetUserFlagBits(client) & g_iAdminFlags[indexs] == g_iAdminFlags[indexs]){
			DisplayMenu(g_hMenuLists[indexs], client, MENU_TIME_FOREVER);
			return;
		}
		PrintToChat(client, "%t", "No Access");
		return;
	}
	DisplayMenu(g_hMenuLists[indexs], client, MENU_TIME_FOREVER);
	return;
}

bool strstarts(const char[] str, const char[] prefix)
{
     return strncmp(str, prefix, strlen(prefix)) == 0;
}

public Menu_Handle(Handle:main, MenuAction:action, client, param2) {
	switch (action) {
		case MenuAction_Select: {
			char info[256];
			GetMenuItem(main, param2, info, sizeof(info));
			if(strstarts(info,"menuopen")){
				ReplaceString(info, 32, "menuopen", "");
				MenuShow(client, StringToInt(info));
			}
			else if(strstarts(info, "maplistopen")){ 
				DisplayMenu(g_hMapList, client, MENU_TIME_FOREVER);
			}
			else if(strstarts(info, "motdopen")){
				ReplaceString(info, 32, "motdopen", "");
				Handle setup = CreateKeyValues("data");
				KvSetString(setup, "title", "Musicspam");
				KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
				KvSetNum(setup, "customsvr", 1);
				KvSetString(setup, "msg", info);
	
				ShowVGUIPanel(client, "info", setup, true);
				CloseHandle(setup);

			}
			else{
				FakeClientCommand(client, info);
			}
		}
	   case MenuAction_Cancel: {
            switch (param2)
            {
                case MenuCancel_ExitBack:
                {
                	for(int i = 0; i < 20; i++){
                		if (g_hMenuLists[i] == main && i > 0){
                			if (g_hParent[i] != -1){
                			}
                			MenuShow(client, g_hParent[i]);
                			return;
                		}
                	}
                }
            }
        }
	}
	return;

}
void GetSection(JSON_Object obj, const char name[64] = {'\0'}, int indexs = 0, int parent = -1){
	PrintToServer("Parse %s", name, indexs, parent);
	int k = 0;
	g_hMenuLists[indexs] = CreateMenu(Menu_Handle, MENU_ACTIONS_DEFAULT);
	SetMenuTitle(g_hMenuLists[indexs], name);
	if (parent != -1){
		g_hParent[indexs] = parent;
		SetMenuExitBackButton(g_hMenuLists[indexs], true);
	}
	
	char buffer[5];
	obj.GetString("exit", buffer, sizeof(buffer));
	if (!StringToBool(buffer)){
		SetMenuExitButton(g_hMenuLists[indexs], false);
	}
	if (obj.HasKey("shortcut")){ // shortcut
		char buffer2[64];
		obj.GetString("shortcut", buffer2, sizeof(buffer2));
		ExplodeString(buffer2, "|", shortcuts[indexs], 10, 10);
	}
	if (obj.HasKey("flags")){
		char buffer5[10];
		obj.GetString("flags",buffer5, sizeof(buffer5));
		g_iAdminFlags[indexs] = ReadFlagString(buffer5);
	}
	JSON_Array data = view_as<JSON_Array>(obj.GetObject("data"));
	if (data == null){
		LogError("%s Menu but no data", name);
	}
	int len = data.Length;
	for (int i = 0; i < len; i++){
		JSON_Object tmp = data.GetObject(i);
		char keyName[64];
		tmp.Iterate();
		tmp.GetKey(0, keyName, 64);
		JSON_Object subObj = tmp.GetObject(keyName);
		
		
		if (subObj == null){
			continue;
		}
		switch (GetMenuType(subObj))
		{
			case Type_Menu:
			{
				while (g_hMenuLists[indexs + k] != INVALID_HANDLE)
				{
					k++;
				}
				GetSection(subObj, keyName, indexs + k, indexs);
				char buffer4[64];
				Format(buffer4, sizeof(buffer4), "menuopen%i", indexs + k);
				AddMenuItem(g_hMenuLists[indexs], buffer4, keyName);
				k++;
			}
			case Type_MapList:
			{
				AddMenuItem(g_hMenuLists[indexs], "maplistopen", keyName);
			}
			case Type_Text:
			{
				if (subObj.HasKey("cmd")){
					char buffer3[64];
					subObj.GetString("cmd", buffer3, sizeof(buffer3));
					AddMenuItem(g_hMenuLists[indexs], buffer3, keyName);
				}
				else{
					AddMenuItem(g_hMenuLists[indexs], "", keyName, ITEMDRAW_DISABLED);
				}
			}
			case Type_Motd:
			{
				if (subObj.HasKey("url")){
					char buffer6[256];
					subObj.GetString("url", buffer6, sizeof(buffer6));
					char buffer7[256];
					Format(buffer7, sizeof(buffer7), "motdopen%s", buffer6);
					AddMenuItem(g_hMenuLists[indexs], buffer7, keyName);
				}
				else{
					LogError("%s Motd but without url", keyName);
				}
			}
			case Type_Error:
			{
				LogError("%s Error Type!", keyName);
			}
		}


	}

}
public void SetupConfig(){

	char path[PLATFORM_MAX_PATH];
	char buffer2[100];
	GetConVarString(g_cConfigFilePath, buffer2, 100);
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, buffer2);
	g_hConfigFile = OpenFile(path, "r");
	char text[MAX_READ_BYTE];
	ReadFileString(g_hConfigFile, text, sizeof(text));
	JSON_Object obj = view_as<JSON_Object>(json_decode(text));
	int k = 0;
	JSON_Array arr = view_as<JSON_Array>(obj.GetObject("advhelpmenu"));
	int len = arr.Length;
	
	if (obj.HasKey("maplist_name")){
		char buffer[32];
		obj.GetString("maplist_name", buffer, sizeof(buffer));
		strcopy(g_sMaplistName, sizeof(g_sMaplistName), buffer);
	}
	
	for (int i = 0; i < len; i++){
		
		JSON_Object subObj = arr.GetObject(i);
		char keyName[64];
		
		subObj.Iterate();
		subObj.GetKey(0, keyName, 64);
		JSON_Object menu = subObj.GetObject(keyName);
		if (GetMenuType(menu) == Type_Menu){
			while (g_hMenuLists[k] != INVALID_HANDLE)
			{
				k++;
			}
			GetSection(menu, keyName, k);
		}
	}
	json_cleanup_and_delete(obj);
	


	SetupMaplist();

}
public Action ReloadMenu(int client, int args){
	ServerCommand("sm plugins reload advhelpmenu");
	return Plugin_Handled;
	// TODO:put real reload stuff
}
public void OnPluginStart(){
	g_cConfigFilePath = CreateConVar("advh_config", "configs/advhelpmenu.json", "config file path");
	RegAdminCmd("sm_advhr", ReloadMenu, ADMFLAG_KICK);
	SetupConfig();
}
