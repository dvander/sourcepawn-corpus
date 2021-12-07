/**
 * [ANY?] VGUI URL Cache Buster
 * 
 * Steam's web controls (using CEF) has issues where attempting to navigate to a page on the
 * same domain as a previously loaded page fails to work.
 * 
 * This plugin hooks into the VGUIMenu user message and performs some questionable magic to try
 * and work around the issue.
 * 
 * The plugin is mainly tested on TF2 and has been tested on Empires, though it may work on
 * other games.  Any games using protobufs for their user messages are currently *not*
 * supported, such as CS:GO.
 */
#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#define PLUGIN_VERSION "1.0.2"
public Plugin myinfo = {
	name = "[ANY?] VGUI URL Cache Buster - Protobuf",
	author = "nosoop",
	description = "VGUIMenu fix for same-domain pages, enterprise edition.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-VGUICacheBuster"
}

/**
 * URL to a non-routable address.  We could use an invalid domain name, but we're at the mercy
 * of delays in DNS resolving if we go that route.  This should be much faster.
 * 
 * See: https://en.wikipedia.org/wiki/0.0.0.0
 */
#define INVALID_PAGE_URL "http://0.0.0.0/"

/**
 * URL to a copy of the MOTD frame proxy page.  It can be any valid HTTP / HTTPS URL with paths.
 * Don't include the hash character here; that's done during `OnVGUIMenuPreSent`.
 * 
 * It's preferred that it points to a second-level domain name that you're not using for your
 * MOTD, as MOTDs aren't automatically redirected (though you could modify your `motdfile` to
 * run through the MOTD proxy URL.
 * 
 * You don't have to change this, but leaving it as is means you have to trust that I keep the
 * page up (which has no guarantee) and don't modify the source to do anything malicious.
 * 
 * You can also configure the proxy page using the ConVar `vgui_workaround_proxy_page` instead.
 */
#define MOTD_PROXY_URL "http://motdproxy.us.to/"

/**
 * Path to the config file.
 */
#define PLUGIN_CONFIG_FILE "configs/vgui_cache_buster_urls.cfg"

#define MAX_BYPASS_METHOD_LENGTH 32

enum BypassMethod {
	Bypass_None, // passthrough -- don't manipulate the usermsg
	Bypass_Proxy, // use MOTD proxy page
	Bypass_DelayedLoad, // use timer and invalid page url
};

KeyValues g_URLConfig;
ConVar g_ProxyURL, g_PageDelay;

public void OnPluginStart() {
	char configPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configPath, sizeof(configPath), "%s", PLUGIN_CONFIG_FILE);
	
	g_URLConfig = new KeyValues("URLConfig");
	g_URLConfig.ImportFromFile(configPath);
	
	g_ProxyURL = CreateConVar("vgui_workaround_proxy_page", MOTD_PROXY_URL,
			"The URL to a static iframe page to proxy requests to.");
	
	g_PageDelay = CreateConVar("vgui_workaround_delay_time", "0.5",
			"Amount of time (in seconds) to delay a page load.", _,
			true, 0.0);
	
	AutoExecConfig(true);
	
	UserMsg vguiMessage = GetUserMessageId("VGUIMenu");
	HookUserMessage(vguiMessage, OnVGUIMenuPreSent, true);
}

/**
 * Intercepts VGUIMenu messages, including ones created by ShowMOTDPanel and variants.
 */
public Action OnVGUIMenuPreSent(UserMsg vguiMessage, Protobuf msg, const int[] players,
		int nPlayers, bool reliable, bool init) {
	// implementation based on CHalfLife2::ShowVGUIMenu in sourcemod/core/HalfLife2.cpp
	char name[128];
	msg.ReadString("name" , name, sizeof(name));
	
	if (StrEqual(name, "info")) {
		DataPack dataBuffer = new DataPack();
		
		// pack count of players and player list by userid
		dataBuffer.WriteCell(nPlayers);
		for (int i = 0; i < nPlayers; i++) {
			dataBuffer.WriteCell(GetClientUserId(players[i]));
		}
		
		int flags = (reliable? USERMSG_RELIABLE : 0) | (init? USERMSG_INITMSG : 0);
		dataBuffer.WriteCell(flags);
		
		dataBuffer.WriteCell(msg.ReadBool("show")); // bool bShow
		
		int count = msg.GetRepeatedFieldCount("subkeys");
		dataBuffer.WriteCell(count);
		
		// determines if the usermessage is for a web page that needs bypassing
		// (key "msg", value /^http/)
		BypassMethod pageBypass = Bypass_None; 
		
		// count is for key-value pairs
		for (int i = 0; i < count; i++) {
			char key[256], value[1024];
			Protobuf subkey = msg.ReadRepeatedMessage("subkeys", i);
			
			subkey.ReadString("name", key, sizeof(name));
			dataBuffer.WriteString(key);
			
			subkey.ReadString("str", value, sizeof(value));
			
			if (StrEqual(key, "msg") && StrContains(value, "http") == 0
					&& !StrEqual(value, INVALID_PAGE_URL)) {
				pageBypass = GetBypassMethodForURL(value);
				
				if (pageBypass == Bypass_Proxy) {
					char newURL[1024];
					g_ProxyURL.GetString(newURL, sizeof(newURL));
					
					StrCat(newURL, sizeof(newURL), "#");
					StrCat(newURL, sizeof(newURL), value);
					dataBuffer.WriteString(newURL);
				} else {
					// either delayed send or passthrough, so just copy value back
					dataBuffer.WriteString(value);
				}
			} else {
				dataBuffer.WriteString(value);
			}
		}
		
		switch (pageBypass) {
			case Bypass_Proxy: {
				RequestFrame(SendDataPackVGUI, dataBuffer);
				return Plugin_Handled;
			}
			case Bypass_DelayedLoad: {
				// thanks to boomix for this particular workaround method
				RequestFrame(DelayedSendDataPackVGUI_Pre, dataBuffer);
				return Plugin_Handled;
			}
			default: {
				delete dataBuffer;
			}
		}
	}
	return Plugin_Continue;
}

public void DelayedSendDataPackVGUI_Pre(DataPack dataBuffer) {
	dataBuffer.Reset();
	
	// unpack userids
	int nPackedPlayers = dataBuffer.ReadCell(), nPlayers;
	int[] players = new int[nPackedPlayers];
	for (int i = 0; i < nPackedPlayers; i++) {
		int recipient = GetClientOfUserId(dataBuffer.ReadCell());
		
		if (recipient) {
			players[nPlayers++] = recipient;
		}
	}
	
	if (nPlayers) {
		DisplayHiddenInvalidMOTD(players, nPlayers);
		
		// RequestFrame(SendDataPackVGUI, dataBuffer);
		CreateTimer(g_PageDelay.FloatValue, DelayedSendDataPackVGUI, dataBuffer);
	} else {
		// no players to transmit to
		delete dataBuffer;
	}
}

public Action DelayedSendDataPackVGUI(Handle timer, DataPack dataBuffer) {
	SendDataPackVGUI(dataBuffer);
	return Plugin_Handled;
}

/**
 * Sends a VGUI message that was previously packed into a DataPack.
 */
public void SendDataPackVGUI(DataPack dataBuffer) {
	dataBuffer.Reset();
	
	int nPackedPlayers = dataBuffer.ReadCell(), nPlayers;
	int[] players = new int[nPackedPlayers];
	for (int i = 0; i < nPackedPlayers; i++) {
		int recipient = GetClientOfUserId(dataBuffer.ReadCell());
		
		if (recipient) {
			players[nPlayers++] = recipient;
		}
	}
	
	int flags = dataBuffer.ReadCell();
	
	if (nPlayers) {
		Handle msg = StartMessage("VGUIMenu", players, nPlayers, flags | USERMSG_BLOCKHOOKS);
		Protobuf pb = UserMessageToProtobuf(msg);
		
		pb.SetString("name", "info");
		pb.SetBool("show", dataBuffer.ReadCell()); // bShow
		
		int count = dataBuffer.ReadCell();
		
		char content[1024];
		for (int i = 0; i < count; i++) {
			Protobuf subkey = pb.AddMessage("subkeys");
			
			dataBuffer.ReadString(content, sizeof(content));
			subkey.SetString("name", content);
			
			dataBuffer.ReadString(content, sizeof(content));
			subkey.SetString("str", content);
		}
		
		// writestring "cmd" and "closed_htmlpage" if you want to detect closing every html page
		// could be useful by itself
		
		EndMessage();
	}
	delete dataBuffer;
}

/**
 * Displays a hidden MOTD that makes a request to INVALID_PAGE_URL.
 */
void DisplayHiddenInvalidMOTD(const int[] players, int nPlayers) {
	static KeyValues invalidPageInfo;
	
	if (!invalidPageInfo) {
		invalidPageInfo = new KeyValues("data");
		invalidPageInfo.SetString("title", "");
		invalidPageInfo.SetNum("type", MOTDPANEL_TYPE_URL);
		invalidPageInfo.SetString("msg", INVALID_PAGE_URL);
	}
	
	for (int i = 0; i < nPlayers; i++) {
		ShowVGUIPanel(players[i], "info", invalidPageInfo, false);
	}
}

/**
 * Searches for an appropriate bypass method based on the URL.  The longest matching prefix
 * takes precedence.
 */
static BypassMethod GetBypassMethodForURL(const char[] url) {
	int matchLength;
	int handler = StrContains(url, "://");
	
	if (handler == -1) {
		return Bypass_None;
	}
	
	char defaultMethod[MAX_BYPASS_METHOD_LENGTH];
	g_URLConfig.GetString("*", defaultMethod, sizeof(defaultMethod));
	
	BypassMethod returnValue = GetBypassMethodFromString(defaultMethod);
	
	// iterate keyvalues
	g_URLConfig.GotoFirstSubKey(false);
	do {
		char matchingURL[PLATFORM_MAX_PATH];
		g_URLConfig.GetSectionName(matchingURL, sizeof(matchingURL));
		
		if (StrContains(url[handler + 3], matchingURL) == 0
				&& strlen(matchingURL) > matchLength) {
			char bypassMethodString[MAX_BYPASS_METHOD_LENGTH];
			g_URLConfig.GetString(NULL_STRING, bypassMethodString, sizeof(bypassMethodString));
			
			returnValue = GetBypassMethodFromString(bypassMethodString);
			matchLength = strlen(matchingURL);
		}
	} while (g_URLConfig.GotoNextKey(false));
	g_URLConfig.GoBack();
	
	return returnValue;
}

/**
 * Converts a string (from the config) to a value from the BypassMethod enum.
 */
static BypassMethod GetBypassMethodFromString(const char[] bypassMethod) {
	if (StrEqual(bypassMethod, "proxy")) {
		return Bypass_Proxy;
	} else if (StrEqual(bypassMethod, "delayed")) {
		return Bypass_DelayedLoad;
	} else if (StrEqual(bypassMethod, "none")) {
		return Bypass_None;
	}
	
	return Bypass_DelayedLoad;
}