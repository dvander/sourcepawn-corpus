#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <ff2_dynamic_defaults>

#pragma newdecls required

int curBossIdx;
bool workaroundActive=false;
bool isMatch=false;
char curBossSteamID[64];

// workaround for v1.10.8 and older, due to a bug:
char curBGM[PLATFORM_MAX_PATH];

public Plugin myinfo = {
    name = "Freak Fortress 2: Boss Client Music Modifier",
    author = "Koishi (SHADoW NiNE TR3S)",
    version = "1.0",
};

public void OnPluginStart2()
{

    int version[3];
    FF2_GetFF2Version(version);
    if(version[0]==1 && (version[1]<10 || (version[1]==10 && version[2]<9)))
    {
        HookEvent("arena_win_panel", Event_ArenaWinPanel); // workaround for older versions to fix a bug present in those versions of FF2.
        workaroundActive=true;
    }
    
    HookEvent("arena_round_start", Event_ArenaRoundStart);
}

public void FF2_OnAbility2(int boss,const char[] plugin_name,const char[] ability_name,int action)
{
    // nothing to see here
}

public void Event_ArenaRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    isMatch=false;
    for(int client=1;client<=MaxClients;client++)
    {
        if(client<=0 || client>MaxClients || !IsClientInGame(client))
            continue;
        int boss=FF2_GetBossIndex(client);
        if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, "special_changebgm_onclientmatch"))
        {
            char steamID[64], steamIDstring[1024];
            GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID), true);            
            FF2_GetAbilityArgumentString(boss, this_plugin_name, "special_changebgm_onclientmatch", 1, steamIDstring, sizeof(steamIDstring));
            if(steamIDstring[0])
            {
                char clientSteamID[64][64];
                int count = ExplodeString(steamIDstring, " ; ", clientSteamID, sizeof(clientSteamID), sizeof(clientSteamID));
                if (count > 0)
                {
                    for (int i = 0; i < count; i++)
                    {
                        if(StrEqual(steamID, clientSteamID[i], false) && !boss)
                        {
                            strcopy(curBossSteamID, sizeof(curBossSteamID), clientSteamID[i]);
                            curBossIdx=boss;
                            isMatch=true;
                        }
                    }
                }
            }
        }
    }
}

public Action FF2_OnMusic(char[] path, float &time)
{
    if(isMatch && !curBossIdx)
    {
        Handle bossKV=FF2_GetSpecialKV(curBossIdx, false);
        
        if(bossKV==null)
        {
            return Plugin_Continue;
        }
        
        KvRewind(bossKV);
    
        char bgmCFG[256];
        Format(bgmCFG, sizeof(bgmCFG), "sound_bgm_%s", curBossSteamID);
        if(KvJumpToKey(bossKV, bgmCFG))
        {
            char music[PLATFORM_MAX_PATH];
            int index;
            do
            {
                index++;
                Format(music, 10, "time%i", index);
            }
            while(KvGetFloat(bossKV, music)>1);

            index=GetRandomInt(1, index-1);
            Format(music, 10, "time%i", index);
            float length=KvGetFloat(bossKV, music);
            Format(music, 10, "path%i", index);
            KvGetString(bossKV, music, music, sizeof(music));
            
            char temp[PLATFORM_MAX_PATH];
            Format(temp, sizeof(temp), "sound/%s", music);
            if(FileExists(temp, true))
            {
                time=length;
                if(workaroundActive)
                {
                    strcopy(curBGM, sizeof(curBGM), music);
                }
                strcopy(path, PLATFORM_MAX_PATH, music);
                return Plugin_Changed;
            }
        }
    }  
    return Plugin_Continue;
}

// this exists solely to work around the issue where v1.10.8 and older won't stop the BGM properly if changed via FF2_OnMusic. This has been fixed on v1.10.9!
public void Event_ArenaWinPanel(Event event, const char[] name, bool dontBroadcast)
{
    for(int client=1;client<=MaxClients;client++)
    {
        if(client<=0 || client>MaxClients || !IsClientInGame(client))
            continue;
        StopSound(client, SNDCHAN_AUTO, curBGM);
    }
}

