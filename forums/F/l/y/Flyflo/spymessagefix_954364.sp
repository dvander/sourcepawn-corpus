#pragma semicolon 1

#include <tf2_stocks>

#define PL_VERSION  "1.2.0"
#define PL_NAME     "TF2 Spy Radio Message Fix"

new String:Spy_CloackedIdentify[9][10][64];

public Plugin:myinfo = 
{
    name = PL_NAME,
    author = "Flyflo",
    description = "Fix the spy detection radio message broken by changing color/alpha/etc...",
    version = PL_VERSION,
    url = "http://www.geek-gaming.fr/"
}

public OnPluginStart()
{
    AddNormalSoundHook(NormalSHook:RewriteMessage);
    CreateConVar("sm_spyradiofix_version", PL_VERSION, PL_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);

    //SCOUT
    Spy_CloackedIdentify[_:TFClass_Scout-1][_:TFClass_Scout-1] = "vo/scout_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Scout-1][_:TFClass_Sniper-1] = "vo/scout_cloakedspyidentify09.wav";
    Spy_CloackedIdentify[_:TFClass_Scout-1][_:TFClass_Soldier-1] = "vo/scout_cloakedspyidentify02.wav";
    Spy_CloackedIdentify[_:TFClass_Scout-1][_:TFClass_DemoMan-1] = "vo/scout_cloakedspyidentify05.wav";
    Spy_CloackedIdentify[_:TFClass_Scout-1][_:TFClass_Medic-1] = "vo/scout_cloakedspyidentify07.wav";
    Spy_CloackedIdentify[_:TFClass_Scout-1][_:TFClass_Heavy-1] = "vo/scout_cloakedspyidentify03.wav";
    Spy_CloackedIdentify[_:TFClass_Scout-1][_:TFClass_Pyro-1] = "vo/scout_cloakedspyidentify04.wav";
    Spy_CloackedIdentify[_:TFClass_Scout-1][_:TFClass_Spy-1] = "vo/scout_cloakedspyidentify06.wav";
    Spy_CloackedIdentify[_:TFClass_Scout-1][_:TFClass_Engineer-1] = "vo/scout_cloakedspyidentify08.wav";
    Spy_CloackedIdentify[_:TFClass_Scout-1][9] = "";

    //SNIPER
    Spy_CloackedIdentify[_:TFClass_Sniper-1][_:TFClass_Scout-1] = "vo/sniper_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Sniper-1][_:TFClass_Sniper-1] = "vo/sniper_cloakedspyidentify08.wav";
    Spy_CloackedIdentify[_:TFClass_Sniper-1][_:TFClass_Soldier-1] = "vo/sniper_cloakedspyidentify02.wav";
    Spy_CloackedIdentify[_:TFClass_Sniper-1][_:TFClass_DemoMan-1] = "vo/sniper_cloakedspyidentify05.wav";
    Spy_CloackedIdentify[_:TFClass_Sniper-1][_:TFClass_Medic-1] = "vo/sniper_cloakedspyidentify06.wav";
    Spy_CloackedIdentify[_:TFClass_Sniper-1][_:TFClass_Heavy-1] = "vo/sniper_cloakedspyidentify03.wav";
    Spy_CloackedIdentify[_:TFClass_Sniper-1][_:TFClass_Pyro-1] = "vo/sniper_cloakedspyidentify04.wav";
    Spy_CloackedIdentify[_:TFClass_Sniper-1][_:TFClass_Spy-1] = "vo/sniper_cloakedspyidentify09.wav";
    Spy_CloackedIdentify[_:TFClass_Sniper-1][_:TFClass_Engineer-1] = "vo/sniper_cloakedspyidentify07.wav";
    Spy_CloackedIdentify[_:TFClass_Sniper-1][9] = "";

    //SOLDIER
    Spy_CloackedIdentify[_:TFClass_Soldier-1][_:TFClass_Scout-1] = "vo/soldier_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Soldier-1][_:TFClass_Sniper-1] = "vo/soldier_cloakedspyidentify08.wav";
    Spy_CloackedIdentify[_:TFClass_Soldier-1][_:TFClass_Soldier-1] = "vo/soldier_cloakedspyidentify02.wav";
    Spy_CloackedIdentify[_:TFClass_Soldier-1][_:TFClass_DemoMan-1] = "vo/soldier_cloakedspyidentify05.wav";
    Spy_CloackedIdentify[_:TFClass_Soldier-1][_:TFClass_Medic-1] = "vo/soldier_cloakedspyidentify06.wav";
    Spy_CloackedIdentify[_:TFClass_Soldier-1][_:TFClass_Heavy-1] = "vo/soldier_cloakedspyidentify03.wav";
    Spy_CloackedIdentify[_:TFClass_Soldier-1][_:TFClass_Pyro-1] = "vo/soldier_cloakedspyidentify04.wav";
    Spy_CloackedIdentify[_:TFClass_Soldier-1][_:TFClass_Spy-1] = "vo/soldier_cloakedspyidentify09.wav";
    Spy_CloackedIdentify[_:TFClass_Soldier-1][_:TFClass_Engineer-1] = "vo/soldier_cloakedspyidentify07.wav";
    Spy_CloackedIdentify[_:TFClass_Soldier-1][9] = "";

    //DEMOMAN
    Spy_CloackedIdentify[_:TFClass_DemoMan-1][_:TFClass_Scout-1] = "vo/demoman_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_DemoMan-1][_:TFClass_Sniper-1] = "vo/demoman_cloakedspyidentify08.wav";
    Spy_CloackedIdentify[_:TFClass_DemoMan-1][_:TFClass_Soldier-1] = "vo/demoman_cloakedspyidentify02.wav";
    Spy_CloackedIdentify[_:TFClass_DemoMan-1][_:TFClass_DemoMan-1] = "vo/demoman_cloakedspyidentify04.wav";
    Spy_CloackedIdentify[_:TFClass_DemoMan-1][_:TFClass_Medic-1] = "vo/demoman_cloakedspyidentify06.wav";
    Spy_CloackedIdentify[_:TFClass_DemoMan-1][_:TFClass_Heavy-1] = "vo/demoman_cloakedspyidentify03.wav";
    Spy_CloackedIdentify[_:TFClass_DemoMan-1][_:TFClass_Pyro-1] = "vo/demoman_cloakedspyidentify09.wav";
    Spy_CloackedIdentify[_:TFClass_DemoMan-1][_:TFClass_Spy-1] = "vo/demoman_cloakedspyidentify05.wav";
    Spy_CloackedIdentify[_:TFClass_DemoMan-1][_:TFClass_Engineer-1] = "vo/demoman_cloakedspyidentify07.wav";
    Spy_CloackedIdentify[_:TFClass_DemoMan-1][9] = "";

    //MEDIC
    Spy_CloackedIdentify[_:TFClass_Medic-1][_:TFClass_Scout-1] = "vo/medic_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Medic-1][_:TFClass_Sniper-1] = "vo/medic_cloakedspyidentify09.wav";
    Spy_CloackedIdentify[_:TFClass_Medic-1][_:TFClass_Soldier-1] = "vo/medic_cloakedspyidentify02.wav";
    Spy_CloackedIdentify[_:TFClass_Medic-1][_:TFClass_DemoMan-1] = "vo/medic_cloakedspyidentify05.wav";
    Spy_CloackedIdentify[_:TFClass_Medic-1][_:TFClass_Medic-1] = "vo/medic_cloakedspyidentify07.wav";
    Spy_CloackedIdentify[_:TFClass_Medic-1][_:TFClass_Heavy-1] = "vo/medic_cloakedspyidentify03.wav";
    Spy_CloackedIdentify[_:TFClass_Medic-1][_:TFClass_Pyro-1] = "vo/medic_cloakedspyidentify04.wav";
    Spy_CloackedIdentify[_:TFClass_Medic-1][_:TFClass_Spy-1] = "vo/medic_cloakedspyidentify06.wav";
    Spy_CloackedIdentify[_:TFClass_Medic-1][_:TFClass_Engineer-1] = "vo/medic_cloakedspyidentify08.wav";
    Spy_CloackedIdentify[_:TFClass_Medic-1][9] = "";

    //HEAVY
    Spy_CloackedIdentify[_:TFClass_Heavy-1][_:TFClass_Scout-1] = "vo/heavy_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Heavy-1][_:TFClass_Sniper-1] = "vo/heavy_cloakedspyidentify09.wav";
    Spy_CloackedIdentify[_:TFClass_Heavy-1][_:TFClass_Soldier-1] = "vo/heavy_cloakedspyidentify02.wav";
    Spy_CloackedIdentify[_:TFClass_Heavy-1][_:TFClass_DemoMan-1] = "vo/heavy_cloakedspyidentify05.wav";
    Spy_CloackedIdentify[_:TFClass_Heavy-1][_:TFClass_Medic-1] = "vo/heavy_cloakedspyidentify07.wav";
    Spy_CloackedIdentify[_:TFClass_Heavy-1][_:TFClass_Heavy-1] = "vo/heavy_cloakedspyidentify03.wav";
    Spy_CloackedIdentify[_:TFClass_Heavy-1][_:TFClass_Pyro-1] = "vo/heavy_cloakedspyidentify04.wav";
    Spy_CloackedIdentify[_:TFClass_Heavy-1][_:TFClass_Spy-1] = "vo/heavy_cloakedspyidentify06.wav";
    Spy_CloackedIdentify[_:TFClass_Heavy-1][_:TFClass_Engineer-1] = "vo/heavy_cloakedspyidentify08.wav";
    Spy_CloackedIdentify[_:TFClass_Heavy-1][9] = "";

    //PYRO
    Spy_CloackedIdentify[_:TFClass_Pyro-1][_:TFClass_Scout-1] = "vo/pyro_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Pyro-1][_:TFClass_Sniper-1] = "vo/pyro_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Pyro-1][_:TFClass_Soldier-1] = "vo/pyro_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Pyro-1][_:TFClass_DemoMan-1] = "vo/pyro_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Pyro-1][_:TFClass_Medic-1] = "vo/pyro_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Pyro-1][_:TFClass_Heavy-1] = "vo/pyro_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Pyro-1][_:TFClass_Pyro-1] = "vo/pyro_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Pyro-1][_:TFClass_Spy-1] = "vo/pyro_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Pyro-1][_:TFClass_Engineer-1] = "vo/pyro_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Pyro-1][9] = "";

    //SPY
    Spy_CloackedIdentify[_:TFClass_Spy-1][_:TFClass_Scout-1] = "vo/spy_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Spy-1][_:TFClass_Sniper-1] = "vo/spy_cloakedspyidentify10.wav";
    Spy_CloackedIdentify[_:TFClass_Spy-1][_:TFClass_Soldier-1] = "vo/spy_cloakedspyidentify02.wav";
    Spy_CloackedIdentify[_:TFClass_Spy-1][_:TFClass_DemoMan-1] = "vo/spy_cloakedspyidentify05.wav";
    Spy_CloackedIdentify[_:TFClass_Spy-1][_:TFClass_Medic-1] = "vo/spy_cloakedspyidentify08.wav";
    Spy_CloackedIdentify[_:TFClass_Spy-1][_:TFClass_Heavy-1] = "vo/spy_cloakedspyidentify03.wav";
    Spy_CloackedIdentify[_:TFClass_Spy-1][_:TFClass_Pyro-1] = "vo/spy_cloakedspyidentify04.wav";
    Spy_CloackedIdentify[_:TFClass_Spy-1][_:TFClass_Spy-1] = "vo/spy_cloakedspyidentify06.wav";
    Spy_CloackedIdentify[_:TFClass_Spy-1][_:TFClass_Engineer-1] = "vo/spy_cloakedspyidentify09.wav";
    Spy_CloackedIdentify[_:TFClass_Spy-1][9] = "vo/spy_cloakedspyidentify07.wav";

    //ENGINEER
    Spy_CloackedIdentify[_:TFClass_Engineer-1][_:TFClass_Scout-1] = "vo/engineer_cloakedspyidentify01.wav";
    Spy_CloackedIdentify[_:TFClass_Engineer-1][_:TFClass_Sniper-1] = "vo/engineer_cloakedspyidentify09.wav";
    Spy_CloackedIdentify[_:TFClass_Engineer-1][_:TFClass_Soldier-1] = "vo/engineer_cloakedspyidentify02.wav";
    Spy_CloackedIdentify[_:TFClass_Engineer-1][_:TFClass_DemoMan-1] = "vo/engineer_cloakedspyidentify05.wav";
    Spy_CloackedIdentify[_:TFClass_Engineer-1][_:TFClass_Medic-1] = "vo/engineer_cloakedspyidentify07.wav";
    Spy_CloackedIdentify[_:TFClass_Engineer-1][_:TFClass_Heavy-1] = "vo/engineer_cloakedspyidentify03.wav";
    Spy_CloackedIdentify[_:TFClass_Engineer-1][_:TFClass_Pyro-1] = "vo/engineer_cloakedspyidentify04.wav";
    Spy_CloackedIdentify[_:TFClass_Engineer-1][_:TFClass_Spy-1] = "vo/engineer_cloakedspyidentify06.wav";
    Spy_CloackedIdentify[_:TFClass_Engineer-1][_:TFClass_Engineer-1] = "vo/engineer_cloakedspyidentify08.wav";
    Spy_CloackedIdentify[_:TFClass_Engineer-1][9] = "vo/engineer_cloakedspyidentify10.wav";
}

public Action:RewriteMessage(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity)
{
    if(StrContains(sample, "CloakedSpy") != -1)
    {
        if(IsValidClient(entity))
        {
            new iTarget = GetClientAimTarget(entity);

            if(IsValidClient(iTarget) && !TF2_IsPlayerInCondition(iTarget, TFCond_Cloaked))
            {
                new iClientTeam = GetClientTeam(entity);
                new iTargetTeam = GetClientTeam(iTarget);

                new iFromClass = _:TF2_GetPlayerClass(entity);
                new iToClass = _:TF2_GetPlayerClass(iTarget);

                if(TF2_IsPlayerInCondition(entity, TFCond_Disguised))
                {
                    iFromClass = GetEntProp(entity, Prop_Send, "m_nDisguiseClass");
                }

                if(TF2_IsPlayerInCondition(iTarget, TFCond_Disguised) && iClientTeam != iTargetTeam)
                {
                    iToClass = GetEntProp(iTarget, Prop_Send, "m_nDisguiseClass");
                }

                if((iFromClass == _:TFClass_Engineer || iFromClass == _:TFClass_Spy) && iToClass == _:TFClass_Spy)
                {
                    new ArrayIndex = (GetRandomInt(4, 5)*2) - 1;

                    //Thanks to MasterOfTheXP
                    Format(sample, PLATFORM_MAX_PATH, Spy_CloackedIdentify[iFromClass - 1][ArrayIndex]);
                    return Plugin_Changed;
                }
                else
                {
                    //Thanks to MasterOfTheXP
                    Format(sample, PLATFORM_MAX_PATH, Spy_CloackedIdentify[iFromClass - 1][iToClass - 1], entity);
                    return Plugin_Changed;
                }
            }
        }
    }

    return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
    // Part taken from SMLib (https://github.com/bcserv/smlib)
    if (client > 4096)
    {
        client = EntRefToEntIndex(client);
    }

    if(client < 1 || client > MaxClients)
    {
        return false;
    }

    if(!IsClientConnected(client))
    {
        return false;
    }

    if(!IsClientInGame(client))
    {
        return false;
    }

    return true;
}
