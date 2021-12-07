/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdktools_stringtables>

#pragma newdecls required

#define POPUP_FULL_SIZE 0

public void OnPluginStart() {
	RegAdminCmd("sm_openpage", AdminCmd_OpenPage, ADMFLAG_ROOT);
	RegAdminCmd("sm_openpopup", AdminCmd_OpenPage, ADMFLAG_ROOT);
	RegAdminCmd("sm_openhidden", AdminCmd_OpenPage, ADMFLAG_ROOT);
	RegAdminCmd("sm_openstringpage", AdminCmd_OpenPage, ADMFLAG_ROOT);
	RegAdminCmd("sm_showstandalonepopup", AdminCmd_OpenPage, ADMFLAG_ROOT);
	RegAdminCmd("sm_showstandalonepage", AdminCmd_OpenPage, ADMFLAG_ROOT);
}

public Action AdminCmd_OpenPage(int client, int argc) {
	char command[64];
	GetCmdArg(0, command, sizeof(command));
	
	char url[PLATFORM_MAX_PATH];
	GetCmdArgString(url, sizeof(url));
	
	StripQuotes(url);
	
	if (StrEqual(command, "sm_openpage")) {
		TF2_ShowMOTDPanel(client, "blah", url, true, true);
	} else if (StrEqual(command, "sm_openpopup")) {
		ShowMOTDPopupPanel(client, "blah", url);
	} else if (StrEqual(command, "sm_openhidden")) {
		ShowMOTDHiddenPanel(client, url);
	} else if (StrEqual(command, "sm_openstringpage")) {
		ShowMOTDFromStringTable(client, url);
	} else if (StrEqual(command, "sm_showstandalonepopup")) {
		ShowMOTDPopupStandalone(client, url);
	} else if (StrEqual(command, "sm_showstandalonepage")) {
		ShowMOTDPopupRedirect(client, url);
	}
	
	return Plugin_Handled;
}

/**
 * Displays an MOTD panel with TF2-specific options
 */
stock void TF2_ShowMOTDPanel(int client, const char[] title, const char[] url, bool show = true,
		bool big = false) {
	KeyValues kv = new KeyValues("data");
	
	kv.SetString("title", title);
	kv.SetNum("type", MOTDPANEL_TYPE_URL);
	kv.SetString("msg", url);
	
	if (big) {
		// kv.SetNum("customsvr", 1);
	}
	
	ShowVGUIPanel(client, "info", kv, show);
	
	delete kv;
}

/**
 * Displays a popup web panel.
 */
stock void ShowMOTDPopupPanel(int client, const char[] title, const char[] url,
		int width = POPUP_FULL_SIZE, int height = POPUP_FULL_SIZE) {
	KeyValues kv = new KeyValues("data");
	
	kv.SetString("title", title);
	kv.SetNum("type", MOTDPANEL_TYPE_URL);
	kv.SetString("msg", url);
	
	// kv for TF2 for hidden motd panel to get screen width/height
	kv.SetNum("customsvr", 1);
	
	kv.SetNum("x-vgui-popup", true);
	
	if (width || height) {
		kv.SetNum("x-vgui-width", width);
		kv.SetNum("x-vgui-height", height);
	}
	
	ShowVGUIPanel(client, "info", kv, true);
	
	delete kv;
}

stock void ShowMOTDHiddenPanel(int client, const char[] url) {
	KeyValues kv = new KeyValues("data");
	
	kv.SetString("title", "sample text");
	kv.SetNum("type", MOTDPANEL_TYPE_URL);
	kv.SetString("msg", url);
	
	ShowVGUIPanel(client, "info", kv, false);
	
	delete kv;
}

/**
 * Abuses the info stringtable to open a panel.
 */
stock void ShowMOTDPopupRedirect(int client, const char[] url) {
	char buffer[1024] = "<script>setTimeout(window.location.replace, 500, '{URL}')</script>";
	
	ReplaceString(buffer, sizeof(buffer), "{URL}", url);
	
	ShowMOTDFromStringTable(client, buffer, true);
}


/**
 * Abuses the info stringtable to open a panel.
 */
stock void ShowMOTDPopupStandalone(int client, const char[] url, int width = 0, int height = 0) {
	char buffer[1024] = "<script>window.open('{URL}', '_blank', `width={WIDTH},height={HEIGHT}`)</script>";
	
	char widthString[32] = "${screen.width}", heightString[32] = "${screen.height}";
	if (width) {
		IntToString(width, widthString, sizeof(widthString));
	}
	if (height) {
		IntToString(height, heightString, sizeof(heightString));
	}
	
	ReplaceString(buffer, sizeof(buffer), "{WIDTH}", widthString);
	ReplaceString(buffer, sizeof(buffer), "{HEIGHT}", heightString);
	
	ReplaceString(buffer, sizeof(buffer), "{URL}", url);
	
	ShowMOTDFromStringTable(client, buffer, false);
}

/**
 * Displays HTML content from a string table to the client.
 */
void ShowMOTDFromStringTable(int client, const char[] html, bool show = true) {
	static int s_iStringTableInfoPanel = INVALID_STRING_INDEX;
	
	if (s_iStringTableInfoPanel == INVALID_STRING_INDEX) {
		s_iStringTableInfoPanel = FindStringTable("InfoPanel");
	}
	
	char infoIdentifier[64];
	Format(infoIdentifier, sizeof(infoIdentifier), "__info_html_%d", client);
	
	int iInfoIdentifier = FindStringIndex(s_iStringTableInfoPanel, infoIdentifier);
	
	if (iInfoIdentifier == INVALID_STRING_INDEX) {
		AddToStringTable(s_iStringTableInfoPanel, infoIdentifier, html, strlen(html) + 1);
	} else {
		SetStringTableData(s_iStringTableInfoPanel, iInfoIdentifier, html, strlen(html) + 1);
	}
	
	float flSyncDelay = GetClientAvgLatency(client, NetFlow_Outgoing);
	
	DataPack callbackData;
	CreateDataTimer(flSyncDelay * 2.0, OnMOTDStringTableReplicated, callbackData,
			TIMER_FLAG_NO_MAPCHANGE);
	
	callbackData.WriteCell(GetClientUserId(client));
	callbackData.WriteCell(show);
}

// <script>window.open('https://google.com/', '_blank', `width=${screen.width},height=${screen.height}`)</script>
public Action OnMOTDStringTableReplicated(Handle timer, DataPack callbackData) {
	callbackData.Reset();
	int client = GetClientOfUserId(callbackData.ReadCell());
	bool show = callbackData.ReadCell();
	
	if (client) {
		KeyValues kv = new KeyValues("data");
		
		char infoIdentifier[64];
		Format(infoIdentifier, sizeof(infoIdentifier), "__info_html_%d", client);
		
		kv.SetString("title", "Counter-Strike: This is Offensive");
		kv.SetNum("type", MOTDPANEL_TYPE_INDEX);
		kv.SetString("msg", infoIdentifier);
		// kv.SetNum("cmd", 1);
		kv.SetNum("customsvr", 1);
		
		ShowVGUIPanel(client, "info", kv, show);
		
		delete kv;
	}
	return Plugin_Handled;
}
