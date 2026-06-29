#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define PLUGIN_VERSION "1.2"
#define CVAR_FLAGS FCVAR_NOTIFY

/**
 * Plugin history:
 * ---------------------------
 *
 * v1.2:
 * - blocking new votes if old one is still active
 * - trying to kick the banned one again after 15 seconds
 *
 * v1.1:
 * - added version cvar
 * - output will display cvar sv_vote_kick_ban_duration 
 * - the check timer is now using the value of sv_vote_timer_duration
 *
 */

public Plugin myinfo =
{
	name = "Votekick Escape Ban",
	author = "Die Teetasse",
	description = "This plugins will ban a player who disconnects before the votekick ended.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1250229"
};

PluginData plugin;

enum struct PluginCvars
{
    ConVar hCvarPluginOn;
    ConVar hCvarBanTime;

    void Init()
    {
        CreateConVar("l4d2_votekickban_version", PLUGIN_VERSION, "Votekick Escape Ban - Version", CVAR_FLAGS|FCVAR_DONTRECORD);
        this.hCvarPluginOn = CreateConVar("l4d2_votekickban_on", "1", "Votekick Escape Ban Plugin On/Off", CVAR_FLAGS);
        this.hCvarBanTime = CreateConVar("l4d2_votekickban_bantime", "15", "Votekick Escape Ban - Ban time for excapers in minutes. (0 = permanent)", CVAR_FLAGS);

        AutoExecConfig(true, "l4d2_votekickban");

        this.hCvarPluginOn.AddChangeHook(ConVarChanged_Allow);
        this.hCvarBanTime.AddChangeHook(ConVarChanged_Cvars);

        LoadTranslations("l4d2_assist.phrases");
    }
}

enum struct PluginData
{
    PluginCvars cvars;
    bool bHooked;
    bool bPluginOn;
    bool isVictimAlreadyBanned;
    bool isVoteKickActive;
    int iCvarBanTime;
    int votesNo;
    int votesYes;
    int iVoteBanDuration;
    char voteVictimName[MAX_NAME_LENGTH];
    char voteVictimSteamid[32];
    char voteCommand[32];
    char tempUserId[MAX_NAME_LENGTH];
    char cSteamId[64];
    char banSteamID[64];

    void Init()
    {
        this.cvars.Init();
        AddCommandListener(Cmd_CallVote, "callvote");
    }

    void GetCvarValues()
    {
        this.iCvarBanTime = this.cvars.hCvarBanTime.IntValue;
        this.iVoteBanDuration = FindConVar("sv_vote_kick_ban_duration").IntValue;
    }

    void IsAllowed()
    {
        this.bPluginOn = this.cvars.hCvarPluginOn.BoolValue;
        if(!this.bHooked && this.bPluginOn)
        {
            this.bHooked = true;
            HookEvent("vote_cast_yes", Events);
            HookEvent("vote_cast_no", Events);
            HookEvent("server_addban", Events);
        }
        else if(this.bHooked && !this.bPluginOn)
        {
            this.bHooked = false;
            UnhookEvent("vote_cast_yes", Events);
            UnhookEvent("vote_cast_no", Events);
            UnhookEvent("server_addban", Events);
        }
    }
}

public void OnPluginStart()
{	
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
	plugin.GetCvarValues();
}

void ConVarChanged_Allow(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
    plugin.GetCvarValues();
}

Action Cmd_CallVote(int client, const char[] command, int args)
{
    GetCmdArg(1, plugin.voteCommand, sizeof(plugin.voteCommand));
    //too prevent a new vote try messing the old one
    if (!plugin.isVoteKickActive)
    {
        plugin.isVoteKickActive = false;
        if (StrEqual(plugin.voteCommand, "Kick", false))
        {
            GetCmdArg(2, plugin.tempUserId, sizeof(plugin.tempUserId));

            int victimId = GetClientOfUserId(StringToInt(plugin.tempUserId));
            if (victimId > 0 && IsClientInGame(victimId) && !IsFakeClient(victimId))
            {
                GetClientName(victimId, plugin.voteVictimName, sizeof(plugin.voteVictimName));	
                GetClientAuthId(victimId, AuthId_Steam2, plugin.voteVictimSteamid, sizeof(plugin.voteVictimSteamid));
                plugin.votesNo = 0;
                plugin.votesYes = 0;
                plugin.isVoteKickActive = true;
                plugin.isVictimAlreadyBanned = false;
                PrintToChatAll("\x04[SM] \x03Votekick open for \x04%s. \x03Disconnecting will not help.", plugin.voteVictimName);
                CreateTimer(float(FindConVar("sv_vote_timer_duration").IntValue + 5), Timer_CallEnd, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
    return Plugin_Continue;
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
    if (strcmp(name, "vote_cast_yes") == 0)
    {
        if (plugin.isVoteKickActive)
        {
            plugin.votesYes++;
        }
    }
    else if (strcmp(name, "vote_cast_no") == 0)
    {
        if (plugin.isVoteKickActive)
        {
            plugin.votesNo++;
        }
    }
    else if (strcmp(name, "server_addban") == 0)
    {
        event.GetString("networkid", plugin.banSteamID, sizeof(plugin.banSteamID));
        if (StrEqual(plugin.banSteamID, plugin.voteVictimSteamid, false))
        {
            plugin.isVictimAlreadyBanned = true;
        }
    }
    return Plugin_Continue;
}

Action Timer_CallEnd(Handle timer)
{
    if (plugin.votesYes <= plugin.votesNo)
    {
        PrintToChatAll("\x04[SM] \x03Votekick against \x04%s \x03failed (\x04%d \x03Yes, \x04%d \x03No).", plugin.voteVictimName, plugin.votesYes, plugin.votesNo);
        return Plugin_Continue;
    }

    if (plugin.isVictimAlreadyBanned)
    {
        PrintToChatAll("\x04[SM] \x03Votekick against \x04%s \x03[%s] succeeded (\x04%d \x03Yes, \x04%d \x03No). Standard \x04%d \x03minute ban.", plugin.voteVictimName, plugin.voteVictimSteamid, plugin.votesYes, plugin.votesNo, plugin.iVoteBanDuration);
    }
    else 
    {
        //disconnected before. add x min ban.
        BanIdentity(plugin.voteVictimSteamid, plugin.iCvarBanTime, BANFLAG_AUTHID, "You got banned by vote!");
        PrintToChatAll("\x04[SM] \x03Votekick against \x03%s [%s] succeeded (\x04%d \x03Yes, \x04%d \x03No). Trying to escape: \x04%d \x03minute ban.", plugin.voteVictimName, plugin.voteVictimSteamid, plugin.votesYes, plugin.votesNo, plugin.iCvarBanTime);

        //kick if he maybe rejoined in time
        if (!KickClientBySteamId(plugin.voteVictimSteamid))
        {
            //try another kick in 15 seconds (slowloader -.-)
            ArrayStack tempSteamIdStack = new ArrayStack();
            tempSteamIdStack.PushString(plugin.voteVictimSteamid);
            CreateTimer(15.0, Timer_TryKickAgain, tempSteamIdStack);
        }
    }
    return Plugin_Continue;
}

Action Timer_TryKickAgain(Handle timer, ArrayStack tempSteamIdStack)
{
    tempSteamIdStack.PopString(plugin.cSteamId, sizeof(plugin.cSteamId));
    KickClientBySteamId(plugin.cSteamId);
    delete tempSteamIdStack;
    return Plugin_Stop;
}
		
//true if kick, false if not
stock bool KickClientBySteamId(const char[] steamId)
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientAuthId(i, AuthId_Steam2, plugin.cSteamId, sizeof(plugin.cSteamId));	
			if (StrEqual(steamId, plugin.cSteamId, false))
			{
				KickClient(i, "You got banned by vote!");
				return true;
			}
		}
	}	
	return false;
}
