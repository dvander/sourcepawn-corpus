#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#include <sourcescramble>

public void OnPluginStart()
{
	GameData data = new GameData("l4d2_adrenaline_snd_remove");
	
	MemoryPatch.CreateFromConf(data, "CTerrorPlayer::OnAdrenalineUsed").Enable();
	
	delete data;
}
