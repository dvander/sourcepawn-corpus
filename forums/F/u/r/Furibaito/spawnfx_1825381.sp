/*
 * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 * 
 *  SpawnEffects by Furibaito
 *
 *  spawnfx.sp - Source file
 *
 * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 */
 
#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"
#define DESC "Provides some visual effects on player spawn - Made by Furibaito" 

#define FFADE_IN 0x0001
#define FFADE_OUT 0x0002
#define FFADE_PURGE 0x0010

public Plugin:myinfo =
{
	name = "SpawnEffects",
	author = "Furibaito",
	description = DESC,
	version = PLUGIN_VERSION,
	url = "" 
};

// ConVars
new Handle:g_hEnable;
new Handle:g_hMode;
new Handle:g_hFadeColor;
new Handle:g_hFadeHold;
new Handle:g_hFadeLength;
new Handle:g_hShakeLength;
new Handle:g_hShakeAmplitude;

public OnPluginStart()
{
	// Version info
	CreateConVar("spawnfx_version", PLUGIN_VERSION, DESC, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	// Create ConVars
	g_hEnable = CreateConVar("spawnfx_enable", "1", "Enable/Disable this plugin"); 
	g_hMode = CreateConVar("spawnfx_mode", "1", "Specify which effects will be fired when player spawn | 1 = Fade + Shake | 2 = Fade only | 3 = Shake Only | 0 to disable");
	g_hFadeColor =CreateConVar("spawnfx_fade_color", "255 255 255 255", "Specify the color mixer of the fade effect. <RED> <GREEN> <BLUE> <ALPHA>");
	g_hFadeHold =CreateConVar("spawnfx_fade_hold", "500", "How long the fade hold effects take place in milliseconds");
	g_hFadeLength =CreateConVar("spawnfx_fade_length", "2500", "How long the fade in effects take place in milliseconds");
	g_hShakeLength =CreateConVar("spawnfx_shake_length", "7.5", "How long the shake effect take place in seconds.");
	g_hShakeAmplitude =CreateConVar("spawnfx_shake_amp", "30.0", "How strong the shake effect is");
	
	HookEvent("player_spawn", PlayerSpawn);
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new hEnable = GetConVarInt(g_hEnable);
	new hMode = GetConVarInt(g_hMode);
	if (!hEnable || !hMode)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (hMode == 1 || hMode == 2)
	{
		new hFadeHold = GetConVarInt(g_hFadeHold);
		new hFadeLength = GetConVarInt(g_hFadeLength);
		
		new String:hFadeColor[24];
		new String:ColorArray[4][4];
		GetConVarString(g_hFadeColor, hFadeColor, sizeof(hFadeColor));
		ExplodeString(hFadeColor, " ", ColorArray, 4, 4);
		new R = StringToInt(ColorArray[0]);
		new G = StringToInt(ColorArray[1]);
		new B = StringToInt(ColorArray[2]);
		new A = StringToInt(ColorArray[3]);
		Fade(client, hFadeHold, hFadeLength, FFADE_IN|FFADE_PURGE, R, G, B, A);
	}
	
	if (hMode == 1 || hMode == 3)
	{
		new Float:hShakeLength = GetConVarFloat(g_hShakeLength);
		new Float:hShakeAmplitude = GetConVarFloat(g_hShakeAmplitude);
		Shake(client, hShakeLength, hShakeAmplitude);
	}
}

stock Fade(client, hold, length, type, r, g, b, a)
{
	new Handle:hFadeClient = StartMessageOne("Fade", client);
	if (hFadeClient !=INVALID_HANDLE)
	{
		BfWriteShort(hFadeClient, length);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration
		BfWriteShort(hFadeClient, hold);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration until reset (fade & hold)
		BfWriteShort(hFadeClient, type); // fade type (in / out) FFADE_PURGE|FFADE_IN
		BfWriteByte(hFadeClient, r);	// fade red
		BfWriteByte(hFadeClient, g);	// fade green
		BfWriteByte(hFadeClient, b);	// fade blue
		BfWriteByte(hFadeClient, a);// fade alpha
		EndMessage();
	}
}

stock Shake(client, Float:flLength, Float:flAmp)
{
	new Handle:hShake = StartMessageOne("Shake", client);
	if (hShake !=INVALID_HANDLE)
	{
		BfWriteByte(hShake,  0);
		BfWriteFloat(hShake, flAmp);
		BfWriteFloat(hShake, 5.0);
		BfWriteFloat(hShake, flLength);
		EndMessage();
	}
}