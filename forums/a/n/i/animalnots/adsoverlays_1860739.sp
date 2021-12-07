#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <morecolors> 
#define PLUGIN_VERSION "1.1"
//#define DEBUG true

public Plugin:myinfo = {
	name = "AdsOverlays",
	author = "Animalnots",
	description = "Show advertisments via overlays while player is dead or spectating",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1860739"
};

new Handle:g_hOverlayTriggerStop; // Handle - Convar trigger to stop showing ads
new String:g_sTriggerStop[256]; // String Value - the trigger to stop showing ads
new Handle:g_hOverlayTime; // Handle - Convar the time needed for an ad to change
new Float:g_fTimer; // Float Value - the time needed for an ad to change
new Handle:g_hOverlayCustomShowToVip; // Handle - Convar show ads to vip and root or not
new bool:g_dShowToVip; // Boolean Value - show ads to vip and root or not
new Handle:Connect_Timers[MAXPLAYERS+1]; //CALLED ONCE AFTER CONNECTION, checks who is the player and decides to show ads or not
new Handle:Loop_Timers[MAXPLAYERS+1]; // CALLED EVERY X SECOND TO SHOW NEXT OVERLAY

new g_dOverlayAdsNum; // Total Number of ads
new String:g_sOverlayPaths[256][256]; // Overlays Paths
new g_currentad[MAXPLAYERS+1]; // Ad Id in rotation (determines which ad shown to client at the moment)

new bool:g_isVip[MAXPLAYERS+1]; // Is Player VIP or Root
new bool:g_ShowAd[MAXPLAYERS+1]; // DO WE NEED TO SHOW OVERLAYS (It's the main thing that determines to show ads to a client or not)


public OnPluginStart()
{
	// Translations
	LoadTranslations("adsoverlays.phrases");
	
	// Opens ads.txt and reads overlays paths
	decl String:path[PLATFORM_MAX_PATH],String:line[256];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"configs/ads.txt");
	new Handle:fileHandle=OpenFile(path,"r"); // Opens addons/sourcemod/configs/ads.txt to read from (and only reading)
	g_dOverlayAdsNum = 0; // Total Number of ads
	
	// READING
	while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
	{
		TrimString(line);
		g_sOverlayPaths[g_dOverlayAdsNum] = line;
		g_dOverlayAdsNum++;
	}
	CloseHandle(fileHandle);
	// END READING
	
	// DEBUG
	#if defined DEBUG
		LogAction(-1, -1, "[AO]: Read %d line from ads.txt", g_dOverlayAdsNum);
		PrintToServer("[AO]: Read %d line from ads.txt", g_dOverlayAdsNum);
	#endif
	// END DEBUG
	
	// Convars
	CreateConVar("sm_adsoverlays", "1.0", "Version of RulesOverlay plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hOverlayTime = CreateConVar("sm_ao_time", "10.0", "How often ads change");
	g_hOverlayCustomShowToVip = CreateConVar("sm_ao_showtovip", "0", "Show ads to vips or root", _, true, 0.0, true, 1.0);
	g_dShowToVip  = GetConVarBool(g_hOverlayCustomShowToVip);
	g_fTimer = GetConVarFloat(g_hOverlayTime);
	g_hOverlayTriggerStop = CreateConVar("sm_ao_triggerstop", "!stop", "Trigger to stop showing ads");
	GetConVarString(g_hOverlayTriggerStop, g_sTriggerStop, sizeof(g_sTriggerStop)); // String Value - the trigger to stop showing ads
	
	// Cmds & triggers
	RegConsoleCmd("say", Say_callback, "For catching stop trigger");
	RegConsoleCmd("say2", Say_callback,"For catching stop trigger");
	RegConsoleCmd("say_team", Say_callback, "For catching stop trigger");
	//AdCommandListener(Stop_callback,g_sTriggerStop);
	RegAdminCmd("sm_ao", Command_ShowAd, ADMFLAG_ROOT, "Shows mentioned ad to root");

	// Exec Config
	AutoExecConfig(true);
}

public Action:Command_ShowAd(client, args)
{
	new String:buffer[256]; // FOR loading translations
	new userid = GetClientUserId(client); // userid to show overlay to
	new argsnum = GetCmdArgs(); // numargs: 0 = OverlayClean, 1 = show overlay with number mentioned in 1-st argument
	
	// DEBUG
	#if defined DEBUG
		GetClientName(client, buffer, sizeof(buffer));
		LogAction(client, -1, "[AO]: Player %s triggered sm_ao command, Total args - %d", buffer, argsnum);
		PrintToServer("[AO]: Player %s triggered sm_ao command, Total args - %d", buffer, argsnum);
	#endif
	// END DEBUG
	
	
	if (argsnum != 1) {
		// If ad number not mentioned, reset overlay
		Format(buffer, sizeof(buffer), "%T", "[AO]: sm_ao adnum, force an ad to be shown to you. sm_ao with no arguments hides overlays.", client);
		CPrintToChat(client, buffer);
		OverlayClean(userid);
		
		// DEBUG
		#if defined DEBUG
			GetClientName(client, buffer, sizeof(buffer));
			LogAction(client, -1, "[AO]: Calling OverlayClean for %s", buffer);
			PrintToServer("[AO]: Calling OverlayClean for %s", buffer);
		#endif
		// END DEBUG
	} else {
		// Show overlay with mentioned id
		new String:arg[256];
		GetCmdArg(1,arg,sizeof(arg));
		new adid = StringToInt(arg);
		OverlayCustomShow(userid, adid);
		
		// DEBUG
		#if defined DEBUG
			GetClientName(client, buffer, sizeof(buffer));
			LogAction(client, -1, "[AO]: Calling OverlayCustomShow for %s", buffer);
			PrintToServer("[AO]: Calling OverlayCustomShow for %s", buffer);
		#endif
		// END DEBUG
	}
}

public OnClientPostAdminCheck(client)
{
	new flags = GetUserFlagBits(client);
	new userid = GetClientUserId(client);
	g_ShowAd[client] = true;
	g_isVip[client] = false;
	//If client is vip , we do not show him ads
	if (flags & ADMFLAG_CUSTOM1 || flags & ADMFLAG_ROOT)
	{
		if (!g_dShowToVip) {
			// We don't want to show ad to this vip user
			g_isVip[client] = true; // Needs to check in ClientConnectCheck if he's vip, and to print grateful message	
			g_ShowAd[client] = false;
		}
		
		// DEBUG
		#if defined DEBUG			
			GetClientName(client, buffer, sizeof(buffer));
			LogAction(client, -1, "[AO]: %s is Admin or VIP", buffer);
			PrintToServer("[AO]: %s is Admin or VIP", buffer);
		#endif
		// END DEBUG
	}
	Connect_Timers[client] = CreateTimer(10.0, ClientConnectCheck, userid);
}
public OnClientDisconnect(client)
{
	g_isVip[client] = false;
	g_ShowAd[client] = false;
	g_currentad[client] = 0;
	// Kill connect timer if client left too early
	if (Connect_Timers[client] != INVALID_HANDLE)
	{
		KillTimer(Connect_Timers[client]);
		Connect_Timers[client] = INVALID_HANDLE;
	}
	// Kill any ad rotation timer (loop_timer)
	if (Loop_Timers[client] != INVALID_HANDLE)
	{
		KillTimer(Loop_Timers[client]);
		Loop_Timers[client] = INVALID_HANDLE;
	}
}
public Action:ClientConnectCheck(Handle:timer, any:userid)
{
	new client;
	new String:buffer[256]; // For translations
	client = GetClientOfUserId(userid);
	if(Client_IsIngame(client) && Client_IsValid(client)) {
		g_currentad[client] = 0; // Begin from first ad
		if (g_ShowAd[client]) {
			// Call timer that will Show overlay to user
			Loop_Timers[client] = CreateTimer(g_fTimer, NextOverlayShow, userid);
			
			// DEBUG
			#if defined DEBUG			
				GetClientName(client, buffer, sizeof(buffer));
				LogAction(client, -1, "[AO]: %s is not VIP, showing ads", buffer);
				PrintToServer("[AO]: %s is not VIP, showing ads", buffer);
			#endif
			// END DEBUG
		} else {
			// DEBUG
			#if defined DEBUG			
				GetClientName(client, buffer, sizeof(buffer));
				LogAction(client, -1, "[AO]: %s is VIP, ads free", buffer);
				if (g_isVip[client]) {
					PrintToServer("[AO]: %s is VIP, ads free", buffer);
				} else {
					PrintToServer("[AO]: %s used trigger to disable ads", buffer);
				}
			#endif
			// END DEBUG
			
			if (g_isVip[client]) {
				//client is vip
				Format(buffer, sizeof(buffer), "%T", "[VIP] As VIP, you can play without ads! Thank you For Your Support!", client);
				CPrintToChat(client, buffer);
			}
		}
	}
	Connect_Timers[client]  = INVALID_HANDLE;
}

public Action:Say_callback(client, args)
{
	
	new String:arg[256];
	new String:buffer[256];
	new userid = GetClientUserId(client);
	GetCmdArg(1,arg,sizeof(arg));
	if(Client_IsIngame(client) && Client_IsValid(client)) {
		if (StrEqual(arg,g_sTriggerStop,false) && g_ShowAd[client]) {
			OverlayStop(userid);
			Format(buffer, sizeof(buffer), "%T", "[AO]: We will not show visual ads till your next connect!", client);
			CPrintToChat(client, buffer);
		}
	}
	return Plugin_Continue;
}

public Action:NextOverlayShow(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(Client_IsIngame(client) && Client_IsValid(client))
	{
		if (g_ShowAd[client]) {
			// Rotate ads
			if (!IsPlayerAlive(client) && (g_dOverlayAdsNum > 0)) {
				OverlayClean(userid);
				OverlaySet(userid, g_sOverlayPaths[g_currentad[client]]);
				if (g_currentad[client]+1 >= g_dOverlayAdsNum) {
					g_currentad[client] = 0;
				} else {
					g_currentad[client] = g_currentad[client] + 1;
				}
			} else {
				OverlayClean(userid);
			}
			// Call NextOverlayShow in g_fTimer seconds
			if (Loop_Timers[client] != INVALID_HANDLE)
			{
				KillTimer(Loop_Timers[client]);
				Loop_Timers[client] = INVALID_HANDLE;
			}
			Loop_Timers[client] = CreateTimer(g_fTimer, NextOverlayShow, userid);
		}
	} else {
		// Destroying timers, resetting values and similiar stuff is handled with OnClientDisconnect
		// else case is supposed to be never triggered
	}
}

public Action:OverlayCustomShow(any:userid, any:adnum)
{
	OverlayStop(userid); // stop any rotation
	if(g_dOverlayAdsNum > 0 && (adnum >= 0) && (adnum < g_dOverlayAdsNum)) {
		OverlaySet(userid, g_sOverlayPaths[adnum]);
	}
}

public Action:OverlayClean(any:userid)
{
	// Prepare User Screen (cleans) To Show Next Overlay
	new client = GetClientOfUserId(userid);
	if(Client_IsIngame(client) && Client_IsValid(client))
	{
		Client_SetScreenOverlay(client, "off");
		Client_SetScreenOverlay(client, "");			
	} else {
		// Destroying timers, resetting values and similiar stuff is handled with OnClientDisconnect
		// else case is supposed to be never triggered
	}
}

public Action:OverlayStop(any:userid)
{
	// Stops showing overlays
	new client = GetClientOfUserId(userid);
	if(Client_IsIngame(client) && Client_IsValid(client))
	{
		OverlayClean(userid);
		g_ShowAd[client] = false;
		g_currentad[client] = 0;
		// Kill connect timer if client left too early
		if (Connect_Timers[client] != INVALID_HANDLE)
		{
			KillTimer(Connect_Timers[client]);
			Connect_Timers[client] = INVALID_HANDLE;
		}
		// Kill any ad rotation timer (loop_timer)
		if (Loop_Timers[client] != INVALID_HANDLE)
		{
			KillTimer(Loop_Timers[client]);
			Loop_Timers[client] = INVALID_HANDLE;
		}
	}
}

stock OverlaySet(any:userid, String:overlay[])
{
	new client = GetClientOfUserId(userid);
	if(Client_IsIngame(client) && Client_IsValid(client))
	{
		Client_SetScreenOverlay(client, overlay);
	}
}

public OnMapStart()
{
	decl String:vmt[PLATFORM_MAX_PATH];
	decl String:vtf[PLATFORM_MAX_PATH];
	PrintToServer("Found %d ads:",g_dOverlayAdsNum);
	LogAction(-1, -1, "Found %d ads:",g_dOverlayAdsNum);
	for (new i = 0; i < g_dOverlayAdsNum; i++)
	{
		// Adds overlays to downloads table and prechaches them
		Format(vtf, sizeof(vtf), "materials/%s.vtf", g_sOverlayPaths[i]);
		Format(vmt, sizeof(vmt), "materials/%s.vmt", g_sOverlayPaths[i]);
		AddFileToDownloadsTable(vtf);
		AddFileToDownloadsTable(vmt);
		PrecacheDecal(vtf, true);
		PrintToServer("%d) %s", i, vtf);
		LogAction(-1, -1, "%d) %s", i, vtf);
		
	}
}