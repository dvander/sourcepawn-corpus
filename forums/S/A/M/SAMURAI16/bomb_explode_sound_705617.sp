#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
    name = "New Plugin",
    author = "SAMURAI",
    description = "",
    version = "0.1",
    url = ""
}

stock const String:g_szFile[] = "misc/bomb_explode_sound.wav";

public OnPluginStart()
{
    HookEvent("bomb_exploded",fn_EventBomb_Exploded);
}

public OnMapStart()
{
    static String:szTemp[64];
    FormatEx(szTemp,sizeof(szTemp),"sound/%s",g_szFile);
    
    PrecacheSound(g_szFile);
    AddFileToDownloadsTable(szTemp);
}

public Action:fn_EventBomb_Exploded(Handle:event, const String:name[], bool:dontBroadcast)
{
    EmitSoundToAll(g_szFile);
}