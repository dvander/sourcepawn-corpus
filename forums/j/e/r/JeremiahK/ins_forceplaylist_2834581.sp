// vi: syntax=cpp
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_gamerules>

public Plugin myinfo = {
    name = "[INS] Force Playlist",
    author = "JeremiahK (RedDeathOfMe)",
    description = "Force sv_playlist to be enabled, even if it normally wouldn't.",
    version = "1.12.1.1",
    url = "https://forums.alliedmods.net/showthread.php?p=2834581"
}

public APLRes AskPluginLoad2(Handle handle, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Insurgency) {
		strcopy(error, err_max, "Only compatible with Insurgency");
		return APLRes_SilentFailure;
	}
}

public void OnMapStart() {
    OnGameFrame();
}

public void OnGameFrame() {
    GameRules_SetProp("m_bPlaylistEnabled", true);
}
