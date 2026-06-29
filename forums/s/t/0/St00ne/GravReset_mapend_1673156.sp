#include <sourcemod>
#define PLUGIN_VERSION "1.0.2"

new Handle:v_Gravity;
new Handle:v_GravMessage;
new Handle:v_NormGravity;

public Plugin:myinfo =
{
    name = "Game-End Gravity Reset",
    author = "DarthNinja + Bacardi + St00ne",
    description = "Resets Gravity at the end of the game",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=1097121"
};

public OnPluginStart()
{
	v_GravMessage = CreateConVar("gravreset_message","1","Announce gravity change 1/0");
	v_NormGravity = CreateConVar("gravreset_gravity","800","Gravity to reset to");
	CreateConVar("sm_gravreset_version", PLUGIN_VERSION, "Version of gravity reset plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	v_Gravity = FindConVar("sv_gravity");
	if (v_Gravity == INVALID_HANDLE)
	{
		SetFailState("Unable to find convar: sv_gravity");
	}
	
    decl String:folder[64];
    GetGameFolderName(folder, sizeof(folder));

    if (strcmp(folder, "tf") == 0)
    {
        HookEvent("teamplay_win_panel", Event_GameEnd);
    }
    else
    {
        if(!HookEventEx("cs_win_panel_match", Event_GameEnd))
        {
            SetFailState("Unable to find event: cs_win_panel_match");
        }
    }
}

public Event_GameEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new currentGrav = GetConVarInt(v_Gravity);
	new NormGrav = GetConVarInt(v_NormGravity);

	if(currentGrav != NormGrav)
	{
		SetConVarInt(v_Gravity, NormGrav);
		if (GetConVarBool(v_GravMessage))
		{
			PrintToChatAll("Gravity has been reset to %d due to game end", NormGrav);
		}
	}
}
