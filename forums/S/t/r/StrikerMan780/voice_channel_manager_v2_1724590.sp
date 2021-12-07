#include <sourcemod>
#include <sdktools>
#include <colors>
#include <smlib>

#define PLUGIN_VERSION "2.5"

#define MAXCLIENTS 255
#define ARRAYS_SIZE 128
#define NO_CHANNEL -1

// CHANNEL MODE

#define CHMODE_PUBLIC 0
#define CHMODE_PRIVATE 1
#define CHMODE_ADMIN 2

// ANOUNCER MODE

#define ANNOUNCERMODE_SPEAK 0
#define ANNOUNCERMODE_MUTE 1
#define ANNOUNCERMODE_LISTEN 2

// HUD MODE

#define HUD_DISABLED 0
#define HUD_CHANNEL 1
#define HUD_CHANNEL_ALL 2
#define HUD_SPECTATOR 3

// SPECTATOR MOODE

#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 			5
#define SPECMODE_FREELOOK	 		6

new g_iChannels;
new g_iChannelsCount[65];
new g_iChannelsMode[65];
new g_iChannelsShowHUD[65];
new g_iChannelsTeams[65];

new String:g_sChannelsName[65][ARRAYS_SIZE];
new String:g_sChannelsPass[65][ARRAYS_SIZE];
new String:g_sChannelsFlag[65][ARRAYS_SIZE];

new String:SavePath[256];

new g_iClientChannel[MAXCLIENTS+1];
new g_iClientInvites[MAXCLIENTS+1];
new g_iClientChTryPrivate[MAXCLIENTS+1];
new g_iClientChTryPw[MAXCLIENTS+1];

new Handle:HudHintTimers[MAXPLAYERS+1];

new Handle:vc_show_incoming = INVALID_HANDLE;
new Handle:vc_store_channel = INVALID_HANDLE;
new Handle:vc_admin_ignore_channel_pw = INVALID_HANDLE;
new Handle:vc_public_channel_id = INVALID_HANDLE;
new Handle:vc_announcer_channel_id = INVALID_HANDLE;
new Handle:vc_announcer_mode = INVALID_HANDLE;

new Handle:vc_invite_max = INVALID_HANDLE;
new Handle:vc_invite_admins = INVALID_HANDLE;
new Handle:vc_invite_enable = INVALID_HANDLE;
new Handle:vc_invite_admin_only = INVALID_HANDLE;
new Handle:vc_invite_public_only = INVALID_HANDLE;

new Handle:vc_hud_enable = INVALID_HANDLE;
new Handle:vc_hud_show_status = INVALID_HANDLE;
new Handle:vc_hud_show_self = INVALID_HANDLE;
new Handle:vc_hud_show_player_count = INVALID_HANDLE;
new Handle:vc_hud_show_invites = INVALID_HANDLE;
new Handle:vc_hud_show_invite_cmd = INVALID_HANDLE;
new Handle:vc_hud_show_channel_cmd = INVALID_HANDLE;
new Handle:vc_hud_show_team = INVALID_HANDLE;
new Handle:vc_hud_show_public_all = INVALID_HANDLE;

new Handle:vc_hud_team_tag_1 = INVALID_HANDLE;
new Handle:vc_hud_team_tag_2 = INVALID_HANDLE;
new Handle:vc_hud_team_tag_3 = INVALID_HANDLE;

new Handle:vc_hud_status_tag_alive = INVALID_HANDLE;
new Handle:vc_hud_status_tag_dead = INVALID_HANDLE;

new Handle:vc_hud_update_interval = INVALID_HANDLE;

/**
new Handle:vc_snd_enable = INVALID_HANDLE;
new Handle:vc_snd_incorrect_password = INVALID_HANDLE;
new Handle:vc_snd_permissions = INVALID_HANDLE;
new Handle:vc_snd_joined_channel = INVALID_HANDLE;
new Handle:vc_snd_kick = INVALID_HANDLE;
new Handle:vc_snd_usr_disconnect = INVALID_HANDLE;
new Handle:vc_snd_usr_joined = INVALID_HANDLE;
new Handle:vc_snd_usr_kick = INVALID_HANDLE;
new Handle:vc_snd_usr_kick2current = INVALID_HANDLE;
new Handle:vc_snd_usr_left = INVALID_HANDLE;
*/

new Float:cvar_vc_hud_update_interval;

new String:cvar_vc_hud_team_tag_1[32];
new String:cvar_vc_hud_team_tag_2[32];
new String:cvar_vc_hud_team_tag_3[32];

new String:cvar_vc_hud_status_tag_alive[32];
new String:cvar_vc_hud_status_tag_dead[32];

/**
new String:cvar_vc_snd_incorrect_password[32];
new String:cvar_vc_snd_permissions[32];
new String:cvar_vc_snd_joined_channel[32];
new String:cvar_vc_snd_kick[32];
new String:cvar_vc_snd_usr_disconnect[32];
new String:cvar_vc_snd_usr_joined[32];
new String:cvar_vc_snd_usr_kick[32];
new String:cvar_vc_snd_usr_kick2current[32];
new String:cvar_vc_snd_usr_left[32];

new bool:snd_incorrect_password_enable;
new bool:snd_permissions_enable;
new bool:snd_joined_channel_enable;
new bool:snd_kick_enable;
new bool:snd_usr_disconnect_enable;
new bool:snd_usr_joined_enable;
new bool:snd_usr_kick_enable;
new bool:snd_usr_kick2current_enable;
new bool:snd_usr_left_enable;
*/

public Plugin:myinfo = {
	name = "Advanced Voice Channel Manager V2",
	author = "s1dex & zipcore",
	description = "Advanced Voice Channel Manager V2",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1601253"
};

public OnPluginStart()
{	
	RegConsoleCmd("vc", VCChooseChannelGui);
	RegConsoleCmd("vci",VCInviteGui)
	RegConsoleCmd("vck",VCKickGui)
	RegConsoleCmd("vcs", VCSetChnl);
	RegConsoleCmd("vcl", VCList);
	
	RegConsoleCmd("say", CmdSay);
	
	BuildPath(Path_SM, SavePath, 255, "data/VoiceMgrSave.txt");
	LoadTranslations("voicemgr.phrases");
	
	CreateConVar("vc_version", PLUGIN_VERSION, "VoiceMgr Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	vc_show_incoming = CreateConVar("vc_show_incoming", "0", "Show channel transfer msg if client connected (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_store_channel = CreateConVar("vc_store_channel", "1", "Rememberlast channel if a client switch channel? (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_admin_ignore_channel_pw = CreateConVar("vc_admin_ingore_channel_pw", "1", "Can Admins join private channels without password? (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_public_channel_id = CreateConVar("vc_public_channel_id", "-1", "Only change if you like to change default channel (-1=first public channel)", FCVAR_PLUGIN);
	vc_announcer_channel_id = CreateConVar("vc_announcer_channel_id", "-1", "Only change if you like to create an announcer channel channel (-1=no announcer channel)", FCVAR_PLUGIN);
	vc_announcer_mode = CreateConVar("vc_announcer_mode", "0", "Additional to vc_announcer_channel_id (0=speak to all; 1=speak to all and mute everyone else; 2=speak to all and listen all)", FCVAR_PLUGIN, true, 0.0,true, 2.0);
	
	vc_invite_max = CreateConVar("vc_invite_max", "3", "Max. invites per map for non-admins (0=unl.)", FCVAR_PLUGIN, true, 0.0);
	vc_invite_admins = CreateConVar("vc_invite_admins", "1", "Can non-admins invite admins? (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_invite_enable = CreateConVar("vc_invite_enable", "1", "Enable invite cmd (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_invite_admin_only = CreateConVar("vc_invite_admin_only", "0", "Only admins can use invite command (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_invite_public_only = CreateConVar("vc_invite_public_only", "1", "Only invite player if they are in default channel (0=all channels; 1=only default channel; 2=all public channels)", FCVAR_PLUGIN, true, 0.0,true, 2.0);
	
	vc_hud_enable = CreateConVar("vc_hud_enable", "1", "Enable channel HUD (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_hud_show_status = CreateConVar("vc_hud_show_status", "1", "Show [ALIVE] & [DEAD] behind name (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_hud_show_self = CreateConVar("vc_hud_show_self", "1", "Show yourself listed (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_hud_show_player_count = CreateConVar("vc_hud_show_player_count", "1", "Show count of online players in channel (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_hud_show_invites = CreateConVar("vc_hud_show_invites", "1", "Show invites left (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	vc_hud_show_invite_cmd = CreateConVar("vc_hud_show_invite_cmd", "2", "Show !vci? (0=disable; 1=ever; 2=only if public channel is not empty)", FCVAR_PLUGIN, true, 0.0,true, 2.0);
	vc_hud_show_channel_cmd = CreateConVar("vc_hud_show_channel_cmd", "2", "Show !vc? (0 = disable; 1=ever; 2=only public channel)", FCVAR_PLUGIN, true, 0.0,true, 2.0);
	vc_hud_show_team = CreateConVar("vc_hud_show_team", "1", "Show team tags in front of name (0=disable; 1=all channels 2=only team channels", FCVAR_PLUGIN, true, 0.0,true, 2.0);
	vc_hud_show_public_all = CreateConVar("vc_hud_show_public_all", "1", "List all channels if current channel is default channel (0=disable; 1=only not empty 2=all channels)", FCVAR_PLUGIN, true, 0.0,true, 2.0);
	vc_hud_team_tag_1 = CreateConVar("vc_team_tag_1", "[SPEC] ", "Team tag for team 1/Spectator");
	vc_hud_team_tag_2 = CreateConVar("vc_team_tag_2", "[RED] ", "Team tag for team 2/Red/T");
	vc_hud_team_tag_3 = CreateConVar("vc_team_tag_3", "[BLU] ", "Team tag for team 3/Blue/CT");
	vc_hud_status_tag_alive = CreateConVar("vc_hud_status_tag_alive", " [ALIVE]", "Status tag for alive players");
	vc_hud_status_tag_dead = CreateConVar("vc_hud_status_tag_dead", " [DEAD]", "Status tag for dead players");
	vc_hud_update_interval = CreateConVar("vc_hud_update_interval", "1.0", "Update interval of channel HUD", FCVAR_PLUGIN, true, 0.5);
	vc_hud_status_tag_dead = CreateConVar("vc_hud_status_tag_dead", " [DEAD]", "Status tag for dead players");
	
	AutoExecConfig(true, "voice_channel_manager_v2");
	
	GetConVarString(vc_hud_team_tag_1, cvar_vc_hud_team_tag_1, sizeof(cvar_vc_hud_team_tag_1));
	GetConVarString(vc_hud_team_tag_2, cvar_vc_hud_team_tag_2, sizeof(cvar_vc_hud_team_tag_2));
	GetConVarString(vc_hud_team_tag_3, cvar_vc_hud_team_tag_3, sizeof(cvar_vc_hud_team_tag_3));
	
	GetConVarString(vc_hud_status_tag_alive, cvar_vc_hud_status_tag_alive, sizeof(cvar_vc_hud_status_tag_alive));
	GetConVarString(vc_hud_status_tag_dead, cvar_vc_hud_status_tag_dead, sizeof(cvar_vc_hud_status_tag_dead));
	
	HookEvent("player_team", EventPlayerTeam);
}

/**
CreateCVARs()
{
	vc_snd_enable = CreateConVar("vc_snd_enable", "1", "Enable Sounds (0=disable; 1=enable)", FCVAR_PLUGIN, true, 0.0,true, 1.0);
	
	vc_snd_incorrect_password = CreateConVar("vc_snd_incorrect_password", "0", "Play this sound if your password is incorrect (0=disable)");
	vc_snd_joined_channel = CreateConVar("vc_snd_joined_channel", "0", "Play this sound if you joined a channel (0=disable)");
	vc_snd_kick = CreateConVar("vc_snd_kick", "0", "Play this sound if you were kicked out of your channel (0=disable)");
	vc_snd_permissions = CreateConVar("vc_snd_permissions", "0", "Play this sound if you have no permission to enter a channel(0=disable)");
	vc_snd_usr_disconnect = CreateConVar("vc_snd_usr_disconnect", "0", "Play this sound if someone disconnected from your channel (0=disable)");
	vc_snd_usr_joined = CreateConVar("vc_snd_usr_joined", "0", "Play this sound if someone joined your channel (0=disable)");
	vc_snd_usr_kick = CreateConVar("vc_snd_usr_kick", "0", "Play this sound if was kicked out of your channel (0=disable)");
	vc_snd_usr_kick2current = CreateConVar("vc_snd_usr_kick2current", "0", "Play this sound if someone was kicked into you channel (0=disable)");
	vc_snd_usr_left = CreateConVar("vc_snd_usr_left", "0", "Play this sound if someone left your channel (0=disable)");
}

LoadCVARs()
{
	GetConVarString(vc_snd_incorrect_password, cvar_vc_snd_incorrect_password, sizeof(cvar_vc_snd_incorrect_password));
	GetConVarString(vc_snd_joined_channel, cvar_vc_snd_joined_channel, sizeof(cvar_vc_snd_joined_channel));
	GetConVarString(vc_snd_kick, cvar_vc_snd_kick, sizeof(cvar_vc_snd_kick));
	GetConVarString(vc_snd_permissions, cvar_vc_snd_permissions, sizeof(cvar_vc_snd_permissions));
	
	GetConVarString(vc_snd_usr_disconnect, cvar_vc_snd_usr_disconnect, sizeof(cvar_vc_snd_usr_disconnect));
	GetConVarString(vc_snd_usr_joined, cvar_vc_snd_usr_joined, sizeof(cvar_vc_snd_usr_joined));
	GetConVarString(vc_snd_usr_kick, cvar_vc_snd_usr_kick, sizeof(cvar_vc_snd_usr_kick));
	GetConVarString(vc_snd_usr_kick2current, cvar_vc_snd_usr_kick2current, sizeof(cvar_vc_snd_usr_kick2current));
	GetConVarString(vc_snd_usr_left, cvar_vc_snd_usr_left, sizeof(cvar_vc_snd_usr_left));
}
*/

LoadChannels()
{
	decl String:file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/voicemgr.channels.cfg");
	new Handle:kv = CreateKeyValues("Channels");
	FileToKeyValues(kv, file);
	if (KvGotoFirstSubKey(kv))
	{
		do
		{
			g_iChannels++;
			
			decl String:buffer[32];
			KvGetSectionName(kv, g_sChannelsName[g_iChannels], ARRAYS_SIZE);
			
			//Get Channel Mode
			KvGetString(kv, "mode", buffer, sizeof(buffer), "public");
			if (StrEqual(buffer, "private"))
			{
				g_iChannelsMode[g_iChannels] = CHMODE_PRIVATE;
			}
			else if (StrEqual(buffer, "admins"))
			{
				g_iChannelsMode[g_iChannels] = CHMODE_ADMIN;
			}
			else
			{
				g_iChannelsMode[g_iChannels] = CHMODE_PUBLIC;
			}
			
			//Get Channel Password
			if (g_iChannelsMode[g_iChannels] == CHMODE_PRIVATE)
			{
				KvGetString(kv, "password", g_sChannelsPass[g_iChannels], ARRAYS_SIZE, "pw");
			}
			
			//Get Required Admin Flags
			if (g_iChannelsMode[g_iChannels] == CHMODE_ADMIN)
			{
				KvGetString(kv, "flag", g_sChannelsFlag[g_iChannels], ARRAYS_SIZE, "slay");
			}
			
			//Get Team Channel Mode
			g_iChannelsTeams[g_iChannels] = KvGetNum(kv, "teams", CHMODE_PUBLIC);
			
			//Get HUD Channel Mode
			g_iChannelsShowHUD[g_iChannels] = KvGetNum(kv, "hud", HUD_DISABLED);
		}
		while (KvGotoNextKey(kv))
	}
}

public OnClientDisconnect(client)
{
	
	new cvar_vc_hud_enable = GetConVarInt(vc_hud_enable);
	//new cvar_vc_snd_enable = GetConVarInt(vc_snd_enable);
	
	if(cvar_vc_hud_enable == 1)
	{
		KillHudHintTimer(client);
	}
	/**
	if(cvar_vc_snd_enable == 1 && snd_usr_disconnect_enable)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				if(i != client)
				{
					if(g_iClientChannel[i] == g_iClientChannel[client])
					{
						EmitSoundToClient(client, cvar_vc_snd_usr_disconnect);
					}
				}
			}
		}
	}
	*/
}

public OnClientPutInServer(client)
{
	new cvar_vc_hud_enable = GetConVarInt(vc_hud_enable);
	new cvar_vc_store_channel = GetConVarInt(vc_store_channel);
	new cvar_vc_show_incoming = GetConVarInt(vc_show_incoming);
	
	decl String:name[64];
	GetClientName(client, name, sizeof(name));
	if(cvar_vc_hud_enable == 1)
	{
		CreateHudHintTimer(client);
	}
	
	g_iClientChTryPw[client] = 0;
	g_iClientChTryPrivate[client] = 0;
	g_iClientChannel[client] = NO_CHANNEL;
	
	if(cvar_vc_store_channel == 1)
	{
		LoadSettings(client);
	}
	
	if(g_iClientChannel[client] == NO_CHANNEL)
	{
		g_iClientChannel[client] = GetFirstPublicChannel();
		CPrintToChatAll("%t", "ChangeChannel", name, g_sChannelsName[g_iClientChannel[client]]);
	}
	else if(cvar_vc_show_incoming == 1)		
	{
		CPrintToChatAll("%t", "ChangeChannel", name, g_sChannelsName[g_iClientChannel[client]]);
	}
}

public OnMapStart()
{
	
	new cvar_vc_invite_max = GetConVarInt(vc_invite_max);
	//decl String:szText[254];
	
	//Reload Channel Config
	g_iChannels = NO_CHANNEL;
	LoadChannels();
	
	if(g_iChannels == NO_CHANNEL)
	{
		LogError("[VoiceMgr] No channel configured!");
	}
	
	for(new i = 1; i <= MaxClients; i++) 
	{
		//Reset Invites
		g_iClientInvites[i] = cvar_vc_invite_max;
	}
}

public Action:EventPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
	// refresh client channel after a delay to fix invalid memory access bug
	CreateTimer(0.1, Timer_ChangeTeam, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:Timer_ChangeTeam(Handle:timer, any:client)
{
	RefreshClientChannel(client);
	return Plugin_Stop;
}

public Action:VCChooseChannelGui(client, args)
{
	PrintToConsole(client, "ch ch");
	decl String:szText[254];
	new Handle:menu = CreateMenu(MenuChooseChannel);
	SetMenuTitle(menu, "Choose a voice channel [current: %s]", g_sChannelsName[g_iClientChannel[client]]);
	
	decl String:buffer[5];
	for (new i=0;i<=g_iChannels;i++)
	{
		Format(szText, sizeof(szText), "%s (%d online)", g_sChannelsName[i], g_iChannelsCount[i]);
		IntToString(i, buffer, sizeof(buffer));
		AddMenuItem(menu, buffer, szText);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
		
	return Plugin_Handled;
}

public Action:VCSetChnl(client, args)
{
	PrintToConsole(client, "set ch");
	if(0 < client < MaxClients)
	{
		decl String:arg[32];
		GetCmdArg(1, arg, sizeof(arg));
		
		new chnl = StringToInt(arg);
		if (chnl > g_iChannels)
		{
			CPrintToChat(client, "%t", "NotRegistered", chnl);
			return Plugin_Handled;
		}
		else if (chnl == g_iClientChannel[client])
		{
			CPrintToChat(client, "%t", "AlreadyIn");
			return Plugin_Handled;
		}
		else
		{
			if (g_iChannelsMode[chnl] == CHMODE_ADMIN)
			{
				new AdminId:admin;
				if ((admin = GetUserAdmin(client)) == INVALID_ADMIN_ID)
				{
					CPrintToChat(client, "%t", "AdminsOnly");
					return Plugin_Handled;
				}
				else
				{
					new AdminFlag:flag;
					FindFlagByName(g_sChannelsFlag[chnl], flag);
					
					if (!GetAdminFlag(admin, flag))
					{
						CPrintToChat(client, "%t", "InvalidFlag", g_sChannelsFlag[chnl]);
						return Plugin_Handled;
					}
				}
			}
			else if (g_iChannelsMode[chnl] == CHMODE_PRIVATE)
			{
				decl String:info[128];
				GetClientInfo(client, "_vcpass", info, sizeof(info));
				if (!StrEqual(info, g_sChannelsPass[chnl]))
				{
					CPrintToChat(client, "%t", "Private1");
					CPrintToChat(client, "%t", "Private2");
					return Plugin_Handled;
				}
			}
			
			decl String:name[64];
			GetClientName(client, name, sizeof(name));
			
			g_iClientChannel[client] = chnl;
			RefreshClientChannel(client);
			CPrintToChatAll("%t", "ChangeChannel", name, g_sChannelsName[chnl]);
		}
	}
	return Plugin_Handled;
}

public Action:VCList(client, args)
{
	PrintToConsole(client, "li ch");
	if(0 < client < MaxClients)
	{
		PrintToConsole(client, "[VoiceMgr] Channels:");
		for (new i=0;i<=g_iChannels;i++)
		{
			if(g_iChannelsMode[i] == CHMODE_PRIVATE)
			{
				if(Client_IsAdmin(client))
				{
					PrintToConsole(client, "ID: %d - %s (pw: %s)", i, g_sChannelsName[i], g_sChannelsPass[i]);
				}
				else
				{
					PrintToConsole(client, "ID: %d - %s (pwd protected)", i, g_sChannelsName[i], g_sChannelsPass[i]);
				}
			}
			else
			{
				PrintToConsole(client, "ID: %d - %s", i, g_sChannelsName[i]);
			}
		}
		
		CPrintToChat(client, "%t", "ListChannels");
	}
	return Plugin_Handled;
}

public Action:VCKickGui(client, args)
{
	PrintToConsole(client, "ki");
	if(0 < client < MaxClients)
	{
		decl String:szText[254];
		new i_counter;
		
		if(Client_IsAdmin(client))
		{
			if(g_iClientChannel[client] != GetFirstPublicChannel())
			{
				new Handle:menu = CreateMenu(MenuKickChannel);
				SetMenuTitle(menu, "Kick a player out of your channel [current: %s]", g_sChannelsName[g_iClientChannel[client]]);
				
				decl String:buffer[5];
				for (new i=1;i<=MAXPLAYERS;i++)
				{
					if(Client_IsIngame(i) && i != client && g_iClientChannel[client] == g_iClientChannel[i])
					{
						i_counter++;
						Format(szText, sizeof(szText), "%N", i);
						IntToString(i, buffer, sizeof(buffer));
						AddMenuItem(menu, buffer, szText);
					}
				}
				if(i_counter < 1)
				{
					Format(szText, sizeof(szText), "Sorry, no other players found!");
					IntToString(NO_CHANNEL, buffer, sizeof(buffer));
					AddMenuItem(menu, buffer, szText);
				}
				SetMenuExitButton(menu, true);
				DisplayMenu(menu, client, 20);
			}
			else
			{
				CPrintToChat(client, "%t", "KickFailedPublic");
			}
		}
		else
		{
			CPrintToChat(client, "%t", "KickFailedPermission");
		}
	}
	return Plugin_Handled;
}

public Action:VCInviteGui(client, args)
{
	PrintToConsole(client, "inv ch");
	new cvar_vc_invite_enable = GetConVarInt(vc_invite_enable);
	new cvar_vc_invite_admin_only = GetConVarInt(vc_invite_admin_only);
	new cvar_vc_invite_max = GetConVarInt(vc_invite_max);
	new cvar_vc_invite_public_only = GetConVarInt(vc_invite_public_only);
	new cvar_vc_invite_admins = GetConVarInt(vc_invite_admins);
	
	if(0 < client < MaxClients)
	{
		if(cvar_vc_invite_enable == 1)
		{
			decl String:szText[254];
			new i_counter;
			
			if((cvar_vc_invite_admin_only == 0 && (g_iClientInvites[client] > 0 || cvar_vc_invite_max == 0)) || Client_IsAdmin(client))
			{
				new Handle:menu = CreateMenu(MenuInviteChannel);
				SetMenuTitle(menu, "Invite a player into your channel [current: %s]", g_sChannelsName[g_iClientChannel[client]]);
				
				decl String:buffer[5];
				for (new i=1;i<=MAXPLAYERS;i++)
				{
					new bool:addtomenu = false;
					if(Client_IsIngame(i) && i != client)
					{
						//Allow admins to invite anyone
						if(Client_IsAdmin(client))
						{
							addtomenu = true;
						}
						//Can non-admins invite anyone
						else if(cvar_vc_invite_public_only == 0)
						{
							addtomenu = true;
							
						}
						//Can non-admins invite from default channel
						else if(cvar_vc_invite_public_only == 1)
						{
							if(g_iClientChannel[i] == GetFirstPublicChannel())
							{
								addtomenu = true;
							}
						}
						//Can non-admins invite from public channels
						else if(cvar_vc_invite_public_only == 2)
						{
							if(g_iChannelsMode[g_iClientChannel[i]] == CHMODE_PUBLIC)
							{
								addtomenu = true;
							}
						}
						
						//Is client allowed to invite admins?
						if(cvar_vc_invite_admins == 0)
						{
							if(Client_IsAdmin(i) && !Client_IsAdmin(client))
							{
								addtomenu = false;
							}
						}
					}
					
					//If client is allowed to invite show target
					if(addtomenu)
					{
						i_counter++;
						Format(szText, sizeof(szText), "%N", i);
						IntToString(i, buffer, sizeof(buffer));
						AddMenuItem(menu, buffer, szText);
					}
						
				}
				//If there is no target to invite
				if(i_counter < 1)
				{
					Format(szText, sizeof(szText), "Sorry, no other players found!");
					IntToString(NO_CHANNEL, buffer, sizeof(buffer));
					AddMenuItem(menu, buffer, szText);
				}
				SetMenuExitButton(menu, true);
				DisplayMenu(menu, client, 20);
			}
			//Remember if client has no invites left
			else
			{
				CPrintToChat(client, "%t", "NoInvitesLeft", cvar_vc_invite_max);
			}
		}
	}
	return Plugin_Handled;
}

public Action:CmdSay(client, args)
{
	new cvar_vc_store_channel = GetConVarInt(vc_store_channel);
	
	if(0 < client < MaxClients)
	{
		decl String:text[128];
		decl String:name[MAX_NAME_LENGTH+1];
		
		GetClientName(client, name, sizeof(name));
		GetCmdArgString(text, sizeof(text));
		
		// bug fix
		ReplaceString(text, sizeof(text), "\"", "");
		
		if (g_iClientChTryPw[client] == 1)
		{
			if(StrEqual(text, g_sChannelsPass[g_iClientChTryPrivate[client]]))
			{
				if(g_iClientChannel[client] != g_iClientChTryPrivate[client])
				{
					CPrintToChatAll("%t", "ChangeChannel", name, g_sChannelsName[g_iClientChTryPrivate[client]]);
					
					g_iClientChannel[client] = g_iClientChTryPrivate[client];
					RefreshClientChannel(client);
					if(cvar_vc_store_channel == 1)
					{
						SaveSettings(client);
					}
				}
				else
				{
					CPrintToChat(client, "%t", "AlreadyIn");
				}
			}
			else
			{
				CPrintToChat(client, "%t", "PasswordIncorrect");
			}
			g_iClientChTryPw[client] = 0;
			g_iClientChTryPrivate[client] = 0;
			return Plugin_Handled;	
		}
	}
	return Plugin_Continue;
}

public MenuKickChannel(Handle:menu, MenuAction:action, client, param2)
{
	if ( action == MenuAction_Select ) 
	{
		new first_pub_ch = GetFirstPublicChannel();
	
		decl String:info[5];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new target = StringToInt(info);
		
		decl String:clientname[64];
		GetClientName(client, clientname, sizeof(clientname));
		
		decl String:targetname[64];
		GetClientName(target, targetname, sizeof(targetname));
		
		if(target > NO_CHANNEL)
		{
			g_iClientChannel[target]=first_pub_ch;
			RefreshClientChannel(target);
			CPrintToChatAll("%t", "KickedOutOfChannel", targetname, g_sChannelsName[g_iClientChannel[client]], clientname);
		}
	}
}

public MenuChooseChannel(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new cvar_vc_admin_ignore_channel_pw = GetConVarInt(vc_admin_ignore_channel_pw);
		new cvar_vc_store_channel = GetConVarInt(vc_store_channel);
		decl String:info[5];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new chnl = StringToInt(info);
		if (chnl > NO_CHANNEL)
		{
			if (g_iChannelsMode[chnl] == CHMODE_ADMIN)
			{
				new AdminId:admin;
				if ((admin = GetUserAdmin(client)) == INVALID_ADMIN_ID)
				{
					CPrintToChat(client, "%t", "AdminsOnly");
					return;
				}
				else
				{
					new AdminFlag:flag;
					FindFlagByName(g_sChannelsFlag[chnl], flag);
					
					if (!GetAdminFlag(admin, flag))
					{
						CPrintToChat(client, "%t", "InvalidFlag", g_sChannelsFlag[chnl]);
						return;
					}
				}
			}
			else if (g_iChannelsMode[chnl] == CHMODE_PRIVATE)
			{
				if(cvar_vc_admin_ignore_channel_pw == 1 && Client_IsAdmin(client))
				{	
					g_iClientChannel[client] = chnl;
					RefreshClientChannel(client);
				}
				else
				{
					g_iClientChTryPrivate[client] = chnl;
					g_iClientChTryPw[client] = 1;
					CPrintToChat(client, "%t", "Private1");
				}
				return;
			}
			
			decl String:name[64];
			GetClientName(client, name, sizeof(name));
			
			if(g_iClientChannel[client] != chnl)
			{
				CPrintToChatAll("%t", "ChangeChannel", name, g_sChannelsName[chnl]);
			}
			g_iClientChannel[client] = chnl;
			RefreshClientChannel(client);
			if(cvar_vc_store_channel == 1)
			{
				SaveSettings(client);
			}
		}
	}
}

public MenuInviteChannel(Handle:menu, MenuAction:action, client, param2)
{
	if ( action == MenuAction_Select ) 
	{
		new cvar_vc_invite_max = GetConVarInt(vc_invite_max);
		decl String:info[5];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new target = StringToInt(info);
		new chnl = g_iClientChannel[client];
		
		if(target > NO_CHANNEL)
		{
			if(cvar_vc_invite_max > 0)
			{
				g_iClientInvites[client]--;
			}
			new Handle:menu2 = CreateMenu(MenuInvitedChannel);
			SetMenuTitle(menu2, "%N invited you to join %s voice channel:", client, g_sChannelsName[chnl]);
			
			decl String:buffer[5];
			IntToString(chnl, buffer, sizeof(buffer));
			AddMenuItem(menu2, buffer, "Change");
			IntToString(NO_CHANNEL, buffer, sizeof(buffer));
			AddMenuItem(menu2, buffer, "Stay");
			SetMenuExitButton(menu, true);
			DisplayMenu(menu2, target, 20);
		}
	}
}

public MenuInvitedChannel(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new cvar_vc_store_channel = GetConVarInt(vc_store_channel);
		decl String:info[5];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new chnl = StringToInt(info);
		if (chnl > NO_CHANNEL)
		{
			decl String:name[64];
			GetClientName(client, name, sizeof(name));
			
			if(g_iClientChannel[client] != chnl)
			{
				CPrintToChatAll("%t", "ChangeChannel", name, g_sChannelsName[chnl]);
			}
			g_iClientChannel[client] = chnl;
			RefreshClientChannel(client);
			if(cvar_vc_store_channel == 1)
			{
				SaveSettings(client);
			}
		}
	}
}

public Action:Timer_UpdateHudHint(Handle:timer, any:client)
{
	if(g_iChannelsShowHUD[g_iClientChannel[client]] == HUD_DISABLED)
	{
		//Don't show HUD
	}
	else if (0 < client < MaxClients)
	{
		//Show HUD
		ClientUpdateHUD(client);
	}
	return Plugin_Continue;
}

stock RefreshClientChannel(client)
{
	new cvar_vc_announcer_channel_id = GetConVarInt(vc_announcer_channel_id);
	new cvar_vc_announcer_mode = GetConVarInt(vc_announcer_mode);
	
	if(0 < client < MaxClients)
	{
		new chp_count[g_iChannels];
		
		for (new i=1; i<=MaxClients; i++)
		{
			if (0 < i < MaxClients && IsClientInGame(i))
			{
				//Check External Influences
				new bool:cSpeakAll,iSpeakAll;
				new bool:cListen, iListen;
				new bool:cListenAll, iListenAll;
				new bool:cMuted, iMuted;

				//check announcer channel
				if(cvar_vc_announcer_channel_id > NO_CHANNEL)
				{
					//client speak All?
					if(g_iClientChannel[client] == cvar_vc_announcer_channel_id)
						cSpeakAll = true;
					
					//i speak all
					if(g_iClientChannel[i] == cvar_vc_announcer_channel_id)
						iSpeakAll = true;
				}
				
				//default announcer mode 
				if(cvar_vc_announcer_mode == ANNOUNCERMODE_SPEAK)
				{
					//Do nothing...
				}
				//mute everyone outside
				else if(cvar_vc_announcer_mode == ANNOUNCERMODE_MUTE)
				{
					if(iSpeakAll && !cSpeakAll)
						cMuted = true;
					
					if(cSpeakAll && !iSpeakAll)
						iMuted = true;
				}
				//listen to everyone
				else if(cvar_vc_announcer_mode == ANNOUNCERMODE_LISTEN)
				{
					if(cSpeakAll)
						cListenAll = true;
					
					if(iSpeakAll)
						iListenAll = true;
				}
				
				//Count Clients
				chp_count[g_iClientChannel[i]]++;
				
				//Share A Channel?
				if (g_iClientChannel[client] == g_iClientChannel[i])
				{
					
					//Team Channel
					if (g_iChannelsTeams[g_iClientChannel[client]])				
					{
						//Same Team?
						if (GetClientTeam(client) == GetClientTeam(i))
						{
							cListen = true;
							iListen = true;
						}
					}
					//No Team Channel
					else
					{
						cListen = true;
						iListen = true;
					}
				}
				
				//Set Listen Override
				if(client != i)
				{
					//Client Listen Override
					if((cListen || cListenAll || iSpeakAll) && !iMuted)
					{
						SetListenOverride(client, i, Listen_Yes);
					}
					else
					{
						SetListenOverride(client, i, Listen_No);
					}
					
					//i Listen Override
					if((iListen || iListenAll || cSpeakAll) && !cMuted)
					{
						SetListenOverride(i, client, Listen_Yes);
					}
					else
					{
						SetListenOverride(i, client, Listen_No);
					}
				}
			}
		}
		
		//Save Player Counts
		for (new i=0;i<g_iChannels;i++)
		{
			
			g_iChannelsCount[i] = chp_count[i];
		}
	}
}

LoadSettings(client)
{
	decl Handle:kv;
	decl String:cName[MAX_NAME_LENGTH];
	if(0 < client < MaxClients)
	{
		kv = CreateKeyValues("Settings");
		FileToKeyValues(kv, SavePath);
		GetClientAuthString(client, cName, sizeof(cName));
		KvJumpToKey(kv, cName, true);
		//Restore last channel visited
		g_iClientChannel[client] = KvGetNum(kv, "channelid", NO_CHANNEL);
		CloseHandle(kv);
	}
}

SaveSettings(client)
{
	decl Handle:kv;
	decl String:cName[MAX_NAME_LENGTH];
	if(0 < client < MaxClients)
	{
		kv = CreateKeyValues("Settings");
		FileToKeyValues(kv, SavePath);
		GetClientAuthString(client, cName, sizeof(cName));
		KvJumpToKey(kv, cName, true);
		//Save current channel id
		KvSetNum(kv, "channelid", g_iClientChannel[client]);
		KvRewind(kv);
		KeyValuesToFile(kv, SavePath);
		CloseHandle(kv);
	}
}

GetFirstPublicChannel()
{
	new cvar_vc_public_channel_id = GetConVarInt(vc_public_channel_id);
	//Is there a configured public channel id?
	if(cvar_vc_public_channel_id >= 0)
	{
		return cvar_vc_public_channel_id;
	}
	//Get first public channel
	else
	{
		for (new i=0;i<=g_iChannels;i++)
		{
			if (g_iChannelsMode[i] != CHMODE_PUBLIC)
			{
				continue;
			}
			else
			{
				return i;
			}
		}
	}
	return NO_CHANNEL;
}

CreateHudHintTimer(client)
{
	cvar_vc_hud_update_interval = GetConVarFloat(vc_hud_update_interval);
	HudHintTimers[client] = CreateTimer(cvar_vc_hud_update_interval, Timer_UpdateHudHint, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

KillHudHintTimer(client)
{
	if (HudHintTimers[client] != INVALID_HANDLE)
	{
		KillTimer(HudHintTimers[client]);
		HudHintTimers[client] = INVALID_HANDLE;
	}
}

ClientUpdateHUD(client)
{
	new cvar_vc_hud_show_public_all = GetConVarInt(vc_hud_show_public_all);
	new cvar_vc_hud_show_player_count = GetConVarInt(vc_hud_show_player_count);
	new cvar_vc_hud_show_team = GetConVarInt(vc_hud_show_team);
	new cvar_vc_hud_show_status = GetConVarInt(vc_hud_show_status);
	new cvar_vc_hud_show_self = GetConVarInt(vc_hud_show_self);
	new cvar_vc_hud_show_channel_cmd = GetConVarInt(vc_hud_show_channel_cmd);
	new cvar_vc_invite_enable = GetConVarInt(vc_invite_enable);
	new cvar_vc_invite_max = GetConVarInt(vc_invite_max);
	new cvar_vc_hud_show_invite_cmd = GetConVarInt(vc_hud_show_invite_cmd);
	new cvar_vc_hud_show_invites = GetConVarInt(vc_hud_show_invites);
	decl String:szText[254];
	szText[0] = '\0';
	
	//Show spectator list
	if(g_iChannelsShowHUD[g_iClientChannel[client]] == HUD_SPECTATOR)
	{
		new iSpecModeUser = GetEntProp(client, Prop_Send, "m_iObserverMode");
		new iSpecMode, iTarget, iTargetUser;
		new bool:bDisplayHint = false;
		// Dealing with a client who is in the game and playing.
		if (IsPlayerAlive(client))
		{
			for(new i = 1; i <= MaxClients; i++) 
			{
				if (!IsClientInGame(i) || !IsClientObserver(i))
					continue;
					
				iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
				
				// The client isn't spectating any one person, so ignore them.
				if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
					continue;
				
				// Find out who the client is spectating.
				iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				
				// Are they spectating our player?
				if (iTarget == client)
				{
					Format(szText, sizeof(szText), "%s%N\n", szText, i);
					bDisplayHint = true;
				}
			}
		}
		else if (iSpecModeUser == SPECMODE_FIRSTPERSON || iSpecModeUser == SPECMODE_3RDPERSON)
		{
			// Find out who the User is spectating.
			iTargetUser = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			
			if (iTargetUser > 0)
				Format(szText, sizeof(szText), "Spectating %N:\n", iTargetUser);
			
			for(new i = 1; i <= MaxClients; i++) 
			{
				if (!IsClientInGame(i) || !IsClientObserver(i))
					continue;
					
				iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
				
				// The client isn't spectating any one person, so ignore them.
				if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
					continue;
				
				// Find out who the client is spectating.
				iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				
				// Are they spectating the same player as User?
				if (iTarget == iTargetUser)
					Format(szText, sizeof(szText), "%s%N\n", szText, i);
			}
		}
		
		/* We do this to prevent displaying a message
			to a player if no one is spectating them anyway. */
		if (bDisplayHint)
		{
			Format(szText, sizeof(szText), "Spectating %N:\n%s", client, szText);
			bDisplayHint = false;
		}
	}
	//Show all
	else if(g_iChannelsShowHUD[g_iClientChannel[client]] == HUD_CHANNEL_ALL)
	{
		Format(szText, sizeof(szText), "Player-channel list:\n\n");
		for (new i=0;i<=g_iChannels;i++)
		{
			if(g_iChannelsCount[i] > 0 || cvar_vc_hud_show_public_all == 2)
			{
				if(cvar_vc_hud_show_player_count == 1)
				{
					Format(szText, sizeof(szText), "%s%s: %d online\n", szText, g_sChannelsName[i], g_iChannelsCount[i]);
				}
				else
				{
					Format(szText, sizeof(szText), "%s%s:\n", szText, g_sChannelsName[i]);
				}
				for(new j = 1; j <= MaxClients; j++) 
				{
					if (IsClientInGame(j))
					{
						//Same channel?
						if(g_iClientChannel[j] == i)
						{
							Format(szText, sizeof(szText), "%s- ", szText);
							if(cvar_vc_hud_show_team == 1)
							{
								new team_j = GetClientTeam(j);
								if(team_j == 1)
								{
									Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_1);
								}
								else if(team_j == 2)
								{
									Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_2);
								}
								else if(team_j == 3)
								{
									Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_3);
								}
							}
							if(cvar_vc_hud_show_team == 2 && g_iChannelsTeams[g_iClientChannel[j]] == 1)
							{
								new team_j = GetClientTeam(j);
								if(team_j == 1)
								{
									Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_1);
								}
								else if(team_j == 2)
								{
									Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_2);
								}
								else if(team_j == 3)
								{
									Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_3);
								}
							}
							if(cvar_vc_hud_show_status == 1)
							{
								if(GetClientTeam(j) <= 1)
								{
									if(IsPlayerAlive(j))
									{
										Format(szText, sizeof(szText), "%s%N%s\n", szText, j, cvar_vc_hud_status_tag_alive);
									}
									else
									{
										Format(szText, sizeof(szText), "%s%N%s\n", szText, j, cvar_vc_hud_status_tag_dead);
									}
								}
								else
								{
									Format(szText, sizeof(szText), "%s%N\n", szText, j);
								}
							}
							else
							{
								Format(szText, sizeof(szText), "%s%N\n", szText, j);
							}
						}
					}
				}
			}
		}
	}
	//Show channel
	else if(g_iChannelsShowHUD[g_iClientChannel[client]] == HUD_CHANNEL)
	{
		if(cvar_vc_hud_show_player_count == 1)
		{
			Format(szText, sizeof(szText), "%s: %d(%d) online\n\n", g_sChannelsName[g_iClientChannel[client]], (g_iChannelsCount[g_iClientChannel[client]]-1), g_iChannelsCount[g_iClientChannel[client]]);
		}
		else
		{
			Format(szText, sizeof(szText), "%s:\n\n", g_sChannelsName[g_iClientChannel[client]]);
		}
	
		for(new i = 1; i <= MaxClients; i++) 
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
		
			if(g_iClientChannel[client] != g_iClientChannel[i])
			{
				continue;
			}
		
			if (cvar_vc_hud_show_self != 1 && i == client)
			{
				continue;
			}
			
			//Show team tags
			if(cvar_vc_hud_show_team > 0)
			{
				new team_i = GetClientTeam(i);
				
				//All Channel
				if(cvar_vc_hud_show_team == 1)
				{
					if(team_i == 1)
					{
						Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_1);
					}
					else if(team_i == 2)
					{
						Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_2);
					}
					else if(team_i == 3)
					{
						Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_3);
					}
				}
				//Only Teamchannel
				else if(cvar_vc_hud_show_team == 2 && g_iChannelsTeams[g_iClientChannel[i]] == 1)
				{
					if(team_i == 1)
					{
						Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_1);
					}
					else if(team_i == 2)
					{
						Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_2);
					}
					else if(team_i == 3)
					{
						Format(szText, sizeof(szText), "%s%s", szText, cvar_vc_hud_team_tag_3);
					}
				}
			}
			
			//Show status tags and player name
			if(cvar_vc_hud_show_status == 1)
			{
				if(GetClientTeam(i) > 1)
				{
					if(IsPlayerAlive(i))
					{
						Format(szText, sizeof(szText), "%s%N%s\n", szText, i, cvar_vc_hud_status_tag_alive);
					}
					else
					{
						Format(szText, sizeof(szText), "%s%N%s\n", szText, i, cvar_vc_hud_status_tag_dead);
					}
				}
				else
				{
					Format(szText, sizeof(szText), "%s%N\n", szText, i);
				}
			}
			else
			{
				Format(szText, sizeof(szText), "%s%N\n", szText, i);
			}
		}
	}
		
	//display channel choose menu command?
	if((g_iClientChannel[client] == GetFirstPublicChannel() && cvar_vc_hud_show_channel_cmd == 2) || cvar_vc_hud_show_channel_cmd == 1)
	{
		Format(szText, sizeof(szText), "%s\nType !vc to change your voice channel", szText);
	}
	
	//display invite command?
	if(cvar_vc_invite_enable  == 1)
	{
		if((g_iChannelsCount[0] > 0 && cvar_vc_hud_show_invite_cmd == 2) || cvar_vc_hud_show_invite_cmd == 1)
		{
			Format(szText, sizeof(szText), "%s\nType !vci to invite other players", szText);
		}
	}
	
	//display invites left?
	if(!Client_IsAdmin(client) && cvar_vc_hud_show_invites == 1 && cvar_vc_invite_max > 0)
	{
		Format(szText, sizeof(szText), "%s\nYou have %d invites left this map", szText, g_iClientInvites[client]);
	}
	
	//Send our message
	new Handle:hBuffer = StartMessageOne("KeyHintText", client); 
	BfWriteByte(hBuffer, 1); 
	BfWriteString(hBuffer, szText); 
	EndMessage();
}