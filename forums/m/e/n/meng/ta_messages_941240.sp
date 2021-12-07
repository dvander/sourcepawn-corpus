#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.7"

public Plugin:myinfo = 
{
	name = "ta_messages",
	author = "meng",
	version = "PLUGIN_VERSION",
	description = "team attack messages",
	url = ""
};

new UserMsg:g_textmsg;

public OnPluginStart()
{
	g_textmsg = GetUserMessageId("TextMsg");
	HookUserMessage(g_textmsg, UserMessageHook, true);
	HookEvent("player_hurt", EventPlayerHurt);
}

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:message[256];
	BfReadString(bf, message, sizeof(message));
	if (StrContains(message, "teammate_attack") != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker && attacker != victim)
	{
		new victimteam = GetClientTeam(victim);
		new attackerteam = GetClientTeam(attacker);
		if (victimteam == attackerteam)
		{
			new damage = GetEventInt(event, "dmg_health");
			decl String:victimname[64];
			GetClientName(victim, victimname, sizeof(victimname));
			decl String:attackername[64];
			GetClientName(attacker, attackername, sizeof(attackername));
			PrintToChatAll("\x03%s\x04 attacked teammate \x03%s\x04. (\x03%d \x04damage)", attackername, victimname, damage);
		}
	}
}