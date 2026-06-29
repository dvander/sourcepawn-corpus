#include <sourcemod>
#include <dbi>
#include <timers>
#include <events>
#include <clients>
#include <sdktools>

new Float:ori[3];

public Plugin:myinfo = {
    name = "Build a sentry here!RED Version",
    author = "Myrrib",
    description = "Build a sentry here!RED Version",
    version = "0.1",
    url = ""
};

public OnPluginStart() {
    RegAdminCmd("sm_build_sentry_here_red", Command_Sentry, ADMFLAG_GENERIC, "");
	RegAdminCmd("sm_behr", Command_Sentry, ADMFLAG_GENERIC, "");
}

public Action:Command_Sentry(client, args) {
    GetClientAbsOrigin(client,ori); 
    CreateTimer(1.0,CreateSentry,client);
    return Plugin_Handled;
}

public Action:CreateSentry(Handle:timer,any:client) {
    new Float:vbm[3];
    vbm[0] = 24.0;
    vbm[1] = 24.0;
    vbm[2] = 66.0;
    
    new Float:mwc[3];
    mwc[0] = 1.0;
    mwc[1] = 0.5;
    mwc[2] = 0.0;
    
    new Float:angle[3];
    GetClientAbsAngles(client,angle);
    angle[0] = 0.0;
    angle[2] = 0.0;
    
    new team = GetClientTeam(client);
    
    new ent = CreateEntityByName("obj_sentrygun");
    DispatchSpawn(ent);
    TeleportEntity(ent, ori , angle , NULL_VECTOR );
    
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_flAnimTime") , 51 , 4 , true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_nNewSequenceParity") , 4 , 4 , true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_nResetEventsParity") , 4 , 4 , true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_iAmmoShells") , 150 , 4, true );
    //SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_nModelIndex") , 353 , 4 , true );
    SetEntityModel(ent,"models/buildables/sentry1.mdl");
    SetEntDataEnt( ent , FindSendPropOffs("CObjectSentrygun","m_nSequence") , 0 , true );
    SetEntDataFloat( ent , FindSendPropOffs("CObjectSentrygun","m_flPlaybackRate") , 1.0 , true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_iMaxHealth") , 200 , 4, true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_iHealth") , 200 , 4, true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_bBuilding") , 0 , 2, true );
    SetEntDataFloat( ent , FindSendPropOffs("CObjectSentrygun","m_flPercentageConstructed") , 1.0 , true );  
    SetEntDataVector( ent , FindSendPropOffs("CObjectSentrygun","m_vecOrigin") , ori , true );
    SetEntDataVector( ent , FindSendPropOffs("CObjectSentrygun","m_angRotation") , angle , true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_bPlacing") , 0 , 2, true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_bDisabled") , 0 , 2 , true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_iObjectType") , 3, true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_iState") , 1, true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_iUpgradeMetal") , 199 , true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_bHasSapper") , 0 , 2 , true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_nSkin") , team==2?1:0 , 1 , true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_bServerOverridePlacement") , 1 , 1 , true);
    SetEntDataVector( ent , FindSendPropOffs("CObjectSentrygun","m_vecBuildMaxs") , vbm , true );
    SetEntDataVector( ent , FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale") , mwc , true );
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_iUpgradeLevel") , 2 , 4, true );  
    SetEntData( ent , FindSendPropOffs("CObjectSentrygun","m_iAmmoRockets") , 0 , 4, true );
    SetEntDataEnt(ent, FindSendPropOffs("CObjectSentrygun","m_hBuilder"), client , true);
    SetEntDataFloat( ent , FindSendPropOffs("CObjectSentrygun","m_flCycle") , 0.0 , true );
    
    SetVariantInt(team)
    AcceptEntityInput(ent, "2", -1, -1, 0);
    
    SetVariantInt(team)
    AcceptEntityInput(ent, "2", -1, -1, 0);  
    
}