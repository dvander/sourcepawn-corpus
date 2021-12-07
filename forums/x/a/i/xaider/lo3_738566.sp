/*	X@IDER 16.12.2008
	My first plugin. Just implements Live On Three sequence
*/

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.02"

public Plugin:myinfo =
{
	name = "Live On 3",
	author = "X@IDER",
	description = "3 restart system",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

// Restart values
new Handle:sm_lo3_r1_value = INVALID_HANDLE;
new Handle:sm_lo3_r2_value = INVALID_HANDLE;
new Handle:sm_lo3_r3_value = INVALID_HANDLE;

// Restart messages
new Handle:sm_lo3_r1_message = INVALID_HANDLE;
new Handle:sm_lo3_r2_message = INVALID_HANDLE;
new Handle:sm_lo3_r3_message = INVALID_HANDLE;

// Loops of text write
new Handle:sm_lo3_loops = INVALID_HANDLE;

// Message on match begins
new Handle:sm_lo3_match_message = INVALID_HANDLE;

public OnPluginStart()
{
	sm_lo3_r1_value = CreateConVar("sm_lo3_r1_value", "10", "First restart time", 0, true, 1.0);
	sm_lo3_r2_value = CreateConVar("sm_lo3_r2_value", "5", "Second restart time", 0, true, 1.0);
	sm_lo3_r3_value = CreateConVar("sm_lo3_r3_value", "3", "Third restart time", 0, true, 1.0);
	sm_lo3_r1_message = CreateConVar("sm_lo3_r1_message", "1st restart: prepare..", "First restart message", 0);
	sm_lo3_r2_message = CreateConVar("sm_lo3_r2_message", "2nd restart: get ready..", "Second restart message", 0);
	sm_lo3_r3_message = CreateConVar("sm_lo3_r3_message", "3rd restart: get set..", "Third restart message", 0);
	sm_lo3_match_message = CreateConVar("sm_lo3_match_message", "MATCH IS STARTED!!! GO!!!", "Match message", 0);
	sm_lo3_loops = CreateConVar("sm_lo3_loops", "5", "Loops of repeating text", 0, true, 1.0);
	RegAdminCmd("sm_lo3", Rest1, ADMFLAG_CUSTOM4);
}

public Float:DoRest(Handle:val)
{
	new Float:rv = GetConVarFloat(val);
	ServerCommand("mp_restartgame %f",rv);
	return rv;
}

public ShowMsg(Handle:msg)
{
	new loops = GetConVarInt(sm_lo3_loops);
	new String:rm[64];
	GetConVarString(msg,rm,sizeof(rm));
	for (new i = 0; i < loops; i++)
	PrintToChatAll("\x04%s",rm);
	PrintCenterTextAll(rm);
}

public Action:Rest1(client, args)
{
	ShowMsg(sm_lo3_r1_message);
	new Float:rv = DoRest(sm_lo3_r1_value);
	CreateTimer(rv,Rest2);
}

public Action:Rest2(Handle:timer)
{
	ShowMsg(sm_lo3_r2_message);
	new Float:rv = DoRest(sm_lo3_r2_value);
	CreateTimer(rv,Rest3);	
}

public Action:Rest3(Handle:timer)
{
	ShowMsg(sm_lo3_r3_message);
	new Float:rv = DoRest(sm_lo3_r3_value);
	CreateTimer(rv,Match);	
}

public Action:Match(Handle:timer)
{
	ShowMsg(sm_lo3_match_message);
}