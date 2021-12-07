#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION   "1.0"

#define HIDE (0x0001 | 0x0010)
#define SHOW (0x0002)
#define FLASH_ALPHA 0.5

new Handle:g_colfEna = INVALID_HANDLE;
new g_iDuration;
new g_iFlashMaxAlpha;

public Plugin:myinfo = {
    name = "Colored Flash",
    author = "iDragon",
    description = "This plugin changes the Flashbangs color.",
    version = PLUGIN_VERSION,
    url = "http://www.pro-css.co.il/"
};

public OnPluginStart() {

	g_colfEna = CreateConVar("sm_cf_enabled", "1", "Enable colored flash plugin?");
	
	g_iDuration = FindSendPropOffs("CCSPlayer", "m_flFlashDuration");
	if (g_iDuration == -1)
		SetFailState("[Colored_flashbangs] Failed to get offset for CCSPlayer::m_flFlashDuration.");
	
	g_iFlashMaxAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	if (g_iFlashMaxAlpha == -1)
		SetFailState("[Colored_flashbangs] Failed to get offset for CCSPlayer::m_flFlashMaxAlpha.");
	
	HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
	
	PrintToChatAll("\x04Colored Flashbangs\x03 Loaded.");
}

public OnPluginEnd()
{
	PrintToChatAll("\x04Colored Flashbangs\x03 Un-Loaded.");
}

public Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_colfEna))
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"))
		
		new colf_red = GetRandomInt(0, 255);
		new colf_green = GetRandomInt(0, 255);
		new colf_blue = GetRandomInt(0, 255);
		new flash_duration = GetEntData(client, g_iDuration, 4);

		SetEntDataFloat(client,g_iFlashMaxAlpha,FLASH_ALPHA);
		
		new Handle:msg;
	
		msg = StartMessageOne("Fade", client);
		BfWriteShort(msg, 100);
		BfWriteShort(msg, flash_duration);
		BfWriteShort(msg, SHOW);
		BfWriteByte(msg, colf_red);
		BfWriteByte(msg, colf_green);
		BfWriteByte(msg, colf_blue);
		BfWriteByte(msg, 255);
		EndMessage();
		
		CreateTimer(flash_duration, BackToNormal, client);
	}
}

public Action:BackToNormal(Handle:timer, any:client)
{
		new Handle:msg;
		
		msg = StartMessageOne("Fade", client);
		BfWriteShort(msg, 100);
		BfWriteShort(msg, 0);
		BfWriteShort(msg, HIDE);
		BfWriteByte(msg, 0);
		BfWriteByte(msg, 0);
		BfWriteByte(msg, 0);
		BfWriteByte(msg, 255);
		EndMessage();
}