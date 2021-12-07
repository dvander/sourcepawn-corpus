#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.0"

new Handle:g_hBackupPatch;
new g_iPatchSize;
new Address:g_puntBotCall;

public Plugin:myinfo = {
	name		= "Block bot punting",
	author		= "TheLastRevenge",
	description	= "Block Punting bot when server is hibernating",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=251064"
};

public OnPluginStart()
{
	new Handle:hGC = LoadGameConfigFile("hibernatebots.games");
	if(!hGC)
		SetFailState("Can't find hibernatebots.games.txt gamedata.");
	
	new Address:puntBotCall = GameConfGetAddress(hGC, "SetHibernating");
	if(!puntBotCall)
		SetFailState("Can't find CGameServer:SetHibernating.");
	
	new iOffset = GameConfGetOffset(hGC, "PuntBotsCall_Offset");
	if(iOffset == -1)
		SetFailState("Can't get PuntBotsCall_Offset offset from gamedata.");
	
	puntBotCall += Address:iOffset;
	
	new iSize = GameConfGetOffset(hGC, "PuntBotsCall_Patchsize");
	if(iSize == -1)
		SetFailState("Can't get PuntBotsCall_Patchsize offset from gamedata.");
	
	// Store the current memory
	g_hBackupPatch = CreateArray(iSize);
	// Remember the address of the patched call, so we can unpatch on unload
	g_puntBotCall = puntBotCall;
	g_iPatchSize = iSize;
	
	// Do the actual no-op'ing and save the current bytes
	new backupBytes[iSize];
	for(new i=0;i<iSize;i++)
	{
		backupBytes[i] = LoadFromAddress(puntBotCall, NumberType_Int8);
		StoreToAddress(puntBotCall, 0x90, NumberType_Int8);
		puntBotCall++;
	}
	
	// Remember the original memory
	PushArrayArray(g_hBackupPatch, backupBytes, iSize);
	CloseHandle(hGC);
}

public OnPluginEnd()
{
	// Did we even find the address?
	if(!g_puntBotCall)
		return;
	
	// Get the original memory back
	new backupBytes[g_iPatchSize];
	GetArrayArray(g_hBackupPatch, 0, backupBytes, g_iPatchSize);
	
	// Restore the original memory
	new Address:puntBotCall = g_puntBotCall;
	for(new i=0;i<g_iPatchSize;i++)
	{
		StoreToAddress(puntBotCall, backupBytes[i], NumberType_Int8);
		puntBotCall++;
	}
}