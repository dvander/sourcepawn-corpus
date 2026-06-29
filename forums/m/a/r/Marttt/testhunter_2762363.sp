/*
*    Rochelle Tank
*    Copyright (C) 2020 Silvers
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION         "0.2"

/*======================================================================================
    Plugin Info:

*    Name      :    [L4D2] Rochelle Tank
*    Author    :    SilverShot
*    Descrp    :    ...
*    Link      :    https://forums.alliedmods.net/showthread.php?t=325668
*    Plugins   :    https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers 

========================================================================================
    Change Log:

0.2 (11-Jul-2020)
    - Fixed clone not disappearing when the tank dies.

0.1 (01-Jul-2020)
    - Initial release.

======================================================================================*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define EF_BONEMERGE             (1 << 0)
#define EF_NOSHADOW              (1 << 4)
#define EF_BONEMERGE_FASTCULL    (1 << 7)
#define EF_PARENT_ANIMATES       (1 << 9)

#define MODEL_ROCHELLE            "models/survivors/survivor_producer.mdl"
#define MODEL_HUNTER              "models/infected/hunter.mdl"

int g_iClones[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = "[L4D2] Rochelle Tank",
    author = "SilverShot",
    description = "...",
    version = "0.1",
    url = "https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers"
}

public void OnPluginStart()
{
    HookEvent("player_death", Event_Death);
    HookEvent("tank_spawn", Event_TankSpawn);
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if( client )
    {
        if( g_iClones[client] && EntRefToEntIndex(g_iClones[client]) != INVALID_ENT_REFERENCE )
        {
            AcceptEntityInput(g_iClones[client], "Kill");
            g_iClones[client] = 0;
        }
    }
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int tank = GetClientOfUserId(event.GetInt("userid"));

    // int clone = CreateEntityByName(g_bCrazy ? "prop_dynamic" : "commentary_dummy");
    int clone = CreateEntityByName("prop_dynamic");
    SetEntityModel(clone, MODEL_ROCHELLE);
    DispatchSpawn(clone);
    g_iClones[tank] = EntIndexToEntRef(clone);

    SetEntityRenderMode(tank, RENDER_NONE);
    SetAttached(clone, tank);
}

// Lux: As a note this should only be used for dummy entity other entities need to remove EF_BONEMERGE_FASTCULL flag.
/*
*    Recreated "SetAttached" entity input from "prop_dynamic_ornament"
*/
stock void SetAttached(int iEntToAttach, int iEntToAttachTo)
{
    SetVariantString("!activator");
    AcceptEntityInput(iEntToAttach, "SetParent", iEntToAttachTo);

    SetEntityMoveType(iEntToAttach, MOVETYPE_NONE);

    SetEntProp(iEntToAttach, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_BONEMERGE_FASTCULL|EF_PARENT_ANIMATES);

    // Thanks smlib for flag understanding
    int iFlags = GetEntProp(iEntToAttach, Prop_Data, "m_usSolidFlags", 2);
    iFlags = iFlags |= 0x0004;
    SetEntProp(iEntToAttach, Prop_Data, "m_usSolidFlags", iFlags, 2);

    TeleportEntity(iEntToAttach, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
} 

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "infected"))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPostCommon);
}

public void OnSpawnPostCommon(int entity)
{
    RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

public void OnNextFrame(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    int clone = CreateEntityByName("commentary_dummy");
    SetEntityModel(clone, MODEL_HUNTER);
    DispatchSpawn(clone);

    SetEntityRenderMode(entity, RENDER_NONE);
    SetAttached(clone, entity);
}