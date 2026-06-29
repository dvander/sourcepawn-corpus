//////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Addon - Anti-VoiceCommandSpam
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <dodtms_base>

public Plugin:myinfo = 
{
	name = "[DoD TMS] Addon - Anti-VoiceCmdSpam",
	author = "FeuerSturm, modif Micmacx",
	description = "Anti-VoiceCmdSpam Addon for [DoD TMS]",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

#define MAXVOICECMDS 37

new Handle:AVCmdSON = INVALID_HANDLE
new Handle:ClientImmunity = INVALID_HANDLE
new Handle:AVCmdSCount = INVALID_HANDLE
new Handle:AVCmdSDelay = INVALID_HANDLE
new g_VoiceCount[MAXPLAYERS+1]
new Float:g_LastVoiceCmd[MAXPLAYERS+1]
new String:WLFeature[] = { "antivoicecmdspam" }
new bool:IsWhiteListed[MAXPLAYERS+1]
new bool:IsBlackListed[MAXPLAYERS+1]

new String:VoiceCmd[MAXVOICECMDS][]=
{
	"voice_attack", "voice_hold", "voice_left", "voice_right", "voice_sticktogether",
	"voice_cover", "voice_usesmoke", "voice_usegrens", "voice_ceasefire", "voice_yessir",
	"voice_negative", "voice_backup", "voice_fireinhole", "voice_grenade", "voice_sniper",
	"voice_niceshot", "voice_thanks", "voice_areaclear", "voice_dropweapons", "voice_displace",
	"voice_mgahead", "voice_enemybehind", "voice_wegothim", "voice_moveupmg", "voice_needammo",
	"voice_usebazooka", "voice_bazookaspotted", "voice_gogogo", "voice_wtf", "voice_medic",
	"voice_fireleft", "voice_fireright", "voice_coverflanks", "voice_cover", "voice_fallback",
	"voice_movewithtank", "voice_takeammo"
}

public OnPluginStart()
{
	for(new i = 0; i < MAXVOICECMDS; i++)
	{
		RegConsoleCmd(VoiceCmd[i], CheckVoiceCount)
	}
	AVCmdSON = CreateConVar("dod_tms_antivoicecmdspam", "1", "<1/0> = enable/disable preventing players from spamming VoiceCommands",_, true, 0.0, true, 1.0)
	ClientImmunity = CreateConVar("dod_tms_avcmdsimmunity", "1", "<1/0> = enable/disable Admins being immune from almost all actions",_, true, 0.0, true, 1.0)
	AVCmdSCount = CreateConVar("dod_tms_avcmdsmaxcount", "10", "<#> = maximum allowed VoiceCommands per Round  -  0 = no VoiceCmds allowed at all",_, true, 0.0)
	AVCmdSDelay = CreateConVar("dod_tms_avcmdsdelay", "5", "<#/0> = number of seconds after a VoiceCommand can be used again  -  0 = no limit", _, true, 0.0)
	LoadTranslations("dodtms_antivoicecmdspam.txt")
	AutoExecConfig(true,"addon_dodtms_antivcmds", "dod_teammanager_source")
}

public OnAllPluginsLoaded()
{
	CreateTimer(0.9, DoDTMSRunning)
}

public Action:DoDTMSRunning(Handle:timer)
{
	if(!LibraryExists("DoDTeamManagerSource"))
	{
		SetFailState("[DoD TMS] Base Plugin not found!")
		return Plugin_Handled
	}
	TMSRegAddon("I")
	return Plugin_Handled
}

public OnDoDTMSDeleteCfg()
{
	decl String:configfile[256]
	Format(configfile, sizeof(configfile), "cfg/dod_teammanager_source/addon_dodtms_antivcmds.cfg")
	if(FileExists(configfile))
	{
		DeleteFile(configfile)
	}
}

public OnClientPostAdminCheck(client)
{
	if(TMSIsWhiteListed(client, WLFeature))
	{
		IsWhiteListed[client] = true
	}
	else
	{
		IsWhiteListed[client] = false
	}
	if(TMSIsBlackListed(client, WLFeature))
	{
		IsBlackListed[client] = true
	}
	else
	{
		IsBlackListed[client] = false
	}
	g_VoiceCount[client] = 0
	g_LastVoiceCmd[client] = 0.0
}

public OnClientDisconnect(client)
{
	g_VoiceCount[client] = 0
	g_LastVoiceCmd[client] = 0.0
}

public OnDoDTMSRoundActive()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			g_VoiceCount[i] = 0
			g_LastVoiceCmd[i] = 0.0
		}
	}
}

public Action:CheckVoiceCount(client, args)
{
	if(GetConVarInt(AVCmdSON) == 0 || !IsPlayerAlive(client) || !IsClientInGame(client) || GetClientTeam(client) < ALLIES || IsClientImmune(client))
	{
		return Plugin_Continue
	}
	new delay = GetConVarInt(AVCmdSDelay)
	new maxvoicecmds = GetConVarInt(AVCmdSCount)
	if((GetGameTime() < g_LastVoiceCmd[client] + delay) && g_VoiceCount[client] != 0 && g_VoiceCount[client] < maxvoicecmds && delay != 0)
	{
		decl String:message[256]
		Format(message, sizeof(message), "%T", "TryAgainIn", client, RoundToCeil(g_LastVoiceCmd[client] + delay - GetGameTime()))
		TMSMessage(client, message)
		return Plugin_Handled
	}
	if(g_VoiceCount[client] >= GetConVarInt(AVCmdSCount))
	{
		decl String:message[256]
		Format(message, sizeof(message), "%T", "NoVoiceSpam", client)
		TMSMessage(client, message)
		return Plugin_Handled
	}
	g_VoiceCount[client]++
	g_LastVoiceCmd[client] = GetGameTime()
	return Plugin_Continue
}

stock bool:IsClientImmune(client)
{
	if((GetUserAdmin(client) != INVALID_ADMIN_ID || IsWhiteListed[client]) && !IsBlackListed[client] && GetConVarInt(ClientImmunity) == 1)
	{
		return true
	}
	else
	{
		return false
	}
}