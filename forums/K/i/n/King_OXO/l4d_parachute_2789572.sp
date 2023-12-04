
//////////////////////////
//  thanks for code     //
//      shanapu         //
//////////////////////////

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define SOUND_HELICOPTER    "vehicles/airboat/fan_blade_fullthrottle_loop1.wav"
#define SOUND_F18           "ambient/gas/steam2.wav"
    

bool g_bParachute[MAXPLAYERS+1];
int g_iVelocity = -1, g_ent[MAXPLAYERS+1], ModelType[MAXPLAYERS+1];
Handle iCook;

char g_sModels[][] =
{
    "models/props_swamp/parachute01.mdl", //repeated so as not to give the system error
    "models/props_swamp/parachute01.mdl",
    "models/props/de_inferno/ceiling_fan_blade.mdl",
    "models/props_vehicles/helicopter_rescue.mdl",
    "models/f18/f18.mdl"
};

char sName[][] = 
{
    "Remove",
    "Parachute Swamp",
    "Ceiling Fan Blade",
    "Helicopter Rescue",
    "F-18"
};

public Plugin myinfo = {
    name = "[L4D & L4D2] Left 4 Parachute",
    author = "Joshe Gatito",
    description = "Adds support for parachutes",
    version = "1.2",
    url = "https://steamcommunity.com/id/joshegatito/"
};

public void OnPluginStart()
{
    iCook = RegClientCookie("parachuteid", "cookie for parachute id", CookieAccess_Private);
    
    g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
    
    RegConsoleCmd("sm_parachutes", CmdOpenMenu);
    
    HookEvent("player_spawn", Event_Player_Spawn);
}

public void Event_Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!client || IsFakeClient(client))
        return;

    ReadCookies(client);
}

public Action CmdOpenMenu(int client, int args)
{
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;

    if(!IsPlayerAlive(client))
    {
        PrintToChat(client, "\x05[PARACHUTE] \x03You must be \x04alive \x03to use this \x05command \x03!");
        return Plugin_Handled;
    }
    
    Menu menu = new Menu(PrMenu);
    menu.SetTitle("• PARACHUTE MENU •\n ");
    for(int i; i < sizeof(sName); i++)
        menu.AddItem("", sName[i], ModelType[client] == i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Handled;
}

public int PrMenu(Menu menu, MenuAction action, int client, int param)
{
    switch(action)
    {
        case MenuAction_End:
            delete menu;
        case MenuAction_Select:
        {
            GetModel(client, param);
            SetCookie(client, iCook, param);
        }
    }

    return 0;
}

public void SetCookie(int client, Handle hCookie, int n)
{
    char strCookie[4];
    IntToString(n, strCookie, 4);
    SetClientCookie(client, hCookie, strCookie);
}

public void ReadCookies(int client)
{
    if(client < 1 || MaxClients < client || !IsClientInGame(client) || IsFakeClient(client)
    || !AreClientCookiesCached(client))
        return;

    char str[4];
    GetClientCookie(client, iCook, str, sizeof(str));
    if(str[0]) GetModel(client, StringToInt(str));
}

stock void GetModel(int client, int id)
{
    if(!id)
    {
        ModelType[client] = 0;
        PrintToChat(client, "\x05[PARACHUTE] \x03Removed Parachute!");
    }
    else
    {
        ModelType[client] = id;
        PrintToChat(client, "\x05[PARACHUTE] \x03Parachute is:\x04%s\x03!", sName[id]);
    }
}

public void OnMapStart()
{
    for (int i ; i < sizeof g_sModels; i++)
        PrecacheModel(g_sModels[i], true);
    
    PrecacheSound(SOUND_F18, true);
    PrecacheSound(SOUND_HELICOPTER, true);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if(ModelType[client] == 0)
        return Plugin_Continue;
    
    if(g_bParachute[client])
    {
        if(!(buttons & IN_USE) || !IsPlayerAlive(client))
        {
            DisableParachute(client);
            return Plugin_Continue;
        }
        
        if(ModelType[client] == 2)
        {
            float s_rotation[3];
            GetEntPropVector( g_ent[client], Prop_Data, "m_angRotation", s_rotation );
            s_rotation[1] += 90.0;
            TeleportEntity( g_ent[client], NULL_VECTOR, s_rotation, NULL_VECTOR);
        }
        
        float fVel[3];
        GetEntDataVector(client, g_iVelocity, fVel);

        if(fVel[2] >= 0.0)
        {
            DisableParachute(client);
            return Plugin_Continue;
        }

        if(GetEntityFlags(client) & FL_ONGROUND)
        {
            DisableParachute(client);
            return Plugin_Continue;
        }
        
        float fOldSpeed = fVel[2];
    
        if(fVel[2] < 100.0 * -1.0) fVel[2] = 50.0 * -1.0;
        if(fOldSpeed != fVel[2])
            TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVel);
        
        if(GetClientTeam(client) == 2)
        {
            switch(ModelType[client])
            {
                case 1: SpeedPlayer(client, fVel, 250.0);
                case 2: SpeedPlayer(client, fVel, 500.0);
                case 3: SpeedPlayer(client, fVel, 500.0);
                case 4: SpeedPlayer(client, fVel, 500.0);
            }
        }
    }
    else
    {
        if(!(buttons & IN_USE) || !IsPlayerAlive(client))
            return Plugin_Continue;
    
        if(GetEntityFlags(client) & FL_ONGROUND)
            return Plugin_Continue;

        float fVel[3];
        GetEntDataVector(client, g_iVelocity, fVel);

        if(fVel[2] >= 0.0)
            return Plugin_Continue;
    
        CreateParachute(client, ModelType[client]);
    }

    return Plugin_Continue;
}

//         Discord's script          //
void SpeedPlayer(int client, float vVel[3], float speed)
{
    float v = GetVectorLength(vVel);
    if(v > speed)
    {
        NormalizeVector(vVel, vVel);
        ScaleVector(vVel, speed);
    }
    NormalizeVector(vVel, vVel);
    ScaleVector(vVel, speed);
    SetEntityGravity(client, 0.01);
        
    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
}
//==================================//

void CreateParachute(int client, int value)
{
    g_ent[client] = CreateEntityByName("prop_dynamic_override");             
    DispatchKeyValue(g_ent[client], "model", g_sModels[value]);
    DispatchSpawn(g_ent[client]);        
    SetEntityMoveType(g_ent[client], MOVETYPE_NOCLIP);
        
    float ParachutePos[3], ParachuteAng[3];
    GetClientAbsOrigin(client, ParachutePos);
    GetClientAbsAngles(client, ParachuteAng);
    ParachutePos[2] += 80.0;
        
    TeleportEntity(g_ent[client], ParachutePos, ParachuteAng, NULL_VECTOR);
    
    if(value == 1)
    {    
        int R = GetRandomInt(0, 255), G = GetRandomInt(0, 255), B = GetRandomInt(0, 255); 
        SetEntProp(g_ent[client], Prop_Send, "m_nGlowRange", 2000);
        SetEntProp(g_ent[client], Prop_Send, "m_iGlowType", 2);
        SetEntProp(g_ent[client], Prop_Send, "m_glowColorOverride", R + (G * 256) + (B * 65536));
        
        SetEntityRenderMode(g_ent[client], RENDER_TRANSCOLOR);
        SetEntityRenderColor(g_ent[client], 255, 255, 255, 2);
        
        SetEntPropFloat(g_ent[client], Prop_Data, "m_flModelScale", 0.4);
    }
    
    if(value == 2)
    {
        EmitSoundToAll(SOUND_HELICOPTER, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
        SetEntPropFloat(g_ent[client], Prop_Data, "m_flModelScale", 1.0);
    }
    
    if(value == 3)
    {
        EmitSoundToAll(SOUND_HELICOPTER, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
        SetVariantString("3ready");//3ready
        AcceptEntityInput(g_ent[client], "SetAnimation");
        SetEntPropFloat(g_ent[client], Prop_Data, "m_flModelScale", 0.1);
    }
    if(value == 4)
    {
        SetEntPropFloat(g_ent[client], Prop_Data, "m_flModelScale", 0.2);
        EmitSoundToAll(SOUND_F18, client,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
    }
    SetVariantString("!activator");
    AcceptEntityInput(g_ent[client], "SetParent", client);

    g_bParachute[client] = true;
}

void DisableParachute(int client)
{
    AcceptEntityInput(g_ent[client], "ClearParent");
    AcceptEntityInput(g_ent[client], "kill");

    ParachuteDrop(client);
    g_bParachute[client] = false;
    
    SetEntityGravity(client, 1.0);
}

void ParachuteDrop(int client)
{
    if (!IsClientInGame(client))
        return;
    
    StopSound(client, SNDCHAN_AUTO, SOUND_HELICOPTER);
    StopSound(client, SNDCHAN_AUTO, SOUND_F18);
}