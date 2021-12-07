/*
 * ============================================================================
 *
 *  AntiStick
 *
 *  File:          antistick.sp
 *  Type:          Base
 *  Description:   Antistick system.
 *
 *  Copyright (C) 2009  Greyscale
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.0"

/**
 * Record plugin info.
 */
public Plugin:myinfo =
{
    name = "AntiStick",
    author = "Greyscale",
    description = "Automatically allow unstick players that are stuck together.",
    version = VERSION,
    url = "http://forums.alliedmods.net"
};

/**
 * @section Collision values.
*/
#define ANTISTICK_COLLISIONS_OFF 2
#define ANTISTICK_COLLISIONS_ON 5
/**
 * @endsection
*/

/**
 * Default player hull width.
 */
#define ANTISTICK_DEFAULT_HULL_WIDTH 32.0

/**
 * @section Global cvar handles.
 */
new Handle:g_cvEnable = INVALID_HANDLE;
/**
 * @endsection
 */

/**
 * List of components that make up the model's rectangular boundaries.
 * 
 * F = Front
 * B = Back
 * L = Left
 * R = Right
 * U = Upper
 * D = Down
 */
enum AntiStickBoxBound
{
    BoxBound_FUR = 0, /** Front upper right */
    BoxBound_FUL,     /** etc.. */
    BoxBound_FDR,
    BoxBound_FDL,
    BoxBound_BUR,
    BoxBound_BUL,
    BoxBound_BDR,
    BoxBound_BDL,
}
/**
 * Plugin is loading.
 */
public OnPluginStart()
{
    // Load translations.
    LoadTranslations("common.phrases.txt");
    
    // Create cvars.
    g_cvEnable = CreateConVar("as_enable", "1", "Enable AntiStick plugin to prevent players from sticking in each other.");
    
    // Auto-generate config file if it doesn't exist, then execute.
    AutoExecConfig(true);
}

/**
 * Client is joining the game.
 * 
 * @param client    The client index.
 */
public OnClientPutInServer(client)
{
    // Hook "StartTouch" on client.
    SDKHook(client, SDKHook_StartTouch, AntiStickStartTouch);
}

/**
 * Callback function for StartTouch.
 * 
 * @param client        The client index.
 * @param entity        The entity index of the entity being touched.
 */
public Action:AntiStickStartTouch(client, entity)
{
    // If antistick is disabled, then stop.
    new bool:enable = GetConVarBool(g_cvEnable);
    if (!enable)
    {
        return;
    }
    
    // If client isn't in-game, then stop.
    if (!IsClientInGame(client))
    {
        return;
    }
    
    // If client is touching themselves, then leave them alone :P
    if (client == entity)
    {
        return;
    }
    
    // If touched entity isn't a valid client, then stop.
    if (entity <= 0 || entity > MaxClients)
    {
        return;
    }
    
    // If the clients aren't colliding, then stop.
    if (!AntiStickIsModelBoxColliding(client, entity))
    {
        return;
    }
    
    // Disable collisions to unstick, and start timers to re-solidify.
    if (AntiStickClientCollisionGroup(client) == ANTISTICK_COLLISIONS_ON)
    {
        AntiStickClientCollisionGroup(client, true, ANTISTICK_COLLISIONS_OFF);
        CreateTimer(0.0, AntiStickSolidifyTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    }
    
    if (AntiStickClientCollisionGroup(entity) == ANTISTICK_COLLISIONS_ON)
    {
        AntiStickClientCollisionGroup(entity, true, ANTISTICK_COLLISIONS_OFF);
        CreateTimer(0.0, AntiStickSolidifyTimer, entity, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
    }
}

/**
 * Callback function for EndTouch.
 * 
 * @param client        The client index.
 * @param entity        The entity index of the entity being touched.
 */
public Action:AntiStickSolidifyTimer(Handle:timer, any:client)
{
    // If client has left, then stop the timer.
    if (!IsClientInGame(client))
    {
        return Plugin_Stop;
    }
    
    // If the client's collisions are already on, then stop.
    if (AntiStickClientCollisionGroup(client) == ANTISTICK_COLLISIONS_ON)
    {
        return Plugin_Stop;
    }
    
    // Loop through all client's and check if client is stuck in them.
    for (new x = 1; x <= MaxClients; x++)
    {
        // If client isn't in-game, then stop.
        if (!IsClientInGame(x))
        {
            continue;
        }
        
        // Don't compare the same clients.
        if (client == x)
        {
            continue;
        }
        
        // If the client is colliding with a client, then allow timer to continue.
        if (AntiStickIsModelBoxColliding(client, x))
        {
            return Plugin_Continue;
        }
    }
    
    // Change collisions back to normal.
    AntiStickClientCollisionGroup(client, true, ANTISTICK_COLLISIONS_ON);
    
    return Plugin_Stop;
}

/**
 * Build the model box by finding all vertices.
 * 
 * @param client        The client index.
 * @param boundaries    Array with 'AntiStickBoxBounds' for indexes to return bounds into.
 * @param width         The width of the model box.
 */
stock AntiStickBuildModelBox(client, Float:boundaries[AntiStickBoxBound][3])
{
    new Float:clientloc[3];
    new Float:twistang[3];
    new Float:cornerang[3];
    new Float:sideloc[3];
    new Float:finalloc[4][3];
    
    // Get needed vector info.
    GetClientAbsOrigin(client, clientloc);
    
    // Set the pitch to 0.
    twistang[1] = 90.0;
    cornerang[1] = 0.0;
    
    for (new x = 0; x < 4; x++)
    {
        // Jump to point on player's left side.
        AntiStickJumpToPoint(clientloc, twistang, ANTISTICK_DEFAULT_HULL_WIDTH / 2, sideloc);
        
        // From this point, jump to the corner, which would be half the width from the middle of a side.
        AntiStickJumpToPoint(sideloc, cornerang, ANTISTICK_DEFAULT_HULL_WIDTH / 2, finalloc[x]);
        
        // Twist 90 degrees to find next side/corner.
        twistang[1] += 90.0;
        cornerang[1] += 90.0;
        
        // Fix angles.
        if (twistang[1] > 180.0)
        {
            twistang[1] -= 360.0;
        }
        
        if (cornerang[1] > 180.0)
        {
            cornerang[1] -= 360.0;
        }
    }
    
    // Copy all horizontal model box data to array.
    boundaries[BoxBound_FUR][0] = finalloc[3][0];
    boundaries[BoxBound_FUR][1] = finalloc[3][1];
    boundaries[BoxBound_FUL][0] = finalloc[0][0];
    boundaries[BoxBound_FUL][1] = finalloc[0][1];
    boundaries[BoxBound_FDR][0] = finalloc[3][0];
    boundaries[BoxBound_FDR][1] = finalloc[3][1];
    boundaries[BoxBound_FDL][0] = finalloc[0][0];
    boundaries[BoxBound_FDL][1] = finalloc[0][1];
    boundaries[BoxBound_BUR][0] = finalloc[2][0];
    boundaries[BoxBound_BUR][1] = finalloc[2][1];
    boundaries[BoxBound_BUL][0] = finalloc[1][0];
    boundaries[BoxBound_BUL][1] = finalloc[1][1];
    boundaries[BoxBound_BDR][0] = finalloc[2][0];
    boundaries[BoxBound_BDR][1] = finalloc[2][1];
    boundaries[BoxBound_BDL][0] = finalloc[1][0];
    boundaries[BoxBound_BDL][1] = finalloc[1][1];
    
    // Set Z bounds.
    new Float:eyeloc[3];
    GetClientEyePosition(client, eyeloc);
    
    boundaries[BoxBound_FUR][2] = eyeloc[2];
    boundaries[BoxBound_FUL][2] = eyeloc[2];
    boundaries[BoxBound_FDR][2] = clientloc[2] + 15.0;
    boundaries[BoxBound_FDL][2] = clientloc[2] + 15.0;
    boundaries[BoxBound_BUR][2] = eyeloc[2];
    boundaries[BoxBound_BUL][2] = eyeloc[2];
    boundaries[BoxBound_BDR][2] = clientloc[2] + 15.0;
    boundaries[BoxBound_BDL][2] = clientloc[2] + 15.0;
}

/**
 * Jumps from a point to another based off angle and distance.
 * 
 * @param vec       Point to jump from.
 * @param ang       Angle to base jump off of.
 * @param distance  Distance to jump
 * @param result    Resultant point.
 */
stock AntiStickJumpToPoint(const Float:vec[3], const Float:ang[3], Float:distance, Float:result[3])
{
    new Float:viewvec[3];
    
    // Turn client angle, into a vector.
    GetAngleVectors(ang, viewvec, NULL_VECTOR, NULL_VECTOR);
    
    // Normalize vector.
    NormalizeVector(viewvec, viewvec);
    
    // Scale to the given distance.
    ScaleVector(viewvec, distance);
    
    // Add the vectors together.
    AddVectors(vec, viewvec, result);
}
    
/**
 * Get the max/min value of a 3D box on any axis.
 * 
 * @param axis          The axis to check.
 * @param boundaries    The boundaries to check.
 * @param min           Return the min value instead.
 */
stock Float:AntiStickGetBoxMaxBoundary(axis, Float:boundaries[AntiStickBoxBound][3], bool:min = false)
{
    // Create 'outlier' with initial value of first boundary.
    new Float:outlier = boundaries[0][axis];
    
    // x = Boundary index. (Start at 1 because we initialized 'outlier' with the 0 index's value)
    new size = sizeof(boundaries);
    for (new x = 1; x < size; x++)
    {
        if (!min && boundaries[x][axis] > outlier)
        {
            outlier = boundaries[x][axis];
        }
        else if (min && boundaries[x][axis] < outlier)
        {
            outlier = boundaries[x][axis];
        }
    }
    
    // Return value.
    return outlier;
}

/**
 * Checks if a player is currently stuck within another player.
 *
 * @param client1   The first client index.
 * @param client2   The second client index.
 * @return          True if they are stuck together, false if not.
 */
stock bool:AntiStickIsModelBoxColliding(client1, client2)
{
    new Float:client1modelbox[AntiStickBoxBound][3];
    new Float:client2modelbox[AntiStickBoxBound][3];
    
    // Build model boxes for each client.
    AntiStickBuildModelBox(client1, client1modelbox);
    AntiStickBuildModelBox(client2, client2modelbox);
    
    // Compare x values.
    new Float:max1x = AntiStickGetBoxMaxBoundary(0, client1modelbox);
    new Float:max2x = AntiStickGetBoxMaxBoundary(0, client2modelbox);
    new Float:min1x = AntiStickGetBoxMaxBoundary(0, client1modelbox, true);
    new Float:min2x = AntiStickGetBoxMaxBoundary(0, client2modelbox, true);
    
    if (max1x < min2x || min1x > max2x)
    {
        return false;
    }
    
    // Compare y values.
    new Float:max1y = AntiStickGetBoxMaxBoundary(1, client1modelbox);
    new Float:max2y = AntiStickGetBoxMaxBoundary(1, client2modelbox);
    new Float:min1y = AntiStickGetBoxMaxBoundary(1, client1modelbox, true);
    new Float:min2y = AntiStickGetBoxMaxBoundary(1, client2modelbox, true);
    
    if (max1y < min2y || min1y > max2y)
    {
        return false;
    }
    
    // Compare z values.
    new Float:max1z = AntiStickGetBoxMaxBoundary(2, client1modelbox);
    new Float:max2z = AntiStickGetBoxMaxBoundary(2, client2modelbox);
    new Float:min1z = AntiStickGetBoxMaxBoundary(2, client1modelbox, true);
    new Float:min2z = AntiStickGetBoxMaxBoundary(2, client2modelbox, true);
    
    if (max1z < min2z || min1z > max2z)
    {
        return false;
    }
    
    // They are intersecting.
    return true;
}

/**
 * Set collision group flags on a client.
 * @param client            The client index.
 * @param collisiongroup    Collision group flag.
 * @return                  The collision group on the client, -1 if applying collision group. 
 */
AntiStickClientCollisionGroup(client, bool:apply = false, collisiongroup = 0)
{
    if (apply)
    {
        SetEntProp(client, Prop_Data, "m_CollisionGroup", collisiongroup);
        
        return -1;
    }
    
    return GetEntProp(client, Prop_Data, "m_CollisionGroup");
}