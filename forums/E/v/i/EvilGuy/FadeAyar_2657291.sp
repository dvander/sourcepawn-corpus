#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Devil"
#define PLUGIN_VERSION "0.01"

#define FFADE_IN            (0x0001)        // Just here so we don't pass 0 into the function
#define FFADE_OUT           (0x0002)        // Fade out (not in)
#define FFADE_MODULATE      (0x0004)        // Modulate (don't blend)
#define FFADE_STAYOUT       (0x0008)        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE         (0x0010)        // Purges all other fades, replacing them with this one

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

new UserMsg:g_FadeUserMsgId;

public Plugin:myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

public OnPluginStart()
{
	HookEvent("player_spawn", spawn);
	g_FadeUserMsgId = GetUserMessageId("Fade");
	AddCommandListener(Listener_Voice, "voicemenu");
}
public Action:Listener_Voice(client, const String:command[], argc) {
	decl String:arguments[4];
	GetCmdArgString(arguments, sizeof(arguments));
	if (StrEqual(arguments, "0 0")) {
		if (GetClientTeam(client) == 3) {
			SetClientOverlay(client, "effects/combine_binocoverlay");
		}
	} else {
		SetClientOverlay(client, " ");
		return Plugin_Continue;
	}
}
public Action:spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client) == TFTeam_Blue) {
		PrintToChat(client, "\x07696969[ \x07A9A9A9ZF \x07696969]\x07CCCCCCPress 'e' to activate zombie vision");
		SetClientOverlay(client, " ");
	}
	else if (GetClientTeam(client) == TFTeam_Red) {
		SetClientOverlay(client, " ");
	}
}
SetClientOverlay(client, String:strOverlay[])
{
	new iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", iFlags);
	
	ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
}
BlindPlayer(client, iAmount)
{
	new iTargets[2];
	iTargets[0] = client;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, iTargets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if (iAmount == 0) {
		BfWriteShort(message, (0x0001 | 0x0010));
	} else {
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, iAmount);
	
	EndMessage();
} 