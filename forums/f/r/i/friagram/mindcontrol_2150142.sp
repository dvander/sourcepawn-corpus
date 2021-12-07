/**
    friagram@gmail.com
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <smac>

#define PLUGIN_NAME     "Mind Control"
#define PLUGIN_AUTHOR   "Friagram"
#define PLUGIN_VERSION  "1.0.1"
#define PLUGIN_DESCRIP  "Allows Admins to Torment Players"
#define PLUGIN_CONTACT  "http://steamcommunity.com/groups/poniponiponi"

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIP,
    version = PLUGIN_VERSION,
    url = PLUGIN_CONTACT
};

new g_MindControlOwner[MAXPLAYERS+1];
new g_MindControlTarget[MAXPLAYERS+1];
new g_Laser;

public OnPluginStart()
{
    CreateConVar("f_mindcontrol_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);

    RegAdminCmd("sm_mindcontrol", Command_Toggle, ADMFLAG_SLAY, "Control a player");
    RegAdminCmd("sm_mc", Command_Toggle, ADMFLAG_SLAY, "Control a player");
    
    AddCommandListener(Command_InterceptTaunt, "+taunt");
    AddCommandListener(Command_InterceptTaunt, "taunt");
    
    LoadTranslations("common.phrases");
}

public Action:SMAC_OnCheatDetected(client, const String:module[], DetectionType:type, Handle:info)
{
    if(g_MindControlOwner[client])
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public OnMapStart()
{
    g_Laser = PrecacheModel( "materials/sprites/laserbeam.vmt");
}

public Action:Command_Toggle(client, args)
{
    if(client && IsClientInGame(client))
    {
        if(args)
        {
            new String:arg1[32];
            GetCmdArg(1, arg1, sizeof(arg1));

            new String:target_name[MAX_TARGET_LENGTH];
            new target_list[MAXPLAYERS], target_count;
            new bool:tn_is_ml;

            if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
            {
                ReplyToTargetError(client, target_count);
                
                if(StringToInt(arg1) == 0)
                {
                    new count;
                    for(new i=1; i<=MaxClients; i++)
                    {
                        if(g_MindControlOwner[i] == client)
                        {
                            count++;
                            g_MindControlOwner[i] = 0;
                        }
                    }

                    PrintCenterText(client, "Releasing Minions");
                    return Plugin_Handled;
                }

                return Plugin_Handled;
            }
            
            for(new i; i<target_count; i++)
            {
                if(target_list[i] != client)
                {
                    if(g_MindControlOwner[target_list[i]] == client)
                    {
                        g_MindControlOwner[target_list[i]] = 0;
                    }
                    else
                    {
                        g_MindControlOwner[target_list[i]] = client;
                        PrintCenterText(target_list[i], "You are now %N's minion!", client);
                    }
                }
            }
            
            PrintCenterText(client, "Got %d players", target_count);

            return Plugin_Handled;
        }

        new target = TraceToTarget(client);
        if(target)
        {
            if(g_MindControlOwner[target])
            {
                if(g_MindControlOwner[target] == client)
                {
                    PrintCenterText(client, "Releasing: %N", target);

                    g_MindControlOwner[target] = 0;
                }
                else
                {
                    PrintCenterText(client, "Target already possessed");
                }

                return Plugin_Handled;
            }

            g_MindControlOwner[target] = client;

            PrintCenterText(client, "Mind Control: %N", target);
            PrintCenterText(target, "You are now %N's minion!", client);

            return Plugin_Handled;
        }

        PrintCenterText(client, "No target");
    }

    return Plugin_Handled;
}

public Action:Command_InterceptTaunt(client, const String:command[], args)
{
    static Float:cantaunt[MAXPLAYERS+1];
    new Float:time = GetEngineTime();

    if(g_MindControlOwner[client] && cantaunt[client] < time)
    {
        return Plugin_Handled;
    }

    new count;
    for(new i=1; i<=MaxClients; i++)
    {
        if(g_MindControlOwner[i] == client)
        {
            FakeClientCommandEx(i, "taunt");
            count++;
            cantaunt[i] = time + 0.1;
        }
    }
    if(count)
    {
        PrintCenterText(client, "%d Taunted", count);

        return Plugin_Handled;
    }
  
    return Plugin_Continue;
}

//first-order intercept using absolute target position (http://wiki.unity3d.com/index.php/Calculating_Lead_For_Projectiles)
FirstOrderIntercept(Float:shooterPosition[3],Float:shooterVelocity[3],Float:shotSpeed,Float:targetPosition[3],Float:targetVelocity[3])
{
    decl Float:targetRelativePosition[3];
    SubtractVectors(targetPosition, shooterPosition, targetRelativePosition);
    decl Float:targetRelativeVelocity[3];
    SubtractVectors(targetVelocity, shooterVelocity, targetRelativeVelocity);
    new Float:t = FirstOrderInterceptTime(shotSpeed, targetRelativePosition, targetRelativeVelocity);

    ScaleVector(targetRelativeVelocity, t);
    AddVectors(targetPosition, targetRelativeVelocity, targetPosition);
}

//first-order intercept using relative target position
Float:FirstOrderInterceptTime(Float:shotSpeed, Float:targetRelativePosition[3], Float:targetRelativeVelocity[3])
{
    new Float:velocitySquared = GetVectorLength(targetRelativeVelocity, true);
    if(velocitySquared < 0.001)
    {
        return 0.0;
    }

    new Float:a = velocitySquared - shotSpeed*shotSpeed;
    if (FloatAbs(a) < 0.001)  //handle similar velocities
    {
        new Float:t = -GetVectorLength(targetRelativePosition, true)/(2.0*GetVectorDotProduct(targetRelativeVelocity, targetRelativePosition));

        return t > 0.0 ? t : 0.0; //don't shoot back in time
    }

    new Float:b = 2.0*GetVectorDotProduct(targetRelativeVelocity, targetRelativePosition);
    new Float:c = GetVectorLength(targetRelativePosition, true);
    new Float:determinant = b*b - 4.0*a*c;

    if (determinant > 0.0)  //determinant > 0; two intercept paths (most common)
    { 
        new Float:t1 = (-b + SquareRoot(determinant))/(2.0*a);
        new Float:t2 = (-b - SquareRoot(determinant))/(2.0*a);
        if (t1 > 0.0)
        {
            if (t2 > 0.0) 
            {
                return t2 < t2 ? t1 : t2; //both are positive
            }
            else
            {
                return t1; //only t1 is positive
            }
        }
        else
        {
            return t2 > 0.0 ? t2 : 0.0; //don't shoot back in time
        }
    }
    else if (determinant < 0.0) //determinant < 0; no intercept path
    {
        return 0.0;
    }
    else //determinant = 0; one intercept path, pretty much never happen
    {
        determinant = -b/(2.0*a);       // temp
        return determinant > 0.0 ? determinant : 0.0; //don't shoot back in time
    }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    static Float:cooldown[MAXPLAYERS+1];
    static bool:automate[MAXPLAYERS+1];
    static fire[MAXPLAYERS+1];

    if(g_MindControlOwner[client])                      // they are being mind controlled by a player
    {
        if(IsClientInGame(g_MindControlOwner[client]))  // their handler is available
        {
            if(IsPlayerAlive(g_MindControlOwner[client]) && IsPlayerAlive(client))
            {
                new autobuttons;
                decl Float:origin[3];
                if(g_MindControlTarget[g_MindControlOwner[client]])     // do we have a target to lock onto?
                {
                    if(IsClientInGame(g_MindControlTarget[g_MindControlOwner[client]]) && IsPlayerAlive(g_MindControlTarget[g_MindControlOwner[client]]))   // valid lock, calculate puppet > target
                    {                    
                        decl Float:targetvel[3], Float:originvel[3];

                        GetClientEyePosition(client, origin);                                                         // origin (puppet player)
                        GetClientEyePosition(g_MindControlTarget[g_MindControlOwner[client]], angles);           // endpoint (target player), using angles as a buffer
                        //angles[2] -= 20.0;                                                                               // lower it from their head to center of mass (better accuracy)

                        GetEntPropVector(g_MindControlTarget[g_MindControlOwner[client]], Prop_Data, "m_vecVelocity", targetvel);
                        GetEntPropVector(client, Prop_Data, "m_vecVelocity", originvel);

                        if(automate[g_MindControlOwner[client]] && CanSeePoint(origin, angles))
                        {
/**
I'll be getting the weapon ents in spawn, and comparing theme here to set the predicted speeds.
It would be much better to use some internal function for this stuff.

Weapon type speeds:
standard rocket: 1100.0

                            decl Float:projspeed;
                            switch(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
                            {
                                case g_clientweapon[WEAPON_PRIMARY][WEAPON_ENT]: g_clientweapon[WEAPON_PRIMARY][WEAPON_SPEED]
                                case g_clientweapon[WEAPON_SECONDARY][WEAPON_ENT]: g_clientweapon[WEAPON_SECONDARY][WEAPON_SPEED]
                                default: projspeed = 1000000.0;
                            }
**/
                            new Float:distance = GetVectorDistance(origin, angles, true);

                            if(GetPlayerWeaponSlot(client, 2) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
                            {
                                if(distance > 4900.0)
                                {
                                    autobuttons = IN_FORWARD;
                                }
                                else if(distance < 1600.0)
                                {
                                    autobuttons = IN_BACK;
                                }
                            }
                            else
                            {
                                if(distance > 360000.0)
                                {
                                    autobuttons = IN_FORWARD;
                                }
                                else if(distance < 160000.0)
                                {
                                    autobuttons = IN_BACK;
                                }
                            }

                            if(fire[client] < 132)
                            {
                                fire[client]++;
                                autobuttons |= IN_RELOAD;   // converted to attack
                            }
                            else
                            {
                                fire[client] = 0;
                            }
                        }
                        /**
                        attempt to overcome CSP/lerp by aiming ahead for the client.
                        This could also be used to predict intercept course of projectiles,
                        It's not fully tested/implemented, but I think it works.
                        Low values = low "bullet/projectile" velocity = more lead
                        **/
                        FirstOrderIntercept(origin, originvel, 1000000.0, angles, targetvel);                       // if it succeeds, the target position will be updated
                    }
                    else                                                                                                  // there was a lock, but it's bad now, so remove it.
                    {
                        GetClientEyePosition(g_MindControlOwner[client], origin);                                   // calculate owner > target
                        GetClientEyeAngles(g_MindControlOwner[client], angles);
                        TR_TraceRayFilter(origin, angles, MASK_SHOT, RayType_Infinite, Ray_DontHitThis, client);
                        TR_GetEndPosition(angles);                                                                     // it's going to hit something somewhere, always.

                        g_MindControlTarget[g_MindControlOwner[client]] = 0;
                        
                        PrintCenterText(g_MindControlOwner[client], "Lock Lost");
                    }
                }
                else
                {
                    GetClientEyePosition(g_MindControlOwner[client], origin);                                       // calculate owner > target
                    GetClientEyeAngles(g_MindControlOwner[client], angles);
                    TR_TraceRayFilter(origin, angles, MASK_SHOT, RayType_Infinite, Ray_DontHitThis, client);        // it's going to hit something somewhere, always.
                    TR_GetEndPosition(angles);
                }

                GetClientEyePosition(client, origin);

                origin[2] -= 20.0;
                if(autobuttons)
                {
                    TE_SetupBeamPoints(origin, angles, g_Laser, 0, 0, 0, 0.1, 0.5, 0.5, 1, 0.0, {255, 0, 0, 192}, 0);   // draw the beam from the attack position to the end position for owner and puppet
                }
                else
                {
                    TE_SetupBeamPoints(origin, angles, g_Laser, 0, 0, 0, 0.1, 0.5, 0.5, 1, 0.0, {255, 0, 128, 192}, 0);
                }
                
                decl clients[2];
                clients[0] = g_MindControlOwner[client];
                clients[1] = client;
                TE_Send(clients, 2);
                origin[2] += 20.0;
                
                MakeVectorFromPoints(origin, angles, angles);
                GetVectorAngles(angles, angles);
                
                if(angles[0] > 90.0)     // correct upwards angle sign
                {
                    angles[0] -= 360.0;
                }
                
                TeleportEntity(client, NULL_VECTOR, angles, NULL_VECTOR);

                if(autobuttons)
                {
                    buttons = autobuttons | GetClientButtons(g_MindControlOwner[client]);     // override the puppet's commands with the owner's
                }
                else
                {
                    buttons = GetClientButtons(g_MindControlOwner[client]);     // override the puppet's commands with the owner's
                }
                
                if(buttons & IN_ATTACK3)    // attack3 will allow the owner to freeze their own movement
                {
                    buttons &= ~ IN_ATTACK3;

                    new Float:time = GetEngineTime();
                    if(cooldown[g_MindControlOwner[client]] < time)
                    {
                        cooldown[g_MindControlOwner[client]] = time + 0.5;
                        TF2_StunPlayer(g_MindControlOwner[client], 0.6, 1.0, TF_STUNFLAG_SLOWDOWN);
                    }
                }
                if(buttons & IN_USE)    // use will lock onto any valid player (doens't check teams here)
                {
                    new Float:time = GetEngineTime();
                    if(cooldown[g_MindControlOwner[client]] < time)
                    {
                        if(g_MindControlTarget[g_MindControlOwner[client]]) // they have a lock
                        {
                            if(buttons & IN_ATTACK2)
                            {
                                automate[g_MindControlOwner[client]] = true;
                                cooldown[g_MindControlOwner[client]] = time + 1.0;
                                PrintCenterText(g_MindControlOwner[client], "AutoLock On");
                            }
                            else
                            {
                                g_MindControlTarget[g_MindControlOwner[client]] = 0;
                            
                                PrintCenterText(g_MindControlOwner[client], "Lock Off");
                            }
                        }
                        else if((g_MindControlTarget[g_MindControlOwner[client]] = TraceToTarget(g_MindControlOwner[client])))
                        {
                            cooldown[g_MindControlOwner[client]] = time + 1.0;

                            PrintCenterText(g_MindControlOwner[client], "Lock On: %N", g_MindControlTarget[g_MindControlOwner[client]]);
                            automate[g_MindControlOwner[client]] = false;
                        }
                    }
                }

                if (buttons & IN_FORWARD)         vel[0] = 300.0;   // give them velocity to facilitate movement
                else if (buttons & IN_BACK)       vel[0] = -300.0;
                else                               vel[0] = 0.0;    // zero out velocity (for some reason MVM bots need this)
                
                if (buttons & IN_MOVELEFT)        vel[1] = 300.0;
                else if (buttons & IN_MOVERIGHT)  vel[1] = -300.0;
                else                               vel[1] = 0.0;
                
                if (buttons & IN_RELOAD)          buttons |= IN_ATTACK; // using reload to make them attack
                else                               buttons &= ~IN_ATTACK;

                if (buttons & IN_ATTACK)          buttons |= IN_RELOAD; // using attack to make them reload
                else                               buttons &= ~IN_RELOAD;

                if (buttons & IN_SCORE) // using score to make them swap weapons
                {
                    buttons &= ~IN_SCORE;

                    new Float:time = GetEngineTime();
                    if(cooldown[client] < time)
                    {
                        cooldown[client] = time + 0.5;
                        new count;
                        decl weapons[3];
                        new active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

                        for(new i; i<3; i++)
                        {
                            weapons[count] = GetPlayerWeaponSlot(client, i);
                            if(weapons[count] != -1)
                            {
                                count++;
                            }
                        }
                        
                        if(count > 1)
                        {
                            decl newactive;

                            switch(count)
                            {
                            case 2:
                                {
                                    if(active == weapons[0])        newactive = weapons[1];        // primary > secondary
                                    else                              newactive = weapons[0];        // secondary > primary
                                }
                            case 3:
                                {
                                    if(active == weapons[0])        newactive = weapons[1];        // primary > secondary
                                    else if(active == weapons[1])   newactive = weapons[2];        // secondary > melee
                                    else                              newactive = weapons[0];        // melee > primary
                                }
                            }

                            decl String:weaponname[32];
                            decl String:newweaponname[32];
                            if (GetEntityClassname(active, weaponname, 32) && StrEqual(weaponname, "tf_weapon_minigun"))
                            {
                                SetEntProp(active, Prop_Send, "m_iWeaponState", 0);   // stop the barrel, or it will spin forever
                                TF2_RemoveCondition(client, TFCond_Slowed);
                            }
                            
                            SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon",  newactive);
                            if(GetEntityClassname(newactive, newweaponname, 32))
                            {
                                PrintCenterText(g_MindControlOwner[client], "%d: %s -> %s", count, weaponname[10], newweaponname[10]);  // skip tf_weapon_
                            }
                        }
                    }
                }

                return Plugin_Changed;
            }

            PrintCenterText(g_MindControlOwner[client], "Target Lost"); // their target is not valid
        }

        g_MindControlTarget[g_MindControlOwner[client]] = 0;
        g_MindControlOwner[client] = 0;
    }

    return Plugin_Continue;
}

public bool:Ray_DontHitThis(entity, mask, any:client)   // don't hit the owner, 
{
    if(client == entity || g_MindControlOwner[client] == entity)    // don't hit the owner,  don't hit the puppet's owner
    {
        return false;
    }
    if(entity >0 && entity <= MaxClients)
    {
        if(g_MindControlOwner[entity] == client)    // don't hit any of the owner's puppets
        {
            return false;
        }
    }

    return true;
}

public TraceToTarget(client)
{
    new Float:vecClientEyePos[3], Float:vecClientEyeAng[3];
    GetClientEyePosition(client, vecClientEyePos);
    GetClientEyeAngles(client, vecClientEyeAng);

    TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_SHOT, RayType_Infinite, TraceRayClients, client);

    if (TR_DidHit(INVALID_HANDLE))
    {
        new ent = TR_GetEntityIndex(INVALID_HANDLE);
        if(ent != 0)
        {
            return ent;
        }
    }

    return 0;
}

public bool:TraceRayClients(entityhit, mask, any:client)
{
    if(client != entityhit && entityhit > 0 && entityhit <= MaxClients && IsPlayerAlive(entityhit)) // don't hit self, but hit other players
    {
        return true;
    }

    return false;
}

public CanSeePoint(Float:start[3], Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_SHOT, RayType_EndPoint, TraceRayDontHitClients);
	return !TR_DidHit(INVALID_HANDLE);
}

public bool:TraceRayDontHitClients(entity, contentsMask)	// false for clients (filter out everything else)
{
    return !(entity > 0 && entity <= MaxClients);
}