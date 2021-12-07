/**
 * LISTEN.moe Player
 * 
 * A simple, standalone radio plugin that just loads an HTML page from the string table.
 * Type /listenmoe in chat to open LISTEN.moe in the background.
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdktools_stringtables>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
public Plugin myinfo = {
	name = "[ANY] LISTEN.moe Player (Unofficial)",
	author = "nosoop",
	description = "hot weeb tracks straight to your infopanel 24/7",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/"
}

#define INFO_PANEL_STRING "__listen_moe"
#define PENDING_STATE 0

static bool g_bListenState[MAXPLAYERS + 1];
static bool g_bListenUpdatingState[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegConsoleCmd("sm_listenmoe", ShowWeebPlayer);
	
	UserMsg vguiMessage = GetUserMessageId("VGUIMenu");
	
	if (vguiMessage == INVALID_MESSAGE_ID) {
		SetFailState("VGUIMenu is not supported in this game; can't show web pages.");
	}
	
	HookUserMessage(vguiMessage, OnVGUIMenuDisplayed, false, OnVGUIMenuPostNotify);
}

public void OnMapStart() {
	char buffer[] = "<audio autoplay src=\"https://listen.moe/stream\"></audio>";
	/*
	 rainwave: https://rainwave.cc/api4/stations
	*/
	
	SetInfoPanelData(INFO_PANEL_STRING, buffer);
}

public Action ShowWeebPlayer(int client, int argc) {
	static KeyValues playerKeyValues, blankKeyValues;
	
	if (!playerKeyValues) {
		playerKeyValues = new KeyValues("data", "title", "LISTEN.moe");
		
		playerKeyValues.SetNum("type", MOTDPANEL_TYPE_INDEX);
		playerKeyValues.SetString("msg", INFO_PANEL_STRING);
	}
	
	if (!blankKeyValues) {
		blankKeyValues = new KeyValues("data", "title", "blank");
		
		blankKeyValues.SetNum("type", MOTDPANEL_TYPE_URL);
		blankKeyValues.SetString("msg", "about:blank");
	}
	
	if (!g_bListenState[client]) {
		ShowVGUIPanel(client, "info", playerKeyValues, false);
		PrintToChat(client, "%s", "Tuned into LISTEN.moe.");
	} else {
		ShowVGUIPanel(client, "info", blankKeyValues, false);
		PrintToChat(client, "%s", "Closed LISTEN.moe.");
	}
	return Plugin_Handled;
}

/**
 * Determines if an info panel is being displayed to one or more clients and marks their
 * listening state as pending.
 */
public Action OnVGUIMenuDisplayed(UserMsg msg_id, Handle msg, const int[] players, int nPlayers,
		bool reliable, bool init) {
	char panelName[32];
	KeyValues info = ExtractVGUIPanelKeyValues(msg);
	
	info.GetSectionName(panelName, sizeof(panelName));
	if (StrEqual(panelName, "info")) {
		char vguiMsg[16];
		info.GetString("msg", vguiMsg, sizeof(vguiMsg));
		
		bool bIsWeebPlayer = info.GetNum("type") == MOTDPANEL_TYPE_INDEX
				&& StrEqual(vguiMsg, INFO_PANEL_STRING);
		
		/**
		 * mark all the players this menu is displayed to as pending an update
		 * only update the listening state if the message is actually sent in post hook
		 * MOTD messages are always shown even if they aren't (????)
		 */
		for (int i = 0; i < nPlayers; i++) {
			g_bListenUpdatingState[ players[i] ] = true;
		}
		
		// treat worldspawn listening state as the next non-pending state
		g_bListenState[PENDING_STATE] = bIsWeebPlayer;
	}
	delete info;
	
	return Plugin_Continue;
}

/**
 * Update listening state on pending clients if the message was not blocked.
 * Clear pending updating state on all clients.
 */
public void OnVGUIMenuPostNotify(UserMsg msg_id, bool sent) {
	for (int i = 1; i <= MaxClients; i++) {
		if (sent && g_bListenUpdatingState[i]) {
			g_bListenState[i] = g_bListenState[PENDING_STATE];
		}
		g_bListenUpdatingState[i] = false;
	}
}

/**
 * Writes a string into the info panel string table with the specified name, replacing it if
 * it already exists.
 */
stock void SetInfoPanelData(const char[] name, const char[] data) {
	static int s_iStringTableInfoPanel = INVALID_STRING_INDEX;
	
	if (s_iStringTableInfoPanel == INVALID_STRING_INDEX) {
		s_iStringTableInfoPanel = FindStringTable("InfoPanel");
	}
	
	int iInfoIdentifier = FindStringIndex(s_iStringTableInfoPanel, name);
	if (iInfoIdentifier == INVALID_STRING_INDEX) {
		AddToStringTable(s_iStringTableInfoPanel, name, data, strlen(data) + 1);
	} else {
		SetStringTableData(s_iStringTableInfoPanel, iInfoIdentifier, data, strlen(data) + 1);
	}
}

/**
 * Extracts the KeyValues from the given VGUIMenu usermessage buffer.
 * The panel name is set as the KeyValues' section name.
 */
stock KeyValues ExtractVGUIPanelKeyValues(Handle buffer, bool &show = false,
		int &nSubKeys = 0) {
	char panelName[128];
	
	KeyValues kv = new KeyValues("(missing panel name)");
	switch (GetUserMessageType()) {
		case UM_BitBuf: {
			BfRead bitbuf = UserMessageToBfRead(buffer);
			bitbuf.ReadString(panelName, sizeof(panelName));
			
			show = !!bitbuf.ReadByte();
			nSubKeys = bitbuf.ReadByte();
			
			kv.SetSectionName(panelName);
			for (int i = 0; i < nSubKeys; i++) {
				char key[192], value[192];
				
				bitbuf.ReadString(key, sizeof(key), false);
				bitbuf.ReadString(value, sizeof(value), false);
				
				kv.SetString(key, value);
			}
		}
		case UM_Protobuf: {
			Protobuf protobuf = UserMessageToProtobuf(buffer);
			protobuf.ReadString("name", panelName, sizeof(panelName));
			
			show = protobuf.ReadBool("show");
			nSubKeys = protobuf.GetRepeatedFieldCount("subkeys");
			
			kv.SetSectionName(panelName);
			for (int i = 0; i < nSubKeys; i++) {
				char key[192], value[192];
				
				Protobuf subkey = protobuf.ReadRepeatedMessage("subkeys", i);
				subkey.ReadString("name", key, sizeof(key));
				subkey.ReadString("str", value, sizeof(value));
				
				kv.SetString(key, value);
			}
		}
		default: {
			ThrowError("ExtractInfoPanelKeyValues does not support this usermessage type (%d)",
					GetUserMessageType());
		}
	}
	return kv;
}
