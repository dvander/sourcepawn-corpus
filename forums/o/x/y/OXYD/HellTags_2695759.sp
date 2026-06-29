/////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <multicolors>
/////////////////////////////////
#undef REQUIRE_PLUGIN
#include <chat-processor>
#define REQUIRE_PLUGIN
/////////////////////////////////
#pragma semicolon 1
#pragma newdecls required     
/////////////////////////////////
Handle h_cVarAdminOnly;
Handle h_cVarBannedTags;
Handle h_cVarAssignMessage;

ConVar h_cVarServerDNS;

Handle h_HTag = INVALID_HANDLE;
Handle h_HTagColor = INVALID_HANDLE;
Handle h_HBannedTags = INVALID_HANDLE;

char h_HBannedTagsFile[PLATFORM_MAX_PATH];
/////////////////////////////////
Handle SG_hTagCookies;

char h_CTag[100][256];
char h_CFlags[100][8];
char h_CType[100][32];
char h_CTagColors[100][32];
char h_CNameColors[100][32];
char h_CTextColors[100][32];
char h_CIDs[100][32];

int h_CTags = 0;
/////////////////////////////////
#define h_tFlag ADMFLAG_CUSTOM6
#define DEBUG
#define PLUGIN_AUTHOR "KENOXYD"
#define PLUGIN_VERSION "2.0"
/////////////////////////////////
char g_sColors[][] =
{
	"white",
	"red",
	"darkred",
	"lightred",
	"purple",
	"green",
	"lightgreen",
	"lime",
	"grey",
	"grey2",
	"grey3",
	"yellow",
	"lightblue",
	"blue",
	"pink",
	"orange",
	"team",
};

char g_sColorsHex[][] = 
{
	"\x01",
	"\x0F",
	"\x02",
	"\x07",
	"\x03",
	"\x04",
	"\x05",
	"\x06",
	"\x08",
	"\x0A",
	"\x0D",
	"\x09",
	"\x0B",
	"\x0C",
	"\x0E",
	"\x10",
	"",
};
/////////////////////////////////
public Plugin myinfo = 
{
	name = "HellTags",
	author = PLUGIN_AUTHOR,
	description = "Chat Tags Preferentials",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/kenoxyd"
};
/////////////////////////////////

public void OnPluginStart() { 
	//CVARS
	h_cVarAdminOnly = CreateConVar("helltags_adminonly", "1", "0 - Everyone can use the HellTags Commands, 1 - Only Admins can use the HellTags Commands");
	h_cVarServerDNS = CreateConVar("helltags_dns", "", "Server's DNS Required in Name. Leave this field blank to disable", FCVAR_NOTIFY);
	h_cVarBannedTags = CreateConVar("helltags_banned", "1", "0 - Players can use banned tags, 1 - Players can't use banned tags");
	h_cVarAssignMessage = CreateConVar("helltags_message", "1", "0 - Disabled, 1 - Player is announced when he sets his tag.");
	
	//ClientPrefs
	h_HTag = RegClientCookie("HellTag", "Tag-ul ales de jucator", CookieAccess_Protected);
	h_HTagColor = RegClientCookie("HellTagColor", "Culoarea pentru tag", CookieAccess_Protected);
	SG_hTagCookies = RegClientCookie("HellTag_SG", "A cookie for saving iClients's tags", CookieAccess_Private);
	
	//Commands
	RegConsoleCmd("sm_ctag", Command_TagMenu);
	RegConsoleCmd("sm_ctags", Command_TagMenu);
	RegConsoleCmd("sm_ctagmenu", Command_TagMenu);
	RegConsoleCmd("sm_tag", Command_UseTag);
	RegConsoleCmd("sm_tagcolor", Command_UseTagColor);
	RegConsoleCmd("sm_tcolor", Command_UseTagColor);
	RegConsoleCmd("sm_colors", Command_ColorList);
	RegConsoleCmd("sm_disabletag", Command_DisableTag);
	
	RegAdminCmd("sm_reloadtags", Command_ReloadTags, ADMFLAG_GENERIC);
	
	//Events
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEventEx("player_connect_full", Event_FullJoined);
	HookEvent("player_team", Event_CTagSet);
    
	//helltags.cfg
	AutoExecConfig(true, "helltags");
    
	LoadTagsFromFile();
}

public void OnAllPluginsLoaded()
{
    if(!LibraryExists("chat-processor"))
    {
        LogError("[HellTags] Chat Processor plugin not found! HellTags is disabled.");
    }
}

public void OnMapStart() { 
	BannedTags();
}

public Action Event_FullJoined(Event event, const char[] name, bool dontBroadcast) { 
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientConnected(iClient) && !IsFakeClient(iClient)) { 
		CreateTimer(0.5, GiveTagClient, iClient);
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) { 
	int ClientUserId = GetEventInt(event, "userid");
	int iClient = GetClientOfUserId(ClientUserId);
    
	char Tag[16];
	GetClientCookie(iClient, h_HTag, Tag, sizeof(Tag));
	
	if (strlen(Tag) > 0) { 
		CS_SetClientClanTag(iClient, Tag);
	}
	
	SetClientTag(iClient);
}

public Action Event_CTagSet(Handle event, const char[] name, bool dontBroadcast)
{
    int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
    SetClientTag(iClient);
}

public void OnClientPostAdminCheck(int iClient)
{
    if (AreClientCookiesCached(iClient))
    {
        SetClientTag(iClient);
    }
}

public void OnClientSettingsChanged(int iClient)
{
    if (AreClientCookiesCached(iClient))
    {
        SetClientTag(iClient);
    }
}

public Action Command_TagMenu(int iClient, int args)
{
	TagMenu(iClient);
	
	return Plugin_Handled;
}

public Action Command_ReloadTags(int iClient, int args)
{
    LoadTagsFromFile();
    CReplyToCommand(iClient, " \x07Chat+ » \x04HellTags Reloaded.");
    return Plugin_Handled;
}

public void TagMenu(int iClient)
{
    Handle menu = CreateMenu(MenuCallBack);
    SetMenuTitle(menu, "★ HELLTAGS MENU ★");
    
    char sDisableItem[128];
    Format(sDisableItem, sizeof(sDisableItem), "» Disable Tag");
    AddMenuItem(menu, "0", sDisableItem);
    
    for (int i = 0; i < h_CTags; i++)
    {
        char sInfo[300];
        Format(sInfo, sizeof(sInfo), "%s_,_%s", h_CType[i], h_CTag[i]);
        
        if (h_CFlags[i][0] == '\0')
        {
            if (h_CIDs[i][0] != '\0')
            {
                char hSteamID[32];
                GetClientAuthId(iClient, AuthId_Engine, hSteamID, sizeof(hSteamID));
                if (StrEqual(h_CIDs[i], hSteamID))
                    AddMenuItem(menu, sInfo, h_CTag[i]);
                else
                    AddMenuItem(menu, sInfo, h_CTag[i], ITEMDRAW_DISABLED);
            }
            else
                AddMenuItem(menu, sInfo, h_CTag[i]);
        }
        else
        {
            if (CheckCommandAccess(iClient, "", ReadFlagString(h_CFlags[i])))
            {
                AddMenuItem(menu, sInfo, h_CTag[i]);
            }
            else
                AddMenuItem(menu, sInfo, h_CTag[i], ITEMDRAW_DISABLED);
        }
    }
    
    DisplayMenu(menu, iClient, MENU_TIME_FOREVER);
}

public int MenuCallBack(Handle menu, MenuAction action, int iClient, int itemNum)
{
    if (action == MenuAction_Select)
    {
        char hItem[256], hSteamID[64];
        GetMenuItem(menu, itemNum, hItem, sizeof(hItem));
        GetClientAuthId(iClient, AuthId_Engine, hSteamID, sizeof(hSteamID));
        
        if (itemNum == 0)
        {
            CS_SetClientClanTag(iClient, "");
            SetAuthIdCookie(hSteamID, SG_hTagCookies, "");
            CPrintToChat(iClient, " \x07Chat+ » \x02Your Tag has been disabled.");
        }
        else
        {
            char hItems[2][256];
            ExplodeString(hItem, "_,_", hItems, 2, 256);
            
            if (StrEqual(hItems[0], "chat"))
            {
                SetAuthIdCookie(hSteamID, SG_hTagCookies, hItem);
                CPrintToChat(iClient, " \x07Chat+ » \x04Your NEW Chat Tag has been enabled.", hItems[1]);
            }
            else
            {
                CS_SetClientClanTag(iClient, hItems[1]);
                SetAuthIdCookie(hSteamID, SG_hTagCookies, hItem);
                CPrintToChat(iClient, " \x07Chat+ » \x04Your NEW Tag has been enabled", hItems[1]);
            }
        }
    }
    else if (action == MenuAction_End)CloseHandle(menu);
}

public Action Command_UseTag(int iClient, int args) { 
	char DNSbuffer[32];
	h_cVarServerDNS.GetString(DNSbuffer, sizeof(DNSbuffer));
    
	if (GetConVarInt(h_cVarAdminOnly) > 0 || ServerDNS(iClient) == false) { 
		if (!CheckCommandAccess(iClient, "sm_someoverride", h_tFlag) || ServerDNS(iClient) == false) { 
			PrintToChat(iClient, " \x07Chat+ » \x01\x02 You don't have acces to this command or you don't have \x10Gold Member®\x01!");
			return Plugin_Handled;
		}
	}
	
	char ChoosenTag[32];
	GetCmdArgString(ChoosenTag, sizeof(ChoosenTag));
	
	if (args < 1) { 
		PrintToChat(iClient, " \x07Chat+ » \x01\x04 Usage:\x02 !tag\x01 <yourtag>");
		return Plugin_Handled;
	}
	
	if (strlen(ChoosenTag) > 15) { 
		PrintToChat(iClient, " \x07Chat+ » \x01\x02 Tag is too long!");
		return Plugin_Handled;
	}
	
	if (GetConVarInt(h_cVarBannedTags) > 0) { 
		char hBannedTags[1024];
		
		for (int i = 0; i < GetArraySize(h_HBannedTags); i++) { 
			GetArrayString(h_HBannedTags, i, hBannedTags, sizeof(hBannedTags));
			
			if (StrContains(ChoosenTag, hBannedTags) != -1) { 
				PrintToChat(iClient, " \x07Chat+ » \x01\x02 Your tag is restricted from using!");
				return Plugin_Handled;
			}
		}
	}
	
	CS_SetClientClanTag(iClient, ChoosenTag);
	SetClientCookie(iClient, h_HTag, ChoosenTag);
	
	if (GetConVarInt(h_cVarAssignMessage) > 0) { 
		PrintToChat(iClient, " \x07Chat+ » \x01\x09 Your tag has been assigned");
		PrintToChat(iClient, " \x07Chat+ » \x01\x09 Your new tag is\x04 %s", ChoosenTag);
	}
	
	return Plugin_Continue;
}

public Action Command_UseTagColor(int iClient, int args) 
{ 
	if (args < 1) { 
		PrintToChat(iClient, " \x07Chat+ » \x01\x04 Usage:\x02 !tagcolor\x01 <color>\x04 - Use \x02 !colors\x01 for colors list.");
		return Plugin_Handled;
	}
	
	char sColor[32];
	GetCmdArg(1, sColor, sizeof(sColor));
	
	bool colorExists = false;
	int sChoosenColor;
	for (int i = 0; i < 17; i++)
	{
		if (StrEqual(sColor, g_sColors[i]))
		{
			sChoosenColor = i;
			colorExists = true;
		}
	}
	if (!colorExists)
	{
		PrintToChat(iClient, " \x07Chat+ » \x02That color doesn't exist!");
		PrintToChat(iClient, " \x07Chat+ » \x01 \x04Use !colors");
		return Plugin_Handled;
	}

	SetClientCookie(iClient, h_HTagColor, g_sColorsHex[sChoosenColor]);
        PrintToChat(iClient, "\x01 \x04Your tag color is now \"%s%s\x04\".", g_sColorsHex[sChoosenColor], g_sColors[sChoosenColor]);
	return Plugin_Continue;
}

public Action Command_ColorList(int iClient, int args) { 
	PrintToChat(iClient, " \x07Chat+ » \x01\x01 Available colors are:");
	PrintToChat(iClient, "white, \x07red \x02darkred, \x0Flightred \x03purple, \x04green, \x05lightgreen, \x06lime, \x08grey, \x0Agrey2, \x0Dgrey3 \x09yellow, \x0Blightblue, \x0Cblue, \x0Epink, \x10orange, \x01team");
}

public Action CP_OnChatMessage(int & iClient, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool & processcolors, bool & removecolors) { 
	
	if(MaxClients >= iClient > 0)
    {
        if(message[0] == '/' || message[0] == '@')
        {
            return Plugin_Continue;
        }
        
        char sCookie[300];
        GetClientCookie(iClient, SG_hTagCookies, sCookie, sizeof(sCookie));
        
        if (sCookie[0] == '\0')
            return Plugin_Continue;
        
        char sCookies[2][256];
        ExplodeString(sCookie, "_,_", sCookies, 2, 256);
        
        if (StrEqual(sCookies[0], "tag"))
            return Plugin_Continue;
        
        char sTagColor[32], sNameColor[32], sTextColor[32];
        FindTagColors(sCookies[1], sTagColor, sNameColor, sTextColor);
        
        Format(message, MAXLENGTH_MESSAGE, "%s%s", sTextColor, message);
        Format(name, MAXLENGTH_NAME, "%s%s %s%s", sTagColor, sCookies[1], sNameColor, name);
        
        return Plugin_Changed;
    }
	
	if (GetConVarInt(h_cVarAdminOnly) > 0) { 
		if (!CheckCommandAccess(iClient, "sm_someoverride", h_tFlag)) { 
			return Plugin_Continue;
		}
	}
	
	char Tag[32];
	GetClientCookie(iClient, h_HTag, Tag, sizeof(Tag));
	
	char Color[32];
	GetClientCookie(iClient, h_HTagColor, Color, sizeof(Color));
	
	if (StrEqual(Tag, "")) { 
		return Plugin_Continue;
	}
	
	if (strlen(Color) > 0) { 
		switch (GetClientTeam(iClient)) { 
			case CS_TEAM_NONE: {
				Format(name, MAXLENGTH_NAME, " %s%s\x01 %s", Color, Tag, name);
			}
			case CS_TEAM_SPECTATOR: {
				Format(name, MAXLENGTH_NAME, " %s%s\x01 %s", Color, Tag, name);
			}
			case CS_TEAM_T: {
				Format(name, MAXLENGTH_NAME, " %s%s\x09 %s", Color, Tag, name); 
			}
			case CS_TEAM_CT: {
				Format(name, MAXLENGTH_NAME, " %s%s\x0B %s", Color, Tag, name);
			}
		}
	}
	else {
		Format(name, MAXLENGTH_NAME, "%s %s", Tag, name);
	}
	
	Format(message, MAXLENGTH_MESSAGE, "%s", message);
	
	return Plugin_Continue;
}

public void LoadTagsFromFile()
{
    Handle kv = CreateKeyValues("HellTags");
    if (FileToKeyValues(kv, "addons/sourcemod/configs/helltags.cfg") && KvGotoFirstSubKey(kv))
    {
        h_CTags = 0;
        do
        {
			KvGetString(kv, "steamid", h_CIDs[h_CTags], 32);
			KvGetString(kv, "flag", h_CFlags[h_CTags], 8);
			KvGetString(kv, "ctag", h_CTag[h_CTags], 256);
			KvGetString(kv, "tag-color", h_CTagColors[h_CTags], 32, "{default}");
			KvGetString(kv, "name-color", h_CNameColors[h_CTags], 32, "{teamcolor}");
			KvGetString(kv, "text-color", h_CTextColors[h_CTags], 32, "{default}");
			KvGetString(kv, "type", h_CType[h_CTags], 32, "htag");
			h_CTags++;
		} while (KvGotoNextKey(kv));
    }
    else
    {
        SetFailState("[HellTags] Error in parsing file helltags.cfg.");
    }
    CloseHandle(kv);
}

public Action Command_DisableTag(int iClient, int args) { 
	if (IsClientInGame(iClient) && iClient > 0 && iClient <= MaxClients) { 
		SetClientCookie(iClient, h_HTag, "");
		CS_SetClientClanTag(iClient, "");
		
		if (GetConVarInt(h_cVarAssignMessage) > 0) { 
			PrintToChat(iClient, " \x07Chat+ » \x01\x02 Your tag has been disabled!");
		}
	}
}

public Action GiveTagClient(Handle timer, any iClient) { 
	if (IsClientInGame(iClient) && iClient > 0 && iClient <= MaxClients) { 
		char Tag[32];
		GetClientCookie(iClient, h_HTag, Tag, sizeof(Tag));
		
		if (strlen(Tag) > 0) { 
			if (GetConVarInt(h_cVarBannedTags) > 0) { 
				char TagsFromFile[1024];
				
				for (int i = 0; i < GetArraySize(h_HBannedTags); i++) { 
					GetArrayString(h_HBannedTags, i, TagsFromFile, sizeof(TagsFromFile));
					
					if (StrContains(Tag, TagsFromFile) != -1) { 
						SetClientCookie(iClient, h_HTag, ""); 
						
						if (GetConVarInt(h_cVarAssignMessage) > 0) { 
							PrintToChat(iClient, " \x07Chat+ » \x01\x02 Your tag is forbidden and it has been deleted!");
						}
					}
					else {
						CS_SetClientClanTag(iClient, Tag);
					}
				}
			}
			else {
				CS_SetClientClanTag(iClient, Tag);
			}
		}
	}
}

bool ServerDNS(int iClient)
{
    char Name[32], buffer[32];
    h_cVarServerDNS.GetString(buffer, sizeof(buffer));
    GetClientName(iClient, Name, sizeof(Name));

    if(StrContains(Name, buffer, false) > -1)
        return true;
    else
        return false;
}

public void BannedTags() { 
	h_HBannedTags = CreateArray(1024);
	
	BuildPath(Path_SM, h_HBannedTagsFile, sizeof(h_HBannedTagsFile), "configs/banned_tags.txt");
	Handle h_HBannedTagsHolder = OpenFile(h_HBannedTagsFile, "r");
	
	char ResultsBuffer[1024];
	
	while (!IsEndOfFile(h_HBannedTagsHolder) && ReadFileLine(h_HBannedTagsHolder, ResultsBuffer, sizeof(ResultsBuffer))) { 
		ReplaceString(ResultsBuffer, sizeof(ResultsBuffer), "\n", "", false);
		PushArrayString(h_HBannedTags, ResultsBuffer);
	}
}

public void SetClientTag(int iClient)
{
    if (iClient < 1 || iClient > MaxClients || !IsClientConnected(iClient) || IsFakeClient(iClient))
        return;
    
    char sCookie[256];
    GetClientCookie(iClient, SG_hTagCookies, sCookie, sizeof(sCookie));
    
    if (sCookie[0] == '\0')
        return;
    
    char sCookies[2][256];
    ExplodeString(sCookie, "_,_", sCookies, 2, 256);
    
    if (!StrEqual(sCookies[0], "ctag"))
    {
        char sPlayerTag[64];
        CS_GetClientClanTag(iClient, sPlayerTag, sizeof(sPlayerTag));
        if (!StrEqual(sPlayerTag, sCookies[1]))
        {
            CS_SetClientClanTag(iClient, sCookies[1]);
        }
    }
}

public void FindTagColors(char[] sTag, char[] sTagColor, char[] sNameColor, char[] sTextColor)
{
    for (int i = 0; i < h_CTags; i++)
    {
        if (StrEqual(h_CTag[i], sTag))
        {
            strcopy(sTagColor, 32, h_CTagColors[i]);
            strcopy(sNameColor, 32, h_CNameColors[i]);
            strcopy(sTextColor, 32, h_CTextColors[i]);
            break;
        }
    }
}  