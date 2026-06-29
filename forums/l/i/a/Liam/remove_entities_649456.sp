/**
 * vim: set ts=4 :
 * =============================================================================
 * Entity Removal
 * Removes Moveable Entities
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"

new Handle:g_Entities = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Remove Entities",
    author = "Liam",
    description = "Removes moveable objects.",
    version = VERSION,
    url = "http://www.wcugaming.org"
};

public OnPluginStart( )
{
    LoadEntitiesFromFile( );
    HookEvent("round_start", Event_RoundStart);
    CreateConVar("remove_entities_version", VERSION, "", FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart( )
{
    RemoveEntities( );
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    RemoveEntities( );
}

LoadEntitiesFromFile( )
{
    decl String:filename[64];

    BuildPath(Path_SM, filename, sizeof(filename), "configs/remove_entities.cfg");

    if(!FileExists(filename, false))
    {
        SetFailState("File %s does not exist.", filename);
        return;
    }

    if(g_Entities == INVALID_HANDLE)
        g_Entities = CreateTrie( );

    new Handle:file = OpenFile(filename, "rt");

    if(file == INVALID_HANDLE)
    {
        LogError("LoadEntitiesFromFile( ): remove_entities.cfg is missing.");
        SetFailState("Missing File: %s", filename);
        return;
    }

    while(IsEndOfFile(file) == false)
    {
        decl String:line[256];
        ReadFileLine(file, line, sizeof(line));

        if(line[0] == '\0' || line[0] == '/')
            continue;

        TrimString(line);
        SetTrieValue(g_Entities, line, 0);
    }
    CloseHandle(file);
    file = INVALID_HANDLE;
}

RemoveEntities( )
{
    new f_MaxEntities = GetMaxEntities( ), trash;
    decl String:name[64], String:model[128];

    for(new i = 0; i < f_MaxEntities; i++)
    {
        if(IsValidEntity(i))
        {
            GetEdictClassname(i, name, sizeof(name));
            if(!strcmp(name, "prop_physics_multiplayer", false))
            {
                GetEntPropString(i, Prop_Data, "m_ModelName", model, sizeof(model));
                
                if(model[0] == '\0')
                    continue;

                //PrintToServer(model);

                if(GetTrieValue(g_Entities, model, trash))
                    RemoveEdict(i);
            }

        }
    }
}