
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
    name = "Custom Stripper Spawn Entries",
    description = "Provides CS:GO, CS:S & DOD:S Custom Stripper Spawn Entries For The Map",
    author = "Hattrick HKS (CARAMEL® HACK)",
    version = __DATE__,
    url = "https://hattrick.go.ro/",
};

public char g_szTbls[][] =
{
    "CBaseEntity",                  "CBaseCSEntity",
    "CBasePlayer",                  "CBaseCSPlayer",
    "CBaseGrenade",                 "CBaseCSGrenade",
    "CBaseGrenadeProjectile",       "CBaseCSGrenadeProjectile",
    "CBasePlayerResource",          "CBaseCSPlayerResource",
    "CBaseViewModel",               "CBaseCSViewModel",
    "CBaseC4",                      "CBaseCSC4",
    "CBaseAnimating",               "CBaseCSAnimating",
    "CBaseCombatCharacter",         "CBaseCSCombatCharacter",
    "CBaseCombatWeapon",            "CBaseCSCombatWeapon",
    "CBaseWeaponWorldModel",        "CBaseCSWeaponWorldModel",
    "CBaseRagdoll",                 "CBaseCSRagdoll",

    "CEntity",                      "CSEntity",                             "CCSEntity",
    "CPlayer",                      "CSPlayer",                             "CCSPlayer",
    "CGrenade",                     "CSGrenade",                            "CCSGrenade",
    "CGrenadeProjectile",           "CSGrenadeProjectile",                  "CCSGrenadeProjectile",
    "CPlayerResource",              "CSPlayerResource",                     "CCSPlayerResource",
    "CViewModel",                   "CSViewModel",                          "CCSViewModel",
    "CC4",                          "CSC4",                                 "CCSC4",
    "CAnimating",                   "CSAnimating",                          "CCSAnimating",
    "CCombatCharacter",             "CSCombatCharacter",                    "CCSCombatCharacter",
    "CCombatWeapon",                "CSCombatWeapon",                       "CCSCombatWeapon",
    "CWeaponWorldModel",            "CSWeaponWorldModel",                   "CCSWeaponWorldModel",
    "CRagdoll",                     "CSRagdoll",                            "CCSRagdoll",
};

public EngineVersion g_nEngVs = Engine_Unknown;

public int g_nTotalA = 0;

public float g_fPosA[99][3];
public float g_fAngA[99][3];

public int g_nTotalB = 0;

public float g_fPosB[99][3];
public float g_fAngB[99][3];

public int m_vecOrigin = 0;

public int m_angRotation = 0;

public int m_hOwner = 0;

public int m_hOwnerEntity = 0;

public int m_bInBZ = 0;
public int m_bInBZBytes = 0;

public int m_fFlags = 0;
public int m_fFlagsBytes = 0;

public int m_nButtons = 0;
public int m_nButtonsBytes = 0;

public int m_fEffects = 0;
public int m_fEffectsBytes = 0;

public int g_nRed = 0;
public int g_nBlue = 0;

public char g_szPath[256] = { 0, ... };

public bool g_bOnlyInBZ = false;

public bool g_bActive = false;

public int mp_fraglimit = 0;
public int mp_roundtime = 0;
public int mp_roundtime_defuse = 0;
public int mp_roundtime_hostage = 0;
public int mp_roundtime_bomb = 0;
public int mp_roundtime_rescue = 0;
public int mp_buytime = 0;
public int mp_teamlimit = 0;
public int mp_timelimit = 0;
public int mp_roundtime_hostages = 0;
public int mp_limitteam = 0;
public int mp_limitteams = 0;
public int mp_teamlimits = 0;
public int mp_ignore_round_win_conditions = 0;
public int mp_roundtime_deploy = 0;
public int mp_freezetime = 0;
public int mp_winlimit = 0;
public int mp_maxrounds = 0;
public int mp_roundtime_deployment = 0;
public int mp_startmoney = 0;
public int mp_maxmoney = 0;
public int mp_restartgame = 0;
public int mp_restartgame_immediate = 0;

public int bot_quota = 0;

public char sv_password[256] = { 0, ... };

public void OnMapEnd()
{
    if (g_bActive)
    {
        RestoreOrgVars();
        {
            g_bActive = false;
            {
                g_nTotalA = 0;
                {
                    g_nTotalB = 0;
                    {
                        g_nRed = 0;
                        {
                            g_nBlue = 0;
                            {
                                g_bOnlyInBZ = false;
                            }
                        }
                    }
                }
            }
        }
    }
}

public void OnPluginEnd()
{
    OnMapEnd();
}

public void ParseOrgVars()
{
    static Handle hVar = null;
    {
        mp_fraglimit = (hVar = FindConVar("mp_fraglimit")) != null ? GetConVarInt(hVar) : 0;
        mp_roundtime = (hVar = FindConVar("mp_roundtime")) != null ? GetConVarInt(hVar) : 0;
        mp_roundtime_defuse = (hVar = FindConVar("mp_roundtime_defuse")) != null ? GetConVarInt(hVar) : 0;
        mp_roundtime_hostage = (hVar = FindConVar("mp_roundtime_hostage")) != null ? GetConVarInt(hVar) : 0;
        mp_roundtime_bomb = (hVar = FindConVar("mp_roundtime_bomb")) != null ? GetConVarInt(hVar) : 0;
        mp_roundtime_rescue = (hVar = FindConVar("mp_roundtime_rescue")) != null ? GetConVarInt(hVar) : 0;
        mp_buytime = (hVar = FindConVar("mp_buytime")) != null ? GetConVarInt(hVar) : 0;
        mp_teamlimit = (hVar = FindConVar("mp_teamlimit")) != null ? GetConVarInt(hVar) : 0;
        mp_timelimit = (hVar = FindConVar("mp_timelimit")) != null ? GetConVarInt(hVar) : 0;
        mp_roundtime_hostages = (hVar = FindConVar("mp_roundtime_hostages")) != null ? GetConVarInt(hVar) : 0;
        mp_limitteam = (hVar = FindConVar("mp_limitteam")) != null ? GetConVarInt(hVar) : 0;
        mp_limitteams = (hVar = FindConVar("mp_limitteams")) != null ? GetConVarInt(hVar) : 0;
        mp_teamlimits = (hVar = FindConVar("mp_teamlimits")) != null ? GetConVarInt(hVar) : 0;
        mp_ignore_round_win_conditions = (hVar = FindConVar("mp_ignore_round_win_conditions")) != null ? GetConVarInt(hVar) : 0;
        mp_roundtime_deploy = (hVar = FindConVar("mp_roundtime_deploy")) != null ? GetConVarInt(hVar) : 0;
        mp_freezetime = (hVar = FindConVar("mp_freezetime")) != null ? GetConVarInt(hVar) : 0;
        mp_winlimit = (hVar = FindConVar("mp_winlimit")) != null ? GetConVarInt(hVar) : 0;
        mp_maxrounds = (hVar = FindConVar("mp_maxrounds")) != null ? GetConVarInt(hVar) : 0;
        mp_roundtime_deployment = (hVar = FindConVar("mp_roundtime_deployment")) != null ? GetConVarInt(hVar) : 0;
        mp_startmoney = (hVar = FindConVar("mp_startmoney")) != null ? GetConVarInt(hVar) : 0;
        mp_maxmoney = (hVar = FindConVar("mp_maxmoney")) != null ? GetConVarInt(hVar) : 0;
        mp_restartgame = (hVar = FindConVar("mp_restartgame")) != null ? GetConVarInt(hVar) : 0;
        mp_restartgame_immediate = (hVar = FindConVar("mp_restartgame_immediate")) != null ? GetConVarInt(hVar) : 0;

        bot_quota = (hVar = FindConVar("bot_quota")) != null ? GetConVarInt(hVar) : 0;

        if ((hVar = FindConVar("sv_password")) != null)
        {
            GetConVarString(hVar, sv_password, sizeof sv_password);
        }
    }
}

public void RestoreOrgVars()
{
    ServerCommand("mp_fraglimit %d; mp_roundtime %d; mp_roundtime_defuse %d; mp_roundtime_hostage %d; mp_roundtime_bomb %d; mp_roundtime_rescue %d; mp_buytime %d; mp_teamlimit %d;",
        mp_fraglimit, mp_roundtime, mp_roundtime_defuse, mp_roundtime_hostage, mp_roundtime_bomb, mp_roundtime_rescue, mp_buytime, mp_teamlimit);
    {
        ServerCommand("mp_timelimit %d; mp_roundtime_hostages %d; mp_limitteam %d; mp_limitteams %d; mp_teamlimits %d; mp_ignore_round_win_conditions %d; mp_roundtime_deploy %d; mp_freezetime %d;",
            mp_timelimit, mp_roundtime_hostages, mp_limitteam, mp_limitteams, mp_teamlimits, mp_ignore_round_win_conditions, mp_roundtime_deploy, mp_freezetime);
        {
            ServerCommand("mp_winlimit %d; mp_maxrounds %d; mp_roundtime_deployment %d; mp_startmoney %d; mp_maxmoney %d; bot_quota %d; sv_password \"%s\";",
                mp_winlimit, mp_maxrounds, mp_roundtime_deployment, mp_startmoney, mp_maxmoney, bot_quota, sv_password);
            {
                ServerCommand("mp_restartgame %d; mp_restartgame_immediate %d;", mp_restartgame, mp_restartgame_immediate);
            }
        }
    }
}

public bool RmThis(int nPlr)
{
    static int nEntity = -1, nSpawn = -1, nNewA = 0, nNewB = 0, nItr = 0, nIdx = -1;

    static bool bTeamA = false;

    static float fPos[3] = { 0.000000, ... }, fEyePos[3] = { 0.000000, ... }, fDis = 0.000000, fDisStamp = 1711489163.000000, fPosStamp[3] = { 0.000000, ... },
        fPosCpyA[99][3], fAngCpyA[99][3], fPosCpyB[99][3], fAngCpyB[99][3];

    GetClientEyePosition(nPlr, fEyePos);
    {
        fDisStamp = 1711489163.000000;
        {
            nSpawn = -1;
        }
    }

    if (g_nEngVs != Engine_DODS)
    {
        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_counterterrorist")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                        {
                            TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                            {
                                if (m_vecOrigin > 0)
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                        {
                                            nSpawn = nEntity;
                                            {
                                                fDisStamp = fDis;
                                                {
                                                    fPosStamp[0] = fPos[0];
                                                    fPosStamp[1] = fPos[1];
                                                    fPosStamp[2] = fPos[2];
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    else
                    {
                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                        {
                            if (m_vecOrigin > 0)
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                    {
                                        nSpawn = nEntity;
                                        {
                                            fDisStamp = fDis;
                                            {
                                                fPosStamp[0] = fPos[0];
                                                fPosStamp[1] = fPos[1];
                                                fPosStamp[2] = fPos[2];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_terrorist")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                        {
                            TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                            {
                                if (m_vecOrigin > 0)
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                        {
                                            nSpawn = nEntity;
                                            {
                                                fDisStamp = fDis;
                                                {
                                                    fPosStamp[0] = fPos[0];
                                                    fPosStamp[1] = fPos[1];
                                                    fPosStamp[2] = fPos[2];
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    else
                    {
                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                        {
                            if (m_vecOrigin > 0)
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                    {
                                        nSpawn = nEntity;
                                        {
                                            fDisStamp = fDis;
                                            {
                                                fPosStamp[0] = fPos[0];
                                                fPosStamp[1] = fPos[1];
                                                fPosStamp[2] = fPos[2];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    else
    {
        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_axis")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                        {
                            TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                            {
                                if (m_vecOrigin > 0)
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                        {
                                            nSpawn = nEntity;
                                            {
                                                fDisStamp = fDis;
                                                {
                                                    fPosStamp[0] = fPos[0];
                                                    fPosStamp[1] = fPos[1];
                                                    fPosStamp[2] = fPos[2];
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    else
                    {
                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                        {
                            if (m_vecOrigin > 0)
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                    {
                                        nSpawn = nEntity;
                                        {
                                            fDisStamp = fDis;
                                            {
                                                fPosStamp[0] = fPos[0];
                                                fPosStamp[1] = fPos[1];
                                                fPosStamp[2] = fPos[2];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_allies")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                        {
                            TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                            {
                                if (m_vecOrigin > 0)
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                        {
                                            nSpawn = nEntity;
                                            {
                                                fDisStamp = fDis;
                                                {
                                                    fPosStamp[0] = fPos[0];
                                                    fPosStamp[1] = fPos[1];
                                                    fPosStamp[2] = fPos[2];
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    else
                    {
                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                        {
                            if (m_vecOrigin > 0)
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                    {
                                        nSpawn = nEntity;
                                        {
                                            fDisStamp = fDis;
                                            {
                                                fPosStamp[0] = fPos[0];
                                                fPosStamp[1] = fPos[1];
                                                fPosStamp[2] = fPos[2];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (nSpawn == -1)
    {
        return false;
    }

    nIdx = SpawnIdxAndTeamByPos(fPosStamp[0], fPosStamp[1], fPosStamp[2], bTeamA);

    if (nIdx == -1)
    {
        return false;
    }

    AcceptEntityInput(nSpawn, "KillHierarchy");
    {
        for (nItr = 0, nNewA = 0; nItr < g_nTotalA; nItr++)
        {
            if (g_fPosA[nItr][0] == fPosStamp[0] && g_fPosA[nItr][1] == fPosStamp[1] && g_fPosA[nItr][2] == fPosStamp[2])
            {
                /* ... */
            }

            else
            {
                fPosCpyA[nNewA][0] = g_fPosA[nItr][0];
                fPosCpyA[nNewA][1] = g_fPosA[nItr][1];
                fPosCpyA[nNewA][2] = g_fPosA[nItr][2];

                fAngCpyA[nNewA][0] = g_fAngA[nItr][0];
                fAngCpyA[nNewA][1] = g_fAngA[nItr][1];
                fAngCpyA[nNewA][2] = g_fAngA[nItr][2];

                nNewA++;
            }
        }

        for (nItr = 0, nNewB = 0; nItr < g_nTotalB; nItr++)
        {
            if (g_fPosB[nItr][0] == fPosStamp[0] && g_fPosB[nItr][1] == fPosStamp[1] && g_fPosB[nItr][2] == fPosStamp[2])
            {
                /* ... */
            }

            else
            {
                fPosCpyB[nNewB][0] = g_fPosB[nItr][0];
                fPosCpyB[nNewB][1] = g_fPosB[nItr][1];
                fPosCpyB[nNewB][2] = g_fPosB[nItr][2];

                fAngCpyB[nNewB][0] = g_fAngB[nItr][0];
                fAngCpyB[nNewB][1] = g_fAngB[nItr][1];
                fAngCpyB[nNewB][2] = g_fAngB[nItr][2];

                nNewB++;
            }
        }
    }

    for (nItr = 0, g_nTotalA = nNewA; nItr < nNewA; nItr++)
    {
        g_fPosA[nItr][0] = fPosCpyA[nItr][0];
        g_fPosA[nItr][1] = fPosCpyA[nItr][1];
        g_fPosA[nItr][2] = fPosCpyA[nItr][2];

        g_fAngA[nItr][0] = fAngCpyA[nItr][0];
        g_fAngA[nItr][1] = fAngCpyA[nItr][1];
        g_fAngA[nItr][2] = fAngCpyA[nItr][2];
    }

    for (nItr = 0, g_nTotalB = nNewB; nItr < nNewB; nItr++)
    {
        g_fPosB[nItr][0] = fPosCpyB[nItr][0];
        g_fPosB[nItr][1] = fPosCpyB[nItr][1];
        g_fPosB[nItr][2] = fPosCpyB[nItr][2];

        g_fAngB[nItr][0] = fAngCpyB[nItr][0];
        g_fAngB[nItr][1] = fAngCpyB[nItr][1];
        g_fAngB[nItr][2] = fAngCpyB[nItr][2];
    }

    PrintToChat(nPlr, "(#%02d %c) Pos %.1f %.1f %.1f", nIdx, bTeamA ? 'A' : 'B', fPosStamp[0], fPosStamp[1], fPosStamp[2]);
    {
        PrintToChat(nPlr, "%02d Total For Team %c", bTeamA ? nNewA : nNewB, bTeamA ? 'A' : 'B');
    }

    return true;
}

public int SpawnIdxAndTeamByPos(float fX, float fY, float fZ, bool & bTeamA)
{
    static int nItr = 0;

    bTeamA = false;

    for (nItr = 0, bTeamA = true; nItr < g_nTotalA; nItr++)
    {
        if (g_fPosA[nItr][0] == fX && g_fPosA[nItr][1] == fY && g_fPosA[nItr][2] == fZ)
        {
            return nItr;
        }
    }

    for (nItr = 0, bTeamA = false; nItr < g_nTotalB; nItr++)
    {
        if (g_fPosB[nItr][0] == fX && g_fPosB[nItr][1] == fY && g_fPosB[nItr][2] == fZ)
        {
            return nItr;
        }
    }

    return -1;
}

public bool TryThis(int nPlr)
{
    static int nEntity = -1, nSpawn = -1, nIdx = -1, nApprox = 0;

    static bool bTeamA = false;

    static float fPos[3] = { 0.000000, ... }, fAng[3] = { 0.000000, ... }, fEyePos[3] = { 0.000000, ... }, fDis = 0.000000, fDisStamp = 1711489163.000000,
        fPosStamp[3] = { 0.000000, ... }, fAngStamp[3] = { 0.000000, ... };

    GetClientEyePosition(nPlr, fEyePos);
    {
        fDisStamp = 1711489163.000000;
        {
            nSpawn = -1;
        }
    }

    if (g_nEngVs != Engine_DODS)
    {
        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_counterterrorist")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                        {
                            TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                            {
                                if (m_vecOrigin > 0)
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                        {
                                            nSpawn = nEntity;
                                            {
                                                fDisStamp = fDis;
                                                {
                                                    fPosStamp[0] = fPos[0];
                                                    fPosStamp[1] = fPos[1];
                                                    fPosStamp[2] = fPos[2];

                                                    TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                    {
                                                        if (m_angRotation > 0)
                                                        {
                                                            GetEntDataVector(nEntity, m_angRotation, fAng);
                                                            {
                                                                fAngStamp[0] = fAng[0];
                                                                fAngStamp[1] = fAng[1];
                                                                fAngStamp[2] = fAng[2];
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    else
                    {
                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                        {
                            if (m_vecOrigin > 0)
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                    {
                                        nSpawn = nEntity;
                                        {
                                            fDisStamp = fDis;
                                            {
                                                fPosStamp[0] = fPos[0];
                                                fPosStamp[1] = fPos[1];
                                                fPosStamp[2] = fPos[2];

                                                TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                {
                                                    if (m_angRotation > 0)
                                                    {
                                                        GetEntDataVector(nEntity, m_angRotation, fAng);
                                                        {
                                                            fAngStamp[0] = fAng[0];
                                                            fAngStamp[1] = fAng[1];
                                                            fAngStamp[2] = fAng[2];
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_terrorist")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                        {
                            TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                            {
                                if (m_vecOrigin > 0)
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                        {
                                            nSpawn = nEntity;
                                            {
                                                fDisStamp = fDis;
                                                {
                                                    fPosStamp[0] = fPos[0];
                                                    fPosStamp[1] = fPos[1];
                                                    fPosStamp[2] = fPos[2];

                                                    TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                    {
                                                        if (m_angRotation > 0)
                                                        {
                                                            GetEntDataVector(nEntity, m_angRotation, fAng);
                                                            {
                                                                fAngStamp[0] = fAng[0];
                                                                fAngStamp[1] = fAng[1];
                                                                fAngStamp[2] = fAng[2];
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    else
                    {
                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                        {
                            if (m_vecOrigin > 0)
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                    {
                                        nSpawn = nEntity;
                                        {
                                            fDisStamp = fDis;
                                            {
                                                fPosStamp[0] = fPos[0];
                                                fPosStamp[1] = fPos[1];
                                                fPosStamp[2] = fPos[2];

                                                TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                {
                                                    if (m_angRotation > 0)
                                                    {
                                                        GetEntDataVector(nEntity, m_angRotation, fAng);
                                                        {
                                                            fAngStamp[0] = fAng[0];
                                                            fAngStamp[1] = fAng[1];
                                                            fAngStamp[2] = fAng[2];
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    else
    {
        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_axis")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                        {
                            TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                            {
                                if (m_vecOrigin > 0)
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                        {
                                            nSpawn = nEntity;
                                            {
                                                fDisStamp = fDis;
                                                {
                                                    fPosStamp[0] = fPos[0];
                                                    fPosStamp[1] = fPos[1];
                                                    fPosStamp[2] = fPos[2];

                                                    TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                    {
                                                        if (m_angRotation > 0)
                                                        {
                                                            GetEntDataVector(nEntity, m_angRotation, fAng);
                                                            {
                                                                fAngStamp[0] = fAng[0];
                                                                fAngStamp[1] = fAng[1];
                                                                fAngStamp[2] = fAng[2];
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    else
                    {
                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                        {
                            if (m_vecOrigin > 0)
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                    {
                                        nSpawn = nEntity;
                                        {
                                            fDisStamp = fDis;
                                            {
                                                fPosStamp[0] = fPos[0];
                                                fPosStamp[1] = fPos[1];
                                                fPosStamp[2] = fPos[2];

                                                TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                {
                                                    if (m_angRotation > 0)
                                                    {
                                                        GetEntDataVector(nEntity, m_angRotation, fAng);
                                                        {
                                                            fAngStamp[0] = fAng[0];
                                                            fAngStamp[1] = fAng[1];
                                                            fAngStamp[2] = fAng[2];
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_allies")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                        {
                            TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                            {
                                if (m_vecOrigin > 0)
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                        {
                                            nSpawn = nEntity;
                                            {
                                                fDisStamp = fDis;
                                                {
                                                    fPosStamp[0] = fPos[0];
                                                    fPosStamp[1] = fPos[1];
                                                    fPosStamp[2] = fPos[2];

                                                    TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                    {
                                                        if (m_angRotation > 0)
                                                        {
                                                            GetEntDataVector(nEntity, m_angRotation, fAng);
                                                            {
                                                                fAngStamp[0] = fAng[0];
                                                                fAngStamp[1] = fAng[1];
                                                                fAngStamp[2] = fAng[2];
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    else
                    {
                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                        {
                            if (m_vecOrigin > 0)
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if ((fDis = VecDis2D(fEyePos, fPos)) < fDisStamp)
                                    {
                                        nSpawn = nEntity;
                                        {
                                            fDisStamp = fDis;
                                            {
                                                fPosStamp[0] = fPos[0];
                                                fPosStamp[1] = fPos[1];
                                                fPosStamp[2] = fPos[2];

                                                TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                {
                                                    if (m_angRotation > 0)
                                                    {
                                                        GetEntDataVector(nEntity, m_angRotation, fAng);
                                                        {
                                                            fAngStamp[0] = fAng[0];
                                                            fAngStamp[1] = fAng[1];
                                                            fAngStamp[2] = fAng[2];
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (nSpawn == -1)
    {
        return false;
    }

    nIdx = SpawnIdxAndTeamByPos(fPosStamp[0], fPosStamp[1], fPosStamp[2], bTeamA);
    {
        if (nIdx != -1)
        {
            TeleportEntity(nPlr, fPosStamp, fAngStamp, NULL_VECTOR);
            {
                PrintToChat(nPlr, "(#%02d %c) Ang 0 %d 0", nIdx, bTeamA ? 'A' : 'B', (((nApprox = RoundToNearest(fAngStamp[1])) == 180) ? (-180) : (nApprox)));
                {
                    PrintToChat(nPlr, "(#%02d %c) Pos %.1f %.1f %.1f", nIdx, bTeamA ? 'A' : 'B', fPosStamp[0], fPosStamp[1], fPosStamp[2]);
                    {
                        return true;
                    }
                }
            }
        }
    }

    return false;
}

public bool FilterPlr(int nEntity, int nCnts, int nPlr)
{
    return nPlr != nEntity;
}

public void OnConfigsExecuted()
{
    int nEntity = -1, nDirs = 0, nItr = 0;
    char szDirs[16][128], szPath[256] = { 0, ... };

    if (g_nEngVs != Engine_DODS)
    {
        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_counterterrorist")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        SetEntData(nEntity, m_fEffects, GetEntData(nEntity, m_fEffects, m_fEffectsBytes) | 32, m_fEffectsBytes, false);
                    }
                }
            }
        }

        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_terrorist")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        SetEntData(nEntity, m_fEffects, GetEntData(nEntity, m_fEffects, m_fEffectsBytes) | 32, m_fEffectsBytes, false);
                    }
                }
            }
        }
    }

    else
    {
        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_axis")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        SetEntData(nEntity, m_fEffects, GetEntData(nEntity, m_fEffects, m_fEffectsBytes) | 32, m_fEffectsBytes, false);
                    }
                }
            }
        }

        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_allies")) != -1)
            {
                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                {
                    if (m_fEffects > 0)
                    {
                        SetEntData(nEntity, m_fEffects, GetEntData(nEntity, m_fEffects, m_fEffectsBytes) | 32, m_fEffectsBytes, false);
                    }
                }
            }
        }
    }

    GetCurrentMap(szPath, sizeof szPath);
    {
        BuildPath(Path_SM, g_szPath, sizeof g_szPath, "%s.se.cfg", szPath);
        {
            ReplaceString(g_szPath, sizeof g_szPath, "\\", "/", false);
            {
                if (-1 == ReplaceStringEx(g_szPath, sizeof g_szPath, "/sourcemod/", "/stripper/maps/", 11, 15, false))
                {
                    if (-1 == ReplaceStringEx(g_szPath, sizeof g_szPath, "/source_mod/", "/stripper/maps/", 12, 15, false))
                    {
                        if (-1 == ReplaceStringEx(g_szPath, sizeof g_szPath, "/smod/", "/stripper/maps/", 6, 15, false))
                        {
                            if (-1 == ReplaceStringEx(g_szPath, sizeof g_szPath, "/s_mod/", "/stripper/maps/", 7, 15, false))
                            {
                                if (-1 == ReplaceStringEx(g_szPath, sizeof g_szPath, "/sourcem/", "/stripper/maps/", 9, 15, false))
                                {
                                    if (-1 == ReplaceStringEx(g_szPath, sizeof g_szPath, "/source_m/", "/stripper/maps/", 10, 15, false))
                                    {
                                        if (-1 == ReplaceStringEx(g_szPath, sizeof g_szPath, "/srcmod/", "/stripper/maps/", 8, 15, false))
                                        {
                                            if (-1 == ReplaceStringEx(g_szPath, sizeof g_szPath, "/src_mod/", "/stripper/maps/", 9, 15, false))
                                            {
                                                if (-1 == ReplaceStringEx(g_szPath, sizeof g_szPath, "/sm/", "/stripper/maps/", 4, 15, false))
                                                {
                                                    ReplaceStringEx(g_szPath, sizeof g_szPath, "/s_m/", "/stripper/maps/", 5, 15, false);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            nDirs = ExplodeString(g_szPath, "/", szDirs, sizeof szDirs, sizeof szDirs[], false);
            {
                if (nDirs > 0)
                {
                    szPath[0] = 0;
                    {
                        for (nItr = 0; nItr < nDirs; nItr++)
                        {
                            if (strlen(szDirs[nItr]) > 0)
                            {
                                if (StrContains(szDirs[nItr], ".cfg", false) == -1)
                                {
                                    StrCat(szPath, sizeof szPath, szDirs[nItr]);
                                    {
                                        if (!DirExists(szPath))
                                        {
                                            TryMkDir(szPath);
                                        }

                                        StrCat(szPath, sizeof szPath, "/");
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

public void OnMapStart()
{
    g_nEngVs = GetEngineVersion();

    g_nTotalA = 0;
    g_nTotalB = 0;

    g_bOnlyInBZ = false;

    if (Engine_CSGO != g_nEngVs)
    {
        g_nRed = PrecacheModel("sprites/redglow3.vmt", true);
        {
            if (g_nRed < 1)
            {
                LogError("Failed Precaching `sprites/redglow3.vmt`");
            }
        }
    }

    else
    {
        g_nRed = PrecacheModel("sprites/purpleglow1.vmt", true);
        {
            if (g_nRed < 1)
            {
                LogError("Failed Precaching `sprites/purpleglow1.vmt`");
            }
        }
    }

    g_nBlue = PrecacheModel("sprites/blueglow1.vmt", true);
    {
        if (g_nBlue < 1)
        {
            LogError("Failed Precaching `sprites/blueglow1.vmt`");
        }
    }
}

public void ApplyCustomVars()
{
    ServerCommand("mp_fraglimit 16384; mp_roundtime 16384; mp_roundtime_defuse 16384; mp_roundtime_hostage 16384; mp_roundtime_bomb 16384; mp_roundtime_rescue 16384; mp_buytime 16384; mp_teamlimit 0;");
    {
        ServerCommand("mp_timelimit 16384; mp_roundtime_hostages 16384; mp_limitteam 0; mp_limitteams 0; mp_teamlimits 0; mp_ignore_round_win_conditions 1; mp_roundtime_deploy 16384; mp_freezetime 0;");
        {
            ServerCommand("mp_winlimit 16384; mp_maxrounds 16384; mp_roundtime_deployment 16384; mp_startmoney 16384; mp_maxmoney 16384; bot_quota 0; sv_password stripperspawns; mp_warmup_end; mp_restartgame 1;");
            {
                ServerCommand("mp_restartgame_immediate 1;");
            }
        }
    }
}

public float VecDis1D(float fVecA[3], float fVecB[3])
{
    static float fTmpVecA[3] = { 0.000000, ... }, fTmpVecB[3] = { 0.000000, ... };

    fTmpVecA[0] = 0.000000;
    {
        fTmpVecA[1] = 0.000000;
        {
            fTmpVecA[2] = fVecA[2];
        }
    }

    fTmpVecB[0] = 0.000000;
    {
        fTmpVecB[1] = 0.000000;
        {
            fTmpVecB[2] = fVecB[2];
        }
    }

    return GetVectorDistance(fTmpVecA, fTmpVecB, false);
}

public float VecDis2D(float fVecA[3], float fVecB[3])
{
    static float fTmpVecA[3] = { 0.000000, ... }, fTmpVecB[3] = { 0.000000, ... };

    fTmpVecA[0] = fVecA[0];
    {
        fTmpVecA[1] = fVecA[1];
        {
            fTmpVecA[2] = 0.000000;
        }
    }

    fTmpVecB[0] = fVecB[0];
    {
        fTmpVecB[1] = fVecB[1];
        {
            fTmpVecB[2] = 0.000000;
        }
    }

    return GetVectorDistance(fTmpVecA, fTmpVecB, false);
}

public bool GoodDisToSpawnEntry(int nPlr)
{
    static int nEntity = -1;
    static float fPos[3] = { 0.000000, ... }, fEyePos[3] = { 0.000000, ... }, fPlrPos[3] = { 0.000000, ... };

    GetClientEyePosition(nPlr, fEyePos);
    {
        GetClientAbsOrigin(nPlr, fPlrPos);
    }

    if (g_nEngVs != Engine_DODS)
    {
        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_counterterrorist")) != -1)
            {
                TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                {
                    if (m_vecOrigin > 0)
                    {
                        GetEntDataVector(nEntity, m_vecOrigin, fPos);
                        {
                            if (VecDis2D(fPlrPos, fPos) <= 48.000000 || VecDis2D(fEyePos, fPos) <= 48.000000)
                            {
                                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                                {
                                    if (m_fEffects > 0)
                                    {
                                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                        {
                                            return false;
                                        }
                                    }

                                    else
                                    {
                                        return false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_terrorist")) != -1)
            {
                TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                {
                    if (m_vecOrigin > 0)
                    {
                        GetEntDataVector(nEntity, m_vecOrigin, fPos);
                        {
                            if (VecDis2D(fPlrPos, fPos) <= 48.000000 || VecDis2D(fEyePos, fPos) <= 48.000000)
                            {
                                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                                {
                                    if (m_fEffects > 0)
                                    {
                                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                        {
                                            return false;
                                        }
                                    }

                                    else
                                    {
                                        return false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    else
    {
        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_axis")) != -1)
            {
                TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                {
                    if (m_vecOrigin > 0)
                    {
                        GetEntDataVector(nEntity, m_vecOrigin, fPos);
                        {
                            if (VecDis2D(fPlrPos, fPos) <= 48.000000 || VecDis2D(fEyePos, fPos) <= 48.000000)
                            {
                                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                                {
                                    if (m_fEffects > 0)
                                    {
                                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                        {
                                            return false;
                                        }
                                    }

                                    else
                                    {
                                        return false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_allies")) != -1)
            {
                TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                {
                    if (m_vecOrigin > 0)
                    {
                        GetEntDataVector(nEntity, m_vecOrigin, fPos);
                        {
                            if (VecDis2D(fPlrPos, fPos) <= 48.000000 || VecDis2D(fEyePos, fPos) <= 48.000000)
                            {
                                TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                                {
                                    if (m_fEffects > 0)
                                    {
                                        if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                        {
                                            return false;
                                        }
                                    }

                                    else
                                    {
                                        return false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return true;
}

public Action TmrGlow(Handle hTmr, any nData)
{
    static int nEntity = -1;
    static float fPos[3] = { 0.000000, ... };

    if (!g_bActive)
    {
        return Plugin_Stop;
    }

    if (g_nEngVs != Engine_DODS)
    {
        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_counterterrorist")) != -1)
            {
                TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                {
                    if (m_vecOrigin > 0)
                    {
                        TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                        {
                            if (m_fEffects > 0)
                            {
                                if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if (g_nBlue > 0)
                                        {
                                            TE_SetupGlowSprite(fPos, g_nBlue, 1.000000, 0.300000, 180);
                                            {
                                                TE_SendToAll();
                                            }
                                        }
                                    }
                                }
                            }

                            else
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if (g_nBlue > 0)
                                    {
                                        TE_SetupGlowSprite(fPos, g_nBlue, 1.000000, 0.300000, 180);
                                        {
                                            TE_SendToAll();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_terrorist")) != -1)
            {
                TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                {
                    if (m_vecOrigin > 0)
                    {
                        TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                        {
                            if (m_fEffects > 0)
                            {
                                if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if (g_nRed > 0)
                                        {
                                            TE_SetupGlowSprite(fPos, g_nRed, 1.000000, 0.300000, 180);
                                            {
                                                TE_SendToAll();
                                            }
                                        }
                                    }
                                }
                            }

                            else
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if (g_nRed > 0)
                                    {
                                        TE_SetupGlowSprite(fPos, g_nRed, 1.000000, 0.300000, 180);
                                        {
                                            TE_SendToAll();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    else
    {
        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_axis")) != -1)
            {
                TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                {
                    if (m_vecOrigin > 0)
                    {
                        TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                        {
                            if (m_fEffects > 0)
                            {
                                if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if (g_nRed > 0)
                                        {
                                            TE_SetupGlowSprite(fPos, g_nRed, 1.000000, 0.300000, 180);
                                            {
                                                TE_SendToAll();
                                            }
                                        }
                                    }
                                }
                            }

                            else
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if (g_nRed > 0)
                                    {
                                        TE_SetupGlowSprite(fPos, g_nRed, 1.000000, 0.300000, 180);
                                        {
                                            TE_SendToAll();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        nEntity = -1;
        {
            while ((nEntity = FindEntityByClassname(nEntity, "info_player_allies")) != -1)
            {
                TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                {
                    if (m_vecOrigin > 0)
                    {
                        TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                        {
                            if (m_fEffects > 0)
                            {
                                if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                {
                                    GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                    {
                                        if (g_nBlue > 0)
                                        {
                                            TE_SetupGlowSprite(fPos, g_nBlue, 1.000000, 0.300000, 180);
                                            {
                                                TE_SendToAll();
                                            }
                                        }
                                    }
                                }
                            }

                            else
                            {
                                GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                {
                                    if (g_nBlue > 0)
                                    {
                                        TE_SetupGlowSprite(fPos, g_nBlue, 1.000000, 0.300000, 180);
                                        {
                                            TE_SendToAll();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

public bool GoodDisToWall(int nPlr)
{
    static float fEyePos[3] = { 0.000000, ... }, fPlrPos[3] = { 0.000000, ... }, fAng[3] = { 0.000000, ... }, fPos[3] = { 0.000000, ... }, fYaw = 0.000000, fOffs = 0.000000;

    GetClientEyePosition(nPlr, fEyePos);
    {
        GetClientAbsOrigin(nPlr, fPlrPos);
        {
            fAng[0] = 0.000000;
            {
                fAng[1] = 0.000000;
                {
                    fAng[2] = 0.000000;
                }
            }
        }
    }

    fOffs = ((fEyePos[2] - fPlrPos[2]) / 2.000000);
    {
        fPlrPos[2] += fOffs;
        {
            for (fYaw = -179.999999; fYaw <= 169.999999; fYaw += 10.000000)
            {
                fAng[1] = fYaw;
                {
                    TR_TraceRayFilter(fEyePos, fAng, 1711489163, RayType_Infinite, FilterPlr, nPlr);
                    {
                        TR_GetEndPosition(fPos);
                        {
                            if (VecDis2D(fEyePos, fPos) <= 48.000000)
                            {
                                return false;
                            }
                        }
                    }

                    TR_TraceRayFilter(fPlrPos, fAng, 1711489163, RayType_Infinite, FilterPlr, nPlr);
                    {
                        TR_GetEndPosition(fPos);
                        {
                            if (VecDis2D(fPlrPos, fPos) <= 48.000000)
                            {
                                return false;
                            }
                        }
                    }
                }
            }
        }
    }

    if (fOffs != 16.000000)
    {
        fPlrPos[2] -= fOffs;
        {
            fPlrPos[2] += 16.000000;
            {
                for (fYaw = -179.999999; fYaw <= 169.999999; fYaw += 10.000000)
                {
                    fAng[1] = fYaw;
                    {
                        TR_TraceRayFilter(fPlrPos, fAng, 1711489163, RayType_Infinite, FilterPlr, nPlr);
                        {
                            TR_GetEndPosition(fPos);
                            {
                                if (VecDis2D(fPlrPos, fPos) <= 48.000000)
                                {
                                    return false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (fOffs != 8.000000)
    {
        fPlrPos[2] -= ((fOffs == 16.000000) ? (fOffs) : (16.000000));
        {
            fPlrPos[2] += 8.000000;
            {
                for (fYaw = -179.999999; fYaw <= 169.999999; fYaw += 10.000000)
                {
                    fAng[1] = fYaw;
                    {
                        TR_TraceRayFilter(fPlrPos, fAng, 1711489163, RayType_Infinite, FilterPlr, nPlr);
                        {
                            TR_GetEndPosition(fPos);
                            {
                                if (VecDis2D(fPlrPos, fPos) <= 48.000000)
                                {
                                    return false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    fAng[0] = -88.999999;
    {
        fAng[1] = 0.000000;
        {
            fAng[2] = 0.000000;
            {
                TR_TraceRayFilter(fEyePos, fAng, 1711489163, RayType_Infinite, FilterPlr, nPlr);
                {
                    TR_GetEndPosition(fPos);
                    {
                        if (VecDis1D(fEyePos, fPos) <= 48.000000)
                        {
                            return false;
                        }
                    }
                }
            }
        }
    }

    return true;
}

public void TryMkDir(char[] szDir)
{
    static int nItr = 0;

    for (nItr = 511; nItr > -2; nItr--)
    {
        if (CreateDirectory(szDir, nItr))
        {
            break;
        }
    }
}

public void TryOnceReadOffs(int nEntity, char[] szItm, int & nOffs)
{
    static int nItr = 0;
    {
        if (nOffs < 1)
        {
            if (nEntity != -1)
            {
                nOffs = FindDataMapInfo(nEntity, szItm);
                {
                    if (nOffs < 1)
                    {
                        for (nItr = 0; nItr < sizeof g_szTbls; nItr++)
                        {
                            nOffs = FindSendPropInfo(g_szTbls[nItr], szItm);
                            {
                                if (nOffs > 0)
                                {
                                    return;
                                }
                            }
                        }
                    }
                }
            }

            else
            {
                for (nItr = 0; nItr < sizeof g_szTbls; nItr++)
                {
                    nOffs = FindSendPropInfo(g_szTbls[nItr], szItm);
                    {
                        if (nOffs > 0)
                        {
                            return;
                        }
                    }
                }
            }
        }
    }
}

public void TryOnceReadOffsComplex(int nEntity, char[] szItm, int & nOffs, int & nBytes)
{
    static int nItr = 0, nBits = 0;
    {
        if (nOffs < 1)
        {
            if (nEntity != -1)
            {
                nOffs = FindDataMapInfo(nEntity, szItm, _, nBits);
                {
                    if (nOffs < 1)
                    {
                        for (nItr = 0; nItr < sizeof g_szTbls; nItr++)
                        {
                            nOffs = FindSendPropInfo(g_szTbls[nItr], szItm, _, nBits);
                            {
                                if (nOffs > 0)
                                {
                                    nBytes = ((nBits < 9) ? (1) : ((nBits < 17) ? (2) : (4)));
                                    {
                                        return;
                                    }
                                }
                            }
                        }
                    }

                    else
                    {
                        nBytes = ((nBits < 9) ? (1) : ((nBits < 17) ? (2) : (4)));
                    }
                }
            }

            else
            {
                for (nItr = 0; nItr < sizeof g_szTbls; nItr++)
                {
                    nOffs = FindSendPropInfo(g_szTbls[nItr], szItm, _, nBits);
                    {
                        if (nOffs > 0)
                        {
                            nBytes = ((nBits < 9) ? (1) : ((nBits < 17) ? (2) : (4)));
                            {
                                return;
                            }
                        }
                    }
                }
            }
        }
    }
}

public void SkipMultiSpaces(char[] szItm)
{
    static int nItr = 0;
    {
        static int nLen = 0;
        {
            static int nChr = 0;
            {
                static char cTmp = 0;
                {
                    nLen = strlen(szItm);
                    {
                        if (nLen > 0)
                        {
                            char[] szTmp = new char[nLen];
                            {
                                if (!(!szTmp))
                                {
                                    for (nItr = 0, nChr = 0, cTmp = ' '; nItr < nLen; nItr++)
                                    {
                                        if (szItm[nItr] == '\t')
                                        {
                                            szItm[nItr] = ' ';
                                        }

                                        if (szItm[nItr] != ' ' || cTmp != ' ')
                                        {
                                            szTmp[nChr++] = szItm[nItr];
                                            {
                                                cTmp = szItm[nItr];
                                            }
                                        }
                                    }

                                    if (nChr > 0)
                                    {
                                        szTmp[nChr] = 0;

                                        if (szTmp[nChr - 1] == ' ')
                                        {
                                            szTmp[--nChr] = 0;
                                        }

                                        if (nChr > 0)
                                        {
                                            strcopy(szItm, nChr + 1, szTmp);
                                        }

                                        else
                                        {
                                            szItm[0] = 0;
                                        }
                                    }

                                    else
                                    {
                                        szItm[0] = 0;
                                    }
                                }

                                else
                                {
                                    szItm[0] = 0;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

public Action OnClientSayCommand(int nPlr, const char[] szCmd, const char[] szArg)
{
    static int nEntity = -1, nItr = 0, nStamp = 0, nTime = 0, nArgs = 0, nId = 0, nTeam = 0, nApprox = 0;
    static Handle hFile = null;
    static char szArgs[4][128], szTmp[256] = { 0, ... };
    static float fPos[3] = { 0.000000, ... }, fAng[3] = { 0.000000, ... }, fApprox = 0.000000;

    if (nPlr > 0)
    {
        if (nPlr < 66)
        {
            if (MaxClients < 1 || nPlr <= MaxClients)
            {
                if (IsClientConnected(nPlr))
                {
                    if (IsClientInGame(nPlr))
                    {
                        if (!IsFakeClient(nPlr))
                        {
                            if (IsClientAuthorized(nPlr))
                            {
                                if (IsPlayerAlive(nPlr))
                                {
                                    if (GetUserFlagBits(nPlr) & 16384)
                                    {
                                        if (strncmp(szArg, "st", 2, false) == 0)
                                        {
                                            nId = -1;
                                            {
                                                nTeam = -1;
                                                {
                                                    nItr = -1;
                                                    {
                                                        strcopy(szTmp, sizeof szTmp, szArg);
                                                        {
                                                            SkipMultiSpaces(szTmp);
                                                            {
                                                                nArgs = ExplodeString(szTmp, " ", szArgs, sizeof szArgs, sizeof szArgs[], false);
                                                                {
                                                                    if (nArgs > 2)
                                                                    {
                                                                        nId = StringToInt(szArgs[1]);
                                                                        {
                                                                            if (nId > -1)
                                                                            {
                                                                                if (nId < 99)
                                                                                {
                                                                                    nTeam = ((szArgs[2][0] == 'A' || szArgs[2][0] == 'a') ? (0) : (1));
                                                                                    {
                                                                                        if (nTeam > -1)
                                                                                        {
                                                                                            if (nTeam < 2)
                                                                                            {
                                                                                                if (g_nEngVs == Engine_DODS)
                                                                                                {
                                                                                                    if (nTeam < 1)
                                                                                                    {
                                                                                                        nEntity = -1;
                                                                                                        {
                                                                                                            nItr = 0;
                                                                                                            {
                                                                                                                while ((nEntity = FindEntityByClassname(nEntity, "info_player_allies")) != -1)
                                                                                                                {
                                                                                                                    if (nItr == nId)
                                                                                                                    {
                                                                                                                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                                                                                                                        {
                                                                                                                            if (m_vecOrigin > 0)
                                                                                                                            {
                                                                                                                                TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                                                                                                {
                                                                                                                                    if (m_angRotation > 0)
                                                                                                                                    {
                                                                                                                                        GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                                                                                                                        {
                                                                                                                                            GetEntDataVector(nEntity, m_angRotation, fAng);
                                                                                                                                            {
                                                                                                                                                TeleportEntity(nPlr, fPos, fAng, NULL_VECTOR);
                                                                                                                                                {
                                                                                                                                                    PrintToChat(nPlr, "(#%02d %c) Ang 0 %d 0", nItr, nTeam < 1 ? 'A' : 'B',
                                                                                                                                                        (((nApprox = RoundToNearest(fAng[1])) == 180) ? (-180) : (nApprox)));
                                                                                                                                                    {
                                                                                                                                                        PrintToChat(nPlr, "(#%02d %c) Pos %.1f %.1f %.1f",
                                                                                                                                                            nItr, nTeam < 1 ? 'A' : 'B', fPos[0], fPos[1], fPos[2]);
                                                                                                                                                        {
                                                                                                                                                            return Plugin_Handled;
                                                                                                                                                        }
                                                                                                                                                    }
                                                                                                                                                }
                                                                                                                                            }
                                                                                                                                        }
                                                                                                                                    }
                                                                                                                                }
                                                                                                                            }
                                                                                                                        }

                                                                                                                        break;
                                                                                                                    }

                                                                                                                    nItr++;
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                    }

                                                                                                    else
                                                                                                    {
                                                                                                        nEntity = -1;
                                                                                                        {
                                                                                                            nItr = 0;
                                                                                                            {
                                                                                                                while ((nEntity = FindEntityByClassname(nEntity, "info_player_axis")) != -1)
                                                                                                                {
                                                                                                                    if (nItr == nId)
                                                                                                                    {
                                                                                                                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                                                                                                                        {
                                                                                                                            if (m_vecOrigin > 0)
                                                                                                                            {
                                                                                                                                TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                                                                                                {
                                                                                                                                    if (m_angRotation > 0)
                                                                                                                                    {
                                                                                                                                        GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                                                                                                                        {
                                                                                                                                            GetEntDataVector(nEntity, m_angRotation, fAng);
                                                                                                                                            {
                                                                                                                                                TeleportEntity(nPlr, fPos, fAng, NULL_VECTOR);
                                                                                                                                                {
                                                                                                                                                    PrintToChat(nPlr, "(#%02d %c) Ang 0 %d 0", nItr, nTeam < 1 ? 'A' : 'B',
                                                                                                                                                        (((nApprox = RoundToNearest(fAng[1])) == 180) ? (-180) : (nApprox)));
                                                                                                                                                    {
                                                                                                                                                        PrintToChat(nPlr, "(#%02d %c) Pos %.1f %.1f %.1f",
                                                                                                                                                            nItr, nTeam < 1 ? 'A' : 'B', fPos[0], fPos[1], fPos[2]);
                                                                                                                                                        {
                                                                                                                                                            return Plugin_Handled;
                                                                                                                                                        }
                                                                                                                                                    }
                                                                                                                                                }
                                                                                                                                            }
                                                                                                                                        }
                                                                                                                                    }
                                                                                                                                }
                                                                                                                            }
                                                                                                                        }

                                                                                                                        break;
                                                                                                                    }

                                                                                                                    nItr++;
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }

                                                                                                else
                                                                                                {
                                                                                                    if (nTeam < 1)
                                                                                                    {
                                                                                                        nEntity = -1;
                                                                                                        {
                                                                                                            nItr = 0;
                                                                                                            {
                                                                                                                while ((nEntity = FindEntityByClassname(nEntity, "info_player_terrorist")) != -1)
                                                                                                                {
                                                                                                                    if (nItr == nId)
                                                                                                                    {
                                                                                                                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                                                                                                                        {
                                                                                                                            if (m_vecOrigin > 0)
                                                                                                                            {
                                                                                                                                TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                                                                                                {
                                                                                                                                    if (m_angRotation > 0)
                                                                                                                                    {
                                                                                                                                        GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                                                                                                                        {
                                                                                                                                            GetEntDataVector(nEntity, m_angRotation, fAng);
                                                                                                                                            {
                                                                                                                                                TeleportEntity(nPlr, fPos, fAng, NULL_VECTOR);
                                                                                                                                                {
                                                                                                                                                    PrintToChat(nPlr, "(#%02d %c) Ang 0 %d 0", nItr, nTeam < 1 ? 'A' : 'B',
                                                                                                                                                        (((nApprox = RoundToNearest(fAng[1])) == 180) ? (-180) : (nApprox)));
                                                                                                                                                    {
                                                                                                                                                        PrintToChat(nPlr, "(#%02d %c) Pos %.1f %.1f %.1f",
                                                                                                                                                            nItr, nTeam < 1 ? 'A' : 'B', fPos[0], fPos[1], fPos[2]);
                                                                                                                                                        {
                                                                                                                                                            return Plugin_Handled;
                                                                                                                                                        }
                                                                                                                                                    }
                                                                                                                                                }
                                                                                                                                            }
                                                                                                                                        }
                                                                                                                                    }
                                                                                                                                }
                                                                                                                            }
                                                                                                                        }

                                                                                                                        break;
                                                                                                                    }

                                                                                                                    nItr++;
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                    }

                                                                                                    else
                                                                                                    {
                                                                                                        nEntity = -1;
                                                                                                        {
                                                                                                            nItr = 0;
                                                                                                            {
                                                                                                                while ((nEntity = FindEntityByClassname(nEntity, "info_player_counterterrorist")) != -1)
                                                                                                                {
                                                                                                                    if (nItr == nId)
                                                                                                                    {
                                                                                                                        TryOnceReadOffs(nEntity, "m_vecOrigin", m_vecOrigin);
                                                                                                                        {
                                                                                                                            if (m_vecOrigin > 0)
                                                                                                                            {
                                                                                                                                TryOnceReadOffs(nEntity, "m_angRotation", m_angRotation);
                                                                                                                                {
                                                                                                                                    if (m_angRotation > 0)
                                                                                                                                    {
                                                                                                                                        GetEntDataVector(nEntity, m_vecOrigin, fPos);
                                                                                                                                        {
                                                                                                                                            GetEntDataVector(nEntity, m_angRotation, fAng);
                                                                                                                                            {
                                                                                                                                                TeleportEntity(nPlr, fPos, fAng, NULL_VECTOR);
                                                                                                                                                {
                                                                                                                                                    PrintToChat(nPlr, "(#%02d %c) Ang 0 %d 0", nItr, nTeam < 1 ? 'A' : 'B',
                                                                                                                                                        (((nApprox = RoundToNearest(fAng[1])) == 180) ? (-180) : (nApprox)));
                                                                                                                                                    {
                                                                                                                                                        PrintToChat(nPlr, "(#%02d %c) Pos %.1f %.1f %.1f",
                                                                                                                                                            nItr, nTeam < 1 ? 'A' : 'B', fPos[0], fPos[1], fPos[2]);
                                                                                                                                                        {
                                                                                                                                                            return Plugin_Handled;
                                                                                                                                                        }
                                                                                                                                                    }
                                                                                                                                                }
                                                                                                                                            }
                                                                                                                                        }
                                                                                                                                    }
                                                                                                                                }
                                                                                                                            }
                                                                                                                        }

                                                                                                                        break;
                                                                                                                    }

                                                                                                                    nItr++;
                                                                                                                }
                                                                                                            }
                                                                                                        }
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            if (!nItr)
                                            {
                                                PrintToChat(nPlr, "Internal Error");
                                            }

                                            else if (nId > -1 && nId < 99 && nTeam > -1 && nTeam < 2 && nItr > -1)
                                            {
                                                PrintToChat(nPlr, "%d Is Final Spawn Index For %c", nItr - 1, nTeam < 1 ? 'A' : 'B');
                                                {
                                                    PrintToChat(nPlr, "%d Total Spawns For %c", nItr, nTeam < 1 ? 'A' : 'B');
                                                }
                                            }

                                            else
                                            {
                                                PrintToChat(nPlr, "Try ST <0..98> <A..B>");
                                            }

                                            return Plugin_Handled;
                                        }

                                        else if (strcmp(szArg, "sxr", false) == 0)
                                        {
                                            if (!g_bActive)
                                            {
                                                PrintToChat(nPlr, "Type SPAWNS Before");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            if (!RmThis(nPlr))
                                            {
                                                PrintToChat(nPlr, "Error Deleting Spawn Entry");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            return Plugin_Handled;
                                        }

                                        else if (strcmp(szArg, "sxt", false) == 0)
                                        {
                                            if (!g_bActive)
                                            {
                                                PrintToChat(nPlr, "Type SPAWNS Before");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            if (!TryThis(nPlr))
                                            {
                                                PrintToChat(nPlr, "Error Trying Spawn Entry");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            return Plugin_Handled;
                                        }

                                        else if (strcmp(szArg, "s1", false) == 0)
                                        {
                                            if (!g_bActive)
                                            {
                                                PrintToChat(nPlr, "Type SPAWNS Before");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            if (g_nTotalA > 98)
                                            {
                                                PrintToChat(nPlr, "Team A Already Full");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            TryOnceReadOffsComplex(nPlr, "m_fFlags", m_fFlags, m_fFlagsBytes);
                                            {
                                                if (m_fFlags > 0)
                                                {
                                                    if (!(GetEntData(nPlr, m_fFlags, m_fFlagsBytes) & 1))
                                                    {
                                                        PrintToChat(nPlr, "You Should Be On Ground");
                                                        {
                                                            return Plugin_Handled;
                                                        }
                                                    }

                                                    if (GetEntData(nPlr, m_fFlags, m_fFlagsBytes) & 2)
                                                    {
                                                        PrintToChat(nPlr, "You Should Not Be Crouched");
                                                        {
                                                            return Plugin_Handled;
                                                        }
                                                    }
                                                }
                                            }

                                            TryOnceReadOffsComplex(nPlr, "m_nButtons", m_nButtons, m_nButtonsBytes);
                                            {
                                                if (m_nButtons > 0)
                                                {
                                                    if (GetEntData(nPlr, m_nButtons, m_nButtonsBytes) & 2)
                                                    {
                                                        PrintToChat(nPlr, "You Should Not Be Jumping");
                                                        {
                                                            return Plugin_Handled;
                                                        }
                                                    }

                                                    if (GetEntData(nPlr, m_nButtons, m_nButtonsBytes) & 4)
                                                    {
                                                        PrintToChat(nPlr, "You Should Not Be Ducking");
                                                        {
                                                            return Plugin_Handled;
                                                        }
                                                    }
                                                }
                                            }

                                            if (Engine_DODS != g_nEngVs)
                                            {
                                                if (g_bOnlyInBZ)
                                                {
                                                    TryOnceReadOffsComplex(nPlr, "m_bInBuyZone", m_bInBZ, m_bInBZBytes);
                                                    {
                                                        if (m_bInBZ > 0)
                                                        {
                                                            if (!GetEntData(nPlr, m_bInBZ, m_bInBZBytes))
                                                            {
                                                                PrintToChat(nPlr, "Outside Of Buy Zone");
                                                                {
                                                                    return Plugin_Handled;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            if (GoodDisToWall(nPlr))
                                            {
                                                if (GoodDisToSpawnEntry(nPlr))
                                                {
                                                    GetClientAbsOrigin(nPlr, g_fPosA[g_nTotalA]);
                                                    {
                                                        GetClientEyeAngles(nPlr, g_fAngA[g_nTotalA]);
                                                        {
                                                            g_fPosA[g_nTotalA][2] += 16.000000;
                                                            {
                                                                g_fAngA[g_nTotalA][0] = 0.000000;
                                                                {
                                                                    g_fAngA[g_nTotalA][2] = 0.000000;
                                                                    {
                                                                        nApprox = RoundToNearest(g_fAngA[g_nTotalA][1]);
                                                                        {
                                                                            fApprox = float(nApprox);
                                                                            {
                                                                                g_fAngA[g_nTotalA][1] = ((nApprox == 180) ? (-180.000000) : (fApprox));
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    nEntity = CreateEntityByName(Engine_DODS == g_nEngVs ? "info_player_allies" : "info_player_terrorist");
                                                    {
                                                        if (nEntity != -1)
                                                        {
                                                            if (DispatchSpawn(nEntity))
                                                            {
                                                                TeleportEntity(nEntity, g_fPosA[g_nTotalA], g_fAngA[g_nTotalA], NULL_VECTOR);
                                                                {
                                                                    g_nTotalA++;
                                                                    {
                                                                        PrintToChat(nPlr, "Added Spawn #%02d (Team A)", g_nTotalA);
                                                                    }
                                                                }
                                                            }

                                                            else
                                                            {
                                                                AcceptEntityInput(nEntity, "KillHierarchy");
                                                                {
                                                                    PrintToChat(nPlr, "Internal Error");
                                                                }
                                                            }
                                                        }

                                                        else
                                                        {
                                                            PrintToChat(nPlr, "Internal Error");
                                                        }
                                                    }
                                                }

                                                else
                                                {
                                                    PrintToChat(nPlr, "Distance Between Spawns Error");
                                                }
                                            }

                                            else
                                            {
                                                PrintToChat(nPlr, "Wall Distance Error");
                                            }

                                            return Plugin_Handled;
                                        }

                                        else if (strcmp(szArg, "s2", false) == 0)
                                        {
                                            if (!g_bActive)
                                            {
                                                PrintToChat(nPlr, "Type SPAWNS Before");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            if (g_nTotalB > 98)
                                            {
                                                PrintToChat(nPlr, "Team B Already Full");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            TryOnceReadOffsComplex(nPlr, "m_fFlags", m_fFlags, m_fFlagsBytes);
                                            {
                                                if (m_fFlags > 0)
                                                {
                                                    if (!(GetEntData(nPlr, m_fFlags, m_fFlagsBytes) & 1))
                                                    {
                                                        PrintToChat(nPlr, "You Should Be On Ground");
                                                        {
                                                            return Plugin_Handled;
                                                        }
                                                    }

                                                    if (GetEntData(nPlr, m_fFlags, m_fFlagsBytes) & 2)
                                                    {
                                                        PrintToChat(nPlr, "You Should Not Be Crouched");
                                                        {
                                                            return Plugin_Handled;
                                                        }
                                                    }
                                                }
                                            }

                                            TryOnceReadOffsComplex(nPlr, "m_nButtons", m_nButtons, m_nButtonsBytes);
                                            {
                                                if (m_nButtons > 0)
                                                {
                                                    if (GetEntData(nPlr, m_nButtons, m_nButtonsBytes) & 2)
                                                    {
                                                        PrintToChat(nPlr, "You Should Not Be Jumping");
                                                        {
                                                            return Plugin_Handled;
                                                        }
                                                    }

                                                    if (GetEntData(nPlr, m_nButtons, m_nButtonsBytes) & 4)
                                                    {
                                                        PrintToChat(nPlr, "You Should Not Be Ducking");
                                                        {
                                                            return Plugin_Handled;
                                                        }
                                                    }
                                                }
                                            }

                                            if (Engine_DODS != g_nEngVs)
                                            {
                                                if (g_bOnlyInBZ)
                                                {
                                                    TryOnceReadOffsComplex(nPlr, "m_bInBuyZone", m_bInBZ, m_bInBZBytes);
                                                    {
                                                        if (m_bInBZ > 0)
                                                        {
                                                            if (!GetEntData(nPlr, m_bInBZ, m_bInBZBytes))
                                                            {
                                                                PrintToChat(nPlr, "Outside Of Buy Zone");
                                                                {
                                                                    return Plugin_Handled;
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            if (GoodDisToWall(nPlr))
                                            {
                                                if (GoodDisToSpawnEntry(nPlr))
                                                {
                                                    GetClientAbsOrigin(nPlr, g_fPosB[g_nTotalB]);
                                                    {
                                                        GetClientEyeAngles(nPlr, g_fAngB[g_nTotalB]);
                                                        {
                                                            g_fPosB[g_nTotalB][2] += 16.000000;
                                                            {
                                                                g_fAngB[g_nTotalB][0] = 0.000000;
                                                                {
                                                                    g_fAngB[g_nTotalB][2] = 0.000000;
                                                                    {
                                                                        nApprox = RoundToNearest(g_fAngB[g_nTotalB][1]);
                                                                        {
                                                                            fApprox = float(nApprox);
                                                                            {
                                                                                g_fAngB[g_nTotalB][1] = ((nApprox == 180) ? (-180.000000) : (fApprox));
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    nEntity = CreateEntityByName(Engine_DODS == g_nEngVs ? "info_player_axis" : "info_player_counterterrorist");
                                                    {
                                                        if (nEntity != -1)
                                                        {
                                                            if (DispatchSpawn(nEntity))
                                                            {
                                                                TeleportEntity(nEntity, g_fPosB[g_nTotalB], g_fAngB[g_nTotalB], NULL_VECTOR);
                                                                {
                                                                    g_nTotalB++;
                                                                    {
                                                                        PrintToChat(nPlr, "Added Spawn #%02d (Team B)", g_nTotalB);
                                                                    }
                                                                }
                                                            }

                                                            else
                                                            {
                                                                AcceptEntityInput(nEntity, "KillHierarchy");
                                                                {
                                                                    PrintToChat(nPlr, "Internal Error");
                                                                }
                                                            }
                                                        }

                                                        else
                                                        {
                                                            PrintToChat(nPlr, "Internal Error");
                                                        }
                                                    }
                                                }

                                                else
                                                {
                                                    PrintToChat(nPlr, "Distance Between Spawns Error");
                                                }
                                            }

                                            else
                                            {
                                                PrintToChat(nPlr, "Wall Distance Error");
                                            }

                                            return Plugin_Handled;
                                        }

                                        else if (strcmp(szArg, "sr", false) == 0)
                                        {
                                            if (!g_bActive)
                                            {
                                                PrintToChat(nPlr, "Type SPAWNS Before");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            if (g_nEngVs != Engine_DODS)
                                            {
                                                nEntity = -1;
                                                {
                                                    while ((nEntity = FindEntityByClassname(nEntity, "info_player_counterterrorist")) != -1)
                                                    {
                                                        TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                                                        {
                                                            if (m_fEffects > 0)
                                                            {
                                                                if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                                                {
                                                                    AcceptEntityInput(nEntity, "KillHierarchy");
                                                                }
                                                            }

                                                            else
                                                            {
                                                                AcceptEntityInput(nEntity, "KillHierarchy");
                                                            }
                                                        }
                                                    }
                                                }

                                                nEntity = -1;
                                                {
                                                    while ((nEntity = FindEntityByClassname(nEntity, "info_player_terrorist")) != -1)
                                                    {
                                                        TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                                                        {
                                                            if (m_fEffects > 0)
                                                            {
                                                                if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                                                {
                                                                    AcceptEntityInput(nEntity, "KillHierarchy");
                                                                }
                                                            }

                                                            else
                                                            {
                                                                AcceptEntityInput(nEntity, "KillHierarchy");
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            else
                                            {
                                                nEntity = -1;
                                                {
                                                    while ((nEntity = FindEntityByClassname(nEntity, "info_player_axis")) != -1)
                                                    {
                                                        TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                                                        {
                                                            if (m_fEffects > 0)
                                                            {
                                                                if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                                                {
                                                                    AcceptEntityInput(nEntity, "KillHierarchy");
                                                                }
                                                            }

                                                            else
                                                            {
                                                                AcceptEntityInput(nEntity, "KillHierarchy");
                                                            }
                                                        }
                                                    }
                                                }

                                                nEntity = -1;
                                                {
                                                    while ((nEntity = FindEntityByClassname(nEntity, "info_player_allies")) != -1)
                                                    {
                                                        TryOnceReadOffsComplex(nEntity, "m_fEffects", m_fEffects, m_fEffectsBytes);
                                                        {
                                                            if (m_fEffects > 0)
                                                            {
                                                                if (!(GetEntData(nEntity, m_fEffects, m_fEffectsBytes) & 32))
                                                                {
                                                                    AcceptEntityInput(nEntity, "KillHierarchy");
                                                                }
                                                            }

                                                            else
                                                            {
                                                                AcceptEntityInput(nEntity, "KillHierarchy");
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            g_nTotalA = 0;
                                            g_nTotalB = 0;

                                            PrintToChat(nPlr, "All Spawns Removed");

                                            return Plugin_Handled;
                                        }

                                        else if (strcmp(szArg, "spawns", false) == 0)
                                        {
                                            nTime = GetTime();
                                            {
                                                if (nTime - nStamp > 2)
                                                {
                                                    nStamp = nTime;
                                                    {
                                                        g_bActive = !g_bActive;
                                                        {
                                                            if (g_bActive)
                                                            {
                                                                PrintToChat(nPlr, "*ENABLED* Custom Spawn Entries Mode");
                                                                {
                                                                    ParseOrgVars();
                                                                    {
                                                                        ApplyCustomVars();
                                                                        {
                                                                            CreateTimer(1.000000, TmrGlow, 0, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
                                                                            {
                                                                                PrintToChat(nPlr, "S1 S2 SR SS SN SB ST SXR SXT");
                                                                                {
                                                                                    CreateTimer(0.200000, TmrAng, GetClientUserId(nPlr), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }

                                                            else
                                                            {
                                                                PrintToChat(nPlr, "*DISABLED* Custom Spawn Entries Mode");
                                                                {
                                                                    RestoreOrgVars();
                                                                }
                                                            }
                                                        }
                                                    }
                                                }

                                                else
                                                {
                                                    PrintToChat(nPlr, "Allow A Few Seconds");
                                                }
                                            }

                                            return Plugin_Handled;
                                        }

                                        else if (strcmp(szArg, "sn", false) == 0)
                                        {
                                            if (!g_bActive)
                                            {
                                                PrintToChat(nPlr, "Type SPAWNS Before");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            PrintToChat(nPlr, "%02d Team A & %02d Team B", g_nTotalA, g_nTotalB);
                                            {
                                                return Plugin_Handled;
                                            }
                                        }

                                        else if (strcmp(szArg, "ss", false) == 0)
                                        {
                                            if (!g_bActive)
                                            {
                                                PrintToChat(nPlr, "Type SPAWNS Before");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            if (!g_nTotalA && !g_nTotalB)
                                            {
                                                PrintToChat(nPlr, "Nothing To Save");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            hFile = OpenFile(g_szPath, "w");
                                            {
                                                if (hFile != null)
                                                {
                                                    if (Engine_DODS == g_nEngVs)
                                                    {
                                                        if (g_nTotalA > 0 && g_nTotalB > 0)
                                                        {
                                                            WriteFileLine(hFile, "\nremove:\n{\n    \"classname\" \"info_player_allies\"\n}\n\nremove:\n{\n    \"classname\" \"info_player_axis\"\n}\n\n");
                                                        }

                                                        else if (g_nTotalA > 0)
                                                        {
                                                            WriteFileLine(hFile, "\nremove:\n{\n    \"classname\" \"info_player_allies\"\n}\n\n");
                                                        }

                                                        else
                                                        {
                                                            WriteFileLine(hFile, "\nremove:\n{\n    \"classname\" \"info_player_axis\"\n}\n\n");
                                                        }

                                                        for (nItr = 0; nItr < g_nTotalA; nItr++)
                                                        {
                                                            WriteFileLine(hFile, "add:\n{\n    \"origin\" \"%.1f %.1f %.1f\"\n    \"angles\" \"0 %d 0\"\n    \"classname\" \"info_player_allies\"\n}\n",
                                                                g_fPosA[nItr][0], g_fPosA[nItr][1], g_fPosA[nItr][2], (((nApprox = RoundToNearest(g_fAngA[nItr][1])) == 180) ? (-180) : (nApprox)));
                                                        }

                                                        for (nItr = 0; nItr < g_nTotalB; nItr++)
                                                        {
                                                            WriteFileLine(hFile, "add:\n{\n    \"origin\" \"%.1f %.1f %.1f\"\n    \"angles\" \"0 %d 0\"\n    \"classname\" \"info_player_axis\"\n}\n",
                                                                g_fPosB[nItr][0], g_fPosB[nItr][1], g_fPosB[nItr][2], (((nApprox = RoundToNearest(g_fAngB[nItr][1])) == 180) ? (-180) : (nApprox)));
                                                        }
                                                    }

                                                    else
                                                    {
                                                        if (g_nTotalA > 0 && g_nTotalB > 0)
                                                        {
                                                            WriteFileLine(hFile, "\nremove:\n{\n    \"classname\" \"info_player_terrorist\"\n}\n\nremove:\n{\n    \"classname\" \"info_player_counterterrorist\"\n}\n\n");
                                                        }

                                                        else if (g_nTotalA > 0)
                                                        {
                                                            WriteFileLine(hFile, "\nremove:\n{\n    \"classname\" \"info_player_terrorist\"\n}\n\n");
                                                        }

                                                        else
                                                        {
                                                            WriteFileLine(hFile, "\nremove:\n{\n    \"classname\" \"info_player_counterterrorist\"\n}\n\n");
                                                        }

                                                        for (nItr = 0; nItr < g_nTotalA; nItr++)
                                                        {
                                                            WriteFileLine(hFile, "add:\n{\n    \"origin\" \"%.1f %.1f %.1f\"\n    \"angles\" \"0 %d 0\"\n    \"classname\" \"info_player_terrorist\"\n}\n",
                                                                g_fPosA[nItr][0], g_fPosA[nItr][1], g_fPosA[nItr][2], (((nApprox = RoundToNearest(g_fAngA[nItr][1])) == 180) ? (-180) : (nApprox)));
                                                        }

                                                        for (nItr = 0; nItr < g_nTotalB; nItr++)
                                                        {
                                                            WriteFileLine(hFile, "add:\n{\n    \"origin\" \"%.1f %.1f %.1f\"\n    \"angles\" \"0 %d 0\"\n    \"classname\" \"info_player_counterterrorist\"\n}\n",
                                                                g_fPosB[nItr][0], g_fPosB[nItr][1], g_fPosB[nItr][2], (((nApprox = RoundToNearest(g_fAngB[nItr][1])) == 180) ? (-180) : (nApprox)));
                                                        }
                                                    }

                                                    if (g_nTotalA > 0 && g_nTotalB > 0)
                                                    {
                                                        PrintToChat(nPlr, "Saved %02d A & %02d B To %s", g_nTotalA, g_nTotalB, g_szPath);
                                                    }

                                                    else if (g_nTotalA > 0)
                                                    {
                                                        PrintToChat(nPlr, "Saved %02d A To %s", g_nTotalA, g_szPath);
                                                    }

                                                    else
                                                    {
                                                        PrintToChat(nPlr, "Saved %02d B To %s", g_nTotalB, g_szPath);
                                                    }

                                                    CloseHandle(hFile);
                                                    {
                                                        strcopy(szTmp, sizeof szTmp, g_szPath);
                                                        {
                                                            ReplaceStringEx(szTmp, sizeof szTmp, ".se.cfg", ".cfg", 7, 4, false);
                                                            {
                                                                if (!FileExists(szTmp))
                                                                {
                                                                    hFile = OpenFile(szTmp, "w");
                                                                    {
                                                                        if (hFile != null)
                                                                        {
                                                                            CloseHandle(hFile);
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }

                                                    PrintToChat(nPlr, "Copy Contents From It To %s", szTmp);
                                                }

                                                else
                                                {
                                                    PrintToChat(nPlr, "Internal Error");
                                                }
                                            }

                                            return Plugin_Handled;
                                        }

                                        else if (strcmp(szArg, "sb", false) == 0)
                                        {
                                            if (!g_bActive)
                                            {
                                                PrintToChat(nPlr, "Type SPAWNS Before");
                                                {
                                                    return Plugin_Handled;
                                                }
                                            }

                                            if (Engine_DODS != g_nEngVs)
                                            {
                                                g_bOnlyInBZ = !g_bOnlyInBZ;
                                                {
                                                    PrintToChat(nPlr, g_bOnlyInBZ ? "Only In Buy Zone Allowed" : "Everywhere Allowed");
                                                }
                                            }

                                            else
                                            {
                                                PrintToChat(nPlr, "This Is A CS Only Feature");
                                            }

                                            return Plugin_Handled;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action TmrAng(Handle hTmr, any nUsrId)
{
    static float fAng[3] = { 0.000000, ... }, fOrgYaw = 0.000000, fAbsOrgYaw = 0.000000, fAbsYaw = 0.000000;
    {
        static int nPlr = 0, nYaw = 0, nEnd = 0;
        {
            if (g_bActive)
            {
                nPlr = GetClientOfUserId(nUsrId);
                {
                    if (nPlr > 0)
                    {
                        if (nPlr < 66)
                        {
                            if (MaxClients < 1 || nPlr <= MaxClients)
                            {
                                if (IsClientConnected(nPlr))
                                {
                                    if (IsClientInGame(nPlr))
                                    {
                                        if (IsClientAuthorized(nPlr))
                                        {
                                            if (IsPlayerAlive(nPlr))
                                            {
                                                GetClientEyeAngles(nPlr, fAng);
                                                {
                                                    fOrgYaw = fAng[1];
                                                    {
                                                        nYaw = RoundToNearest(fAng[1]);
                                                        {
                                                            nEnd = nYaw % 5;
                                                            {
                                                                if (nEnd != 0)
                                                                {
                                                                    switch (nEnd)
                                                                    {
                                                                        case 1, -4:
                                                                        {
                                                                            nYaw -= 1;
                                                                        }

                                                                        case 2, -3:
                                                                        {
                                                                            nYaw -= 2;
                                                                        }

                                                                        case 3, -2:
                                                                        {
                                                                            nYaw += 2;
                                                                        }

                                                                        default:
                                                                        {
                                                                            nYaw += 1;
                                                                        }
                                                                    }

                                                                    fAng[1] = ((nYaw == 180) ? (-180.000000) : (float(nYaw)));
                                                                    {
                                                                        if (g_nEngVs != Engine_CSGO)
                                                                        {
                                                                            fAbsOrgYaw = FloatAbs(fOrgYaw);
                                                                            {
                                                                                fAbsYaw = FloatAbs(fAng[1]);
                                                                                {
                                                                                    if (fAbsOrgYaw >= fAbsYaw)
                                                                                    {
                                                                                        if (fAbsOrgYaw - fAbsYaw > 0.009)
                                                                                        {
                                                                                            TeleportEntity(nPlr, NULL_VECTOR, fAng, NULL_VECTOR);
                                                                                            {
                                                                                                PrintHintText(nPlr, "Yaw %.0f", fAng[1]);
                                                                                            }
                                                                                        }
                                                                                    }

                                                                                    else
                                                                                    {
                                                                                        if (fAbsYaw - fAbsOrgYaw > 0.009)
                                                                                        {
                                                                                            TeleportEntity(nPlr, NULL_VECTOR, fAng, NULL_VECTOR);
                                                                                            {
                                                                                                PrintHintText(nPlr, "Yaw %.0f", fAng[1]);
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }

                                                                        else
                                                                        {
                                                                            if (fOrgYaw != fAng[1])
                                                                            {
                                                                                TeleportEntity(nPlr, NULL_VECTOR, fAng, NULL_VECTOR);
                                                                                {
                                                                                    PrintHintText(nPlr, "Yaw %.0f", fAng[1]);
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }

                                                                else
                                                                {
                                                                    fAng[1] = ((nYaw == 180) ? (-180.000000) : (float(nYaw)));
                                                                    {
                                                                        if (g_nEngVs != Engine_CSGO)
                                                                        {
                                                                            fAbsOrgYaw = FloatAbs(fOrgYaw);
                                                                            {
                                                                                fAbsYaw = FloatAbs(fAng[1]);
                                                                                {
                                                                                    if (fAbsOrgYaw >= fAbsYaw)
                                                                                    {
                                                                                        if (fAbsOrgYaw - fAbsYaw > 0.009)
                                                                                        {
                                                                                            TeleportEntity(nPlr, NULL_VECTOR, fAng, NULL_VECTOR);
                                                                                            {
                                                                                                PrintHintText(nPlr, "Yaw %.0f", fAng[1]);
                                                                                            }
                                                                                        }
                                                                                    }

                                                                                    else
                                                                                    {
                                                                                        if (fAbsYaw - fAbsOrgYaw > 0.009)
                                                                                        {
                                                                                            TeleportEntity(nPlr, NULL_VECTOR, fAng, NULL_VECTOR);
                                                                                            {
                                                                                                PrintHintText(nPlr, "Yaw %.0f", fAng[1]);
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }

                                                                        else
                                                                        {
                                                                            if (fOrgYaw != fAng[1])
                                                                            {
                                                                                TeleportEntity(nPlr, NULL_VECTOR, fAng, NULL_VECTOR);
                                                                                {
                                                                                    PrintHintText(nPlr, "Yaw %.0f", fAng[1]);
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            return Plugin_Continue;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return Plugin_Stop;
}

public void OnEntityCreated(int nEntity, const char[] szClass)
{
    if (g_bActive)
    {
        if (nEntity != -1)
        {
            if (StrContains(szClass, "weapon", false) != -1 || StrContains(szClass, "item", false) != -1 || StrContains(szClass, "doll", false) != -1)
            {
                CreateTimer(GetRandomFloat(0.750000, 1.000000), TmrEntity, nEntity, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

public Action TmrEntity(Handle hTmr, any nEntity)
{
    if (g_bActive)
    {
        if (nEntity != -1)
        {
            if (IsValidEntity(nEntity))
            {
                TryOnceReadOffs(nEntity, "m_hOwner", m_hOwner);
                {
                    TryOnceReadOffs(nEntity, "m_hOwnerEntity", m_hOwnerEntity);
                    {
                        if (m_hOwner > 0 && m_hOwnerEntity > 0)
                        {
                            if (-1 == GetEntDataEnt2(nEntity, m_hOwner))
                            {
                                if (-1 == GetEntDataEnt2(nEntity, m_hOwnerEntity))
                                {
                                    AcceptEntityInput(nEntity, "KillHierarchy");
                                }
                            }
                        }

                        else if (m_hOwner > 0)
                        {
                            if (-1 == GetEntDataEnt2(nEntity, m_hOwner))
                            {
                                AcceptEntityInput(nEntity, "KillHierarchy");
                            }
                        }

                        else if (m_hOwnerEntity > 0)
                        {
                            if (-1 == GetEntDataEnt2(nEntity, m_hOwnerEntity))
                            {
                                AcceptEntityInput(nEntity, "KillHierarchy");
                            }
                        }
                    }
                }
            }
        }
    }

    return Plugin_Continue;
}
