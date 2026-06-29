/**
 * vim: set ts=4 :
 * jedit:mode=c++:tabSize=4:indentSize=4:noTabs=true:folding=indent:
 * =============================================================================
 * SourceMod Insurgency beta 2 - Test GetClientSquad Plugin
 * Provides a console testing command sm_test_getclientsquad.
 *
 * 166_MMX.TVR.  All rights reserved.
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
 * Version: $Id$
 *
 *
 * v1.0.0 - 2009-10-10
 *   +          Initial release
 */

//==============================================================================
// Compiler Directives
//==============================================================================

#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <ins_lib_getclientsquad>
#define REQUIRE_PLUGIN

#define PLUGIN_NAME             "INS b2 - Test GetClientSquad"
#define PLUGIN_VERSION          "1.0.0"

//==============================================================================
// Plugin information
//==============================================================================

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = "166_MMX.TVR",
    description = "Provides a console testing command sm_getclientsquad",
    version     = PLUGIN_VERSION,
    url         = "http://www.sourcemod.net/"
};

//==============================================================================
// Global variables
//==============================================================================

static bool:g_bIsGetClientSquadAvail = false;

//==============================================================================
// Private functions
//==============================================================================

//==============================================================================
// Privately called event handlers
//==============================================================================

public Action:ConCmd_sm_test_getclientteam(client, args)
{
    if (args != 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_test_getclientteam <#userid>");
        return Plugin_Handled;
    }
    
    decl String:sUserId[6];
    GetCmdArg(1, sUserId, sizeof(sUserId));
    new iUserId           = StringToInt(sUserId);
    new iTargetClient     = GetClientOfUserId(iUserId);
    new iTargetClientTeam = GetClientTeam(iTargetClient);
    
    ReplyToCommand(client, "[SM] GetClientTeam(%i): %i",
        iTargetClient, iTargetClientTeam);
    
    return Plugin_Handled;
}

public Action:ConCmd_sm_test_getclientsquad(client, args)
{
    if (!g_bIsGetClientSquadAvail)
    {
        ReplyToCommand(client, "[SM] Missing GetCLientSquad library");
        return Plugin_Handled;
    }
    
    if (args != 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_test_getclientsquad <#userid>");
        return Plugin_Handled;
    }
    
    decl String:sUserId[6];
    GetCmdArg(1, sUserId, sizeof(sUserId));
    new iUserId           = StringToInt(sUserId);
    new iTargetClient     = GetClientOfUserId(iUserId);
    new iTargetClientTeam = GetClientSquad(iTargetClient);
    
    ReplyToCommand(client, "[SM] GetClientSquad(%i): %i",
        iTargetClient, iTargetClientTeam);
    
    return Plugin_Handled;
}

//==============================================================================
// Public functions
//==============================================================================

//==============================================================================
// Globally called event handlers
//==============================================================================

public OnPluginStart()
{
    CreateConVar("sm_ins_test_getclientsquad_version", PLUGIN_VERSION,
        "Insurgency beta 2 Library GetClientSquad Version",
        FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);

    decl String:sGameFolderName[256];
    GetGameFolderName(sGameFolderName, sizeof(sGameFolderName));
    new bool:bIsGameIns = (strcmp(sGameFolderName, "insurgency") == 0);

    if (!bIsGameIns)
    {
        LogError(
            "Skipping initialization of \"%s\" due to game folder name mismatch. Expected \"%s\" but found \"%s\" (case sensitive match).",
            PLUGIN_NAME, "insurgency", sGameFolderName);
        return;
    }
    
    g_bIsGetClientSquadAvail = LibraryExists("ins_lib_getclientsquad");
    
    RegConsoleCmd("sm_test_getclientteam",  ConCmd_sm_test_getclientteam);
    RegConsoleCmd("sm_test_getclientsquad", ConCmd_sm_test_getclientsquad);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "ins_lib_getclientsquad"))
    {
        g_bIsGetClientSquadAvail = true;
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "ins_lib_getclientsquad"))
    {
        g_bIsGetClientSquadAvail = false;
    }
}

