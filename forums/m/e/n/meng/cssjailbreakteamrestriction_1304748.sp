#include <sourcemod>

#define NAME "CSS Jail Break Team Restriction"
#define VERSION "0.70"

new Handle:g_hListed;

public Plugin:myinfo = {

	name = NAME,
	author = "meng",
	description = "Prevents a player from joining the ct team.",
	version = VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart() {

	CreateConVar("sm_cssjbteamrestriction", VERSION, NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	g_hListed = CreateArray(128);
	AddCommandListener(CmdJoinTeam, "jointeam");
	RegAdminCmd("sm_jbtr", CmdJBTR, ADMFLAG_KICK);
}

public Action:CmdJoinTeam(client, const String:command[], argc) {

	static String:sCmdArg[64];
	GetCmdArgString(sCmdArg, sizeof(sCmdArg));
	StripQuotes(sCmdArg);
	TrimString(sCmdArg);
	if (StringToInt(sCmdArg) == 3) {
		decl String:sAuthID[32];
		GetClientAuthString(client, sAuthID, sizeof(sAuthID));
		if (FindStringInArray(g_hListed, sAuthID) != -1) {
			PrintToChat(client, "You are currently restricted from joining the CT team.");
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:CmdJBTR(client, args) {

	if (!args)
		ReplyToCommand(client, "[SM-JBTR] Usage: sm_jbtr <#userid|name>");
	else {
		decl String:sBuffer[128];
		GetCmdArgString(sBuffer, sizeof(sBuffer));
		new target = FindTarget(client, sBuffer);
		if (target == -1)
			ReplyToCommand(client, "[SM-JBTR] Player ( %s ) not found.", sBuffer);
		else {
			new arrayIndex;
			GetClientAuthString(target, sBuffer, sizeof(sBuffer));
			if ((arrayIndex = FindStringInArray(g_hListed, sBuffer)) != -1) {
				RemoveFromArray(g_hListed, arrayIndex);
				ReplyToCommand(client, "[SM-JBTR] Player ( %N ) unrestricted.", target);
			}
			else {
				PushArrayString(g_hListed, sBuffer);
				ReplyToCommand(client, "[SM-JBTR] Player ( %N ) restricted.", target);
				if (GetClientTeam(target) == 3)
					ChangeClientTeam(target, 2);
			}
		}
	}

	return Plugin_Handled;
}