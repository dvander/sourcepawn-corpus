#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>
#include <regex>
#undef REQUIRE_PLUGIN
#tryinclude <sourceirc>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.8"

#define	dChat					(1 << 0)	//	1
#define	dCenter					(1 << 1)	//	2
#define	dHint					(1 << 2)	//	4
#define	dServer					(1 << 3)	//	8
#define	dHud					(1 << 4)	//	16
#define	dSound					(1 << 5)	//	32
#define	dSourceIRC				(1 << 6)	//	64

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled;
new Handle:g_hCvarHex;
new Handle:g_hCvarSpecial;
new Handle:g_hCvarSound;
new Handle:g_hRegexHex;
new Handle:g_hHudSynchronizer;

// ====[ VARIABLES ]===========================================================
new g_iEnabled;
new String:g_strHex[12];
new String:g_strSpecial[255];
new String:g_strSound[255];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Admin Connect Message (Extended)",
	author = "ReFlexPoison",
	description = "Post connecting admins and special players through hud and say commands",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=183966"
}

// ====[ FUNCTIONS ]===========================================================
public OnPluginStart()
{
	CreateConVar("sm_adminconmsg_version", PLUGIN_VERSION, "Admin Connect Message (Extended) Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_adminconmsg_enabled", "127", "Enable Admin Connect Message (Extended) (Add up values)\n0 = Disabled\n1 = Chat\n2 = Center\n4 = Hint\n8 = Server\n16 = Hud\n32 = Sound\n64 = SourceIRC", FCVAR_NONE, true, 0.0, true, 127.0);
	g_iEnabled = GetConVarInt(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarHex = CreateConVar("sm_adminconmsg_hex", "#FF7700", "Hexadecimal value to use for custom chat color", FCVAR_NONE);
	GetConVarString(g_hCvarHex, g_strHex, sizeof(g_strHex));
	HookConVarChange(g_hCvarHex, OnConVarChange);

	g_hCvarSpecial = CreateConVar("sm_adminconmsg_special", "Donor", "What to call special players (Leave blank to disable notifications of special players)", FCVAR_NONE);
	GetConVarString(g_hCvarSpecial, g_strSpecial, sizeof(g_strSpecial));
	HookConVarChange(g_hCvarSpecial, OnConVarChange);

	g_hCvarSound = CreateConVar("sm_adminconmsg_sound", "adminconmsg/play.mp3", "Sound to play when a special player connects", FCVAR_NONE);
	GetConVarString(g_hCvarSound, g_strSound, sizeof(g_strSound));
	HookConVarChange(g_hCvarSound, OnConVarChange);

	AutoExecConfig(true, "plugin.adminconmsg");

	g_hRegexHex = CompileRegex("([A-Fa-f0-9]{6})");

	decl String:strGame[16];
	GetGameFolderName(strGame, sizeof(strGame));
	if(StrEqual(strGame, "tf") || StrEqual(strGame, "hl2mp"))
		g_hHudSynchronizer = CreateHudSynchronizer();
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
		g_iEnabled = GetConVarInt(g_hCvarEnabled);
	if(hConvar == g_hCvarHex)
		GetConVarString(g_hCvarHex, g_strHex, sizeof(g_strHex));
	if(hConvar == g_hCvarSpecial)
		GetConVarString(g_hCvarSpecial, g_strSpecial, sizeof(g_strSpecial));
	if(hConvar == g_hCvarSound)
		OnConfigsExecuted();
}

public OnConfigsExecuted()
{
	GetConVarString(g_hCvarSound, g_strSound, sizeof(g_strSound));
	decl String:strBuffer[PLATFORM_MAX_PATH];
	PrecacheSound(g_strSound, true);
	Format(strBuffer, sizeof(strBuffer), "sound/%s", g_strSound);
	AddFileToDownloadsTable(strBuffer);
}

public OnClientPostAdminCheck(iClient)
{
	if(g_iEnabled <= 0)
		return;

	new bool:bAdmin = CheckCommandAccess(iClient, "adminconmsg_admin_flag", ADMFLAG_GENERIC);
	new bool:bSpecial = CheckCommandAccess(iClient, "adminconmsg_special_flag", ADMFLAG_RESERVATION);
	if(bAdmin || (g_strSpecial[0] != '\0' && bSpecial))
	{
		decl String:strType[255];
		if(bAdmin)
			strcopy(strType, sizeof(strType), "Admin");
		else
			strcopy(strType, sizeof(strType), g_strSpecial);

		if(g_iEnabled & dChat)
		{
			decl String:strHex[16];
			strcopy(strHex, sizeof(strHex), g_strHex);
			ReplaceString(strHex, sizeof(strHex), "#", "", false);
			if(IsValidHex(strHex))
				PrintToChatAll("\x07%s%s %N Connected", strHex, strType, iClient);
			else
				ThrowError("(%s) not a valid hexadecimal value", strHex);
		}
		if(g_iEnabled & dCenter)
			PrintCenterTextAll("%s %N Connected", strType, iClient);
		if(g_iEnabled & dHud && g_hHudSynchronizer != INVALID_HANDLE)
		{
			SetHudTextParams(-1.0, 0.3, 7.5, 255, 255, 255, 255);
			for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
				ShowSyncHudText(i, g_hHudSynchronizer, "%s %N Connected", strType, iClient);
		}
		if(g_iEnabled & dHint)
			PrintHintTextToAll("%s %N Connected", strType, iClient);
		if(g_iEnabled & dServer)
			PrintToServer("%s %N Connected", strType, iClient);
		if(g_iEnabled & dSound)
			EmitSoundToAll(g_strSound);
		#if defined IRC_VERSION
		if(g_iEnabled & dSourceIRC)
			IRC_MsgFlaggedChannels("ticket", "%s %N Connected", strType, iClient);
		#endif
	}
}

// ====[ STOCKS ]==============================================================
stock IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock bool:IsValidHex(const String:strBuffer[])
{
	if(MatchRegex(g_hRegexHex, strBuffer))
		return true;
	return false;
}