/*
 * Gun Golf, requires SM_Hosties 2.1.0+.
 */
 
#include <sourcemod>
#include <sdktools>
#include <menus>
// Make certain the lastrequest.inc is last on the list
#include <hosties>
#include <lastrequest>
 
#pragma semicolon 1
 
#define PLUGIN_VERSION "1.0.0"
#define Game_CSS 0
#define Game_CSGO 1
 
// This global will store the index number for the new Last Request
new g_LREntryNum;
 
// Global LR type
new g_This_LR_Type;
 
// Global Prisoner & Guard
new g_LR_Player_Prisoner;
new g_LR_Player_Guard;
 
// Global Weapons for Prisoner & Guard
new g_Pistol_Prisoner;
new g_Pistol_Guard;
 
// Global origins
new Float:g_Pistol_Prisoner_Origin[3];
new Float:g_Pistol_Guard_Origin[3];
new Float:g_Point_Origin[3];
 
// LR name
new String:g_sLR_Name[64];
 
// Menus handlers
new Handle:g_WepSelect = INVALID_HANDLE;
new Handle:g_PointSelect = INVALID_HANDLE;
 
// Game detection
new g_Game = -1;
 
// GunGolf states
new GunGolfRunning = 0;
new bool:g_bPistol_Prisoner_Dropped = false;
new bool:g_bPistol_Guard_Dropped = false;
 
// Effects
new BeamSprite = -1;
new HaloSprite = -1;
new LaserSprite = -1;
new LaserHalo = -1;
new greenColor[] = {0, 255, 0, 255};
new redColor[] = {255, 0, 0, 255};
new blueColor[] = {0, 0, 255, 255};
new greyColor[] = {128, 128, 128, 255};
 
public Plugin:myinfo =
{
        name = "Last Request: Gun Golf",
        author = "CoMaNdO",
        description = "Gun Golf last request for SM_Hosties 2.1.0+",
        version = PLUGIN_VERSION,
        url = "http:\\alliedmods.com"
};
 
enum Weapons
{
        Pistol_Deagle = 0,
        Pistol_P228,
        Pistol_Glock,
        Pistol_FiveSeven,
        Pistol_Dualies,
        Pistol_USP,
        Pistol_Tec9
};
 
public OnPluginStart()
{
        // Load translations
        LoadTranslations("LR.GunGolf.phrases");
       
        // LR's name
        Format(g_sLR_Name, sizeof(g_sLR_Name), "%T", "GunGolf", LANG_SERVER);
       
        // Detect game
        decl String:gdir[PLATFORM_MAX_PATH];
        GetGameFolderName(gdir,sizeof(gdir));
        if (StrEqual(gdir,"cstrike",false) || StrEqual(gdir,"cstrike_beta",false))              g_Game = Game_CSS;      else
        if (StrEqual(gdir,"csgo",false))                        g_Game = Game_CSGO;
       
        // Menus
        decl String:sSubTypeName[64];
        decl String:sDataField[16];
       
        // Weapon Select
        g_WepSelect = CreateMenu(WeaponMenuHandler);
        SetMenuTitle(g_WepSelect, "%T", "Weapon Selection Menu"); // Title
       
        Format(sDataField, sizeof(sDataField), "%d", Pistol_Deagle);
        Format(sSubTypeName, sizeof(sSubTypeName), "%T", "Pistol_Deagle");
        AddMenuItem(g_WepSelect, sDataField, sSubTypeName); // Deagle
       
        Format(sDataField, sizeof(sDataField), "%d", Pistol_P228);
        if(g_Game == Game_CSS)
                Format(sSubTypeName, sizeof(sSubTypeName), "%T", "Pistol_P228");
        else if(g_Game == Game_CSGO)
                Format(sSubTypeName, sizeof(sSubTypeName), "%T", "Pistol_P250");
        AddMenuItem(g_WepSelect, sDataField, sSubTypeName); // P228 / P250
       
        Format(sDataField, sizeof(sDataField), "%d", Pistol_Glock);
        Format(sSubTypeName, sizeof(sSubTypeName), "%T", "Pistol_Glock");
        AddMenuItem(g_WepSelect, sDataField, sSubTypeName); // Glock
       
        Format(sDataField, sizeof(sDataField), "%d", Pistol_FiveSeven);
        Format(sSubTypeName, sizeof(sSubTypeName), "%T", "Pistol_FiveSeven");
        AddMenuItem(g_WepSelect, sDataField, sSubTypeName); // FiveSeven
       
        Format(sDataField, sizeof(sDataField), "%d", Pistol_Dualies);
        Format(sSubTypeName, sizeof(sSubTypeName), "%T", "Pistol_Dualies");
        AddMenuItem(g_WepSelect, sDataField, sSubTypeName); // Dualies
       
        Format(sDataField, sizeof(sDataField), "%d", Pistol_USP);
        if(g_Game == Game_CSS)
                Format(sSubTypeName, sizeof(sSubTypeName), "%T", "Pistol_USP");
        else if(g_Game == Game_CSGO)
                Format(sSubTypeName, sizeof(sSubTypeName), "%T", "Pistol_P2000");
        AddMenuItem(g_WepSelect, sDataField, sSubTypeName); // USP / P2000
       
        if(g_Game == Game_CSGO)
        {
                Format(sDataField, sizeof(sDataField), "%d", Pistol_Tec9);
                Format(sSubTypeName, sizeof(sSubTypeName), "%T", "Pistol_Tec9");
                AddMenuItem(g_WepSelect, sDataField, sSubTypeName); // Tec 9
        }
        SetMenuExitButton(g_WepSelect, true);
       
        // Point Select
        g_PointSelect = CreateMenu(PointMenuHandler);
        SetMenuTitle(g_PointSelect, "%T", "Point Selection Menu"); // Title
        Format(sSubTypeName, sizeof(sSubTypeName), "%T", "Point_Selection");
        AddMenuItem(g_PointSelect, "0", sSubTypeName); // Deagle
        SetMenuExitButton(g_PointSelect, true);
}
 
public OnMapStart()
{
        // Precache any materials needed
        if(g_Game == Game_CSGO)
        {
                BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
                HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
                LaserSprite = PrecacheModel("materials/sprites/lgtning.vmt");
                LaserHalo = PrecacheModel("materials/sprites/plasmahalo.vmt");
        }
        else
        {
                BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
                HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
                LaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
                LaserHalo = PrecacheModel("materials/sprites/light_glow02.vmt");
        }
}
 
public OnConfigsExecuted()
{
        static bool:bAddedGunGolf = false;
        if (!bAddedGunGolf)
        {
                g_LREntryNum = AddLastRequestToList(GunGolf_Start, GunGolf_Stop, g_sLR_Name, false);
                bAddedGunGolf = true;
        }      
}
 
public PointMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
        if (action == MenuAction_Select)
        {
                if(param2 == 0)
                {
                        GetClientAbsOrigin(param1, g_Point_Origin);
                       
                }
        }
}
 
public Action:Timer_Pistol_Prisoner_Beam(Handle:timer)
{
        if(!GunGolfRunning)
        {
                gH_Timer_Pistol_Prisoner_Beam = INVALID_HANDLE;
                return Plugin_Stop;
        }
        if(IsClientInGame(g_LR_Player_Prisoner) && IsClientInGame(g_LR_Player_Guard))
        {
                TE_SetupBeamPoints(g_Pistol_Prisoner_Origin, g_Point_Origin, LaserSprite, LaserHalo, 1, 1, 0.2, 2.0, 2.0, 0, 10.0, redColor, 255);                     
                TE_SendToAll();
                TE_SetupBeamPoints(g_Point_Origin, g_Pistol_Prisoner_Origin, LaserSprite, LaserHalo, 1, 1, 0.2, 2.0, 2.0, 0, 10.0, redColor, 255);                     
                TE_SendToAll();
        }
        return Plugin_Continue;
}
 
public Action:Timer_Pistol_Guard_Beam(Handle:timer)
{
        if(!GunGolfRunning)
        {
                gH_Timer_Pistol_Guard_Beam = INVALID_HANDLE;
                return Plugin_Stop;
        }
        if(IsClientInGame(g_LR_Player_Prisoner) && IsClientInGame(g_LR_Player_Guard))
        {
                TE_SetupBeamPoints(g_Pistol_Guard_Origin, g_Point_Origin, LaserSprite, LaserHalo, 1, 1, 0.2, 2.0, 2.0, 0, 10.0, blueColor, 255);                       
                TE_SendToAll();
                TE_SetupBeamPoints(g_Point_Origin, g_Pistol_Guard_Origin, LaserSprite, LaserHalo, 1, 1, 0.2, 2.0, 2.0, 0, 10.0, blueColor, 255);                       
                TE_SendToAll();
        }
        return Plugin_Continue;
}
 
public Action:Timer_Point_Beam(Handle:timer)
{
        if(!GunGolfRunning)
        {
                gH_Timer_Point_Beam = INVALID_HANDLE;
                return Plugin_Stop;
        }
        decl Float:f_Origin[3];
        f_Origin[0] = g_Point_Origin[0];
        f_Origin[1] = g_Point_Origin[1];
        f_Origin[2] = g_Point_Origin[2] + 10;
        TE_SetupBeamRingPoint(f_Origin, 125.0, 350.0, BeamSprite, HaloSprite, 0, 15, 0.6, 5.0, 0.0, greyColor, 10, 0);
        TE_SendToAll();
        TE_SetupBeamRingPoint(f_Origin, 349.9, 350.0, BeamSprite, HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 10, 0);
        TE_SendToAll();
        return Plugin_Continue;
}
 
public WeaponMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
        if (action == MenuAction_Select)
        {
                switch(param2)
                {
                        case Pistol_Deagle:
                        {
                                g_Pistol_Prisoner = GivePlayerItem(g_LR_Player_Prisoner, "weapon_deagle");
                                g_Pistol_Guard = GivePlayerItem(g_LR_Player_Guard, "weapon_deagle");
                        }
                        case Pistol_P228:
                        {
                                if (g_Game == Game_CSS)
                                {
                                        g_Pistol_Prisoner = GivePlayerItem(g_LR_Player_Prisoner, "weapon_p228");
                                        g_Pistol_Guard = GivePlayerItem(g_LR_Player_Guard, "weapon_p228");
                                }
                                else if (g_Game == Game_CSGO)
                                {
                                        g_Pistol_Prisoner = GivePlayerItem(g_LR_Player_Prisoner, "weapon_p250");
                                        g_Pistol_Guard = GivePlayerItem(g_LR_Player_Guard, "weapon_p250");
                                }
                        }
                        case Pistol_Glock:
                        {
                                g_Pistol_Prisoner = GivePlayerItem(g_LR_Player_Prisoner, "weapon_glock");
                                g_Pistol_Guard = GivePlayerItem(g_LR_Player_Guard, "weapon_glock");
                        }
                        case Pistol_FiveSeven:
                        {
                                g_Pistol_Prisoner = GivePlayerItem(g_LR_Player_Prisoner, "weapon_fiveseven");
                                g_Pistol_Guard = GivePlayerItem(g_LR_Player_Guard, "weapon_fiveseven");
                        }
                        case Pistol_Dualies:
                        {
                                g_Pistol_Prisoner = GivePlayerItem(g_LR_Player_Prisoner, "weapon_elite");
                                g_Pistol_Guard = GivePlayerItem(g_LR_Player_Guard, "weapon_elite");
                        }
                        case Pistol_USP:
                        {
                                if(g_Game == Game_CSS)
                                {
                                        g_Pistol_Prisoner = GivePlayerItem(g_LR_Player_Prisoner, "weapon_usp");
                                        g_Pistol_Guard = GivePlayerItem(g_LR_Player_Guard, "weapon_usp");
                                }
                                else if(g_Game == Game_CSGO)
                                {
                                        g_Pistol_Prisoner = GivePlayerItem(g_LR_Player_Prisoner, "weapon_hkp2000");
                                        g_Pistol_Guard = GivePlayerItem(g_LR_Player_Guard, "weapon_hkp2000");
                                }
                        }
                        case Pistol_Tec9:
                        {
                                g_Pistol_Prisoner = GivePlayerItem(g_LR_Player_Prisoner, "weapon_tec9");
                                g_Pistol_Guard = GivePlayerItem(g_LR_Player_Guard, "weapon_tec9");
                        }
                        default:
                        {
                                LogError("hit default S4S");
                                g_Pistol_Prisoner = GivePlayerItem(g_LR_Player_Prisoner, "weapon_deagle");
                                g_Pistol_Guard = GivePlayerItem(g_LR_Player_Guard, "weapon_deagle");
                        }
                }
                DisplayMenu(g_PointSelect, param1, 0);
        }
}
 
public Action:GunGolf(Handle:timer)
{
        GetEntPropVector(g_Pistol_Prisoner, Prop_Data, "m_vecOrigin", GTdeagle2pos);
        if(g_bPistol_Prisoner_Dropped)
        if(g_bPistol_Guard_Dropped)
}
 
// The plugin should remove any LRs it loads when it's unloaded
public OnPluginEnd()
{
        RemoveLastRequestFromList(GunGolf_Start, GunGolf_Stop, g_sLR_Name);
}
 
public GunGolf_Start(Handle:LR_Array, iIndexInArray)
{
        g_This_LR_Type = GetArrayCell(LR_Array, iIndexInArray, _:Block_LRType); // get this lr from selection
        if (g_This_LR_Type == g_LREntryNum)
        {
                g_LR_Player_Prisoner = GetArrayCell(LR_Array, iIndexInArray, _:Block_Prisoner); // get prisoner's id
                g_LR_Player_Guard = GetArrayCell(LR_Array, iIndexInArray, _:Block_Guard); // get guard's id
               
                // check datapack value
                new LR_Pack_Value = GetArrayCell(LR_Array, iIndexInArray, _:Block_Global1);    
                switch (LR_Pack_Value)
                {
                        case -1:
                        {
                                PrintToServer("no info included");
                        }
                }
                DisplayMenu(g_WepSelect, g_LR_Player_Prisoner, 0);
        }
}