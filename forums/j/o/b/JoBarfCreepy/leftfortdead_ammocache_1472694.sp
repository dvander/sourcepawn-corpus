#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"
#define DESCRIPTION "Spawn items to help you to fortify defense"

#define MODEL_MINIGUN       "models/w_models/weapons/w_minigun.mdl"
#define MODEL_AMMOCACHE     "models/props/de_prodigy/ammo_can_03.mdl"
#define MODEL_COFFEECACHE   "models/props/de_prodigy/ammo_can_03.mdl"
#define MODEL_IRONDOOR      "models/props_doors/checkpoint_door_01.mdl"

new Handle:g_cvar_adminonly     = INVALID_HANDLE;
new Handle:g_cvar_enabled        = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name        = "[L4D] Left FORT Dead",
    author      = "Boikinov",
    description = DESCRIPTION,
    version     = VERSION,
    url         = ""
};


public OnPluginStart()
{
    CreateConVar( "leftfortdead_version", VERSION, DESCRIPTION, FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );

    RegConsoleCmd( "leftfortdead_spawnammocache", SpawnAmmoCache, "spawn an ammo stack", FCVAR_PLUGIN );



    g_cvar_enabled   = CreateConVar( "leftfortdead_enabled", "1", "0: disable Left FORT Dead MOD, 1: enable MOD", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DEMO );
    g_cvar_adminonly = CreateConVar( "leftfortdead_adminonly", "0", "0: every client can build, 1: only admin can build", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DEMO );
}

public OnMapStart()
{
    SetRandomSeed( RoundFloat( GetEngineTime() ) );
}

////////////////////////////////////////////////////////////////////////////////
//
// registered commands
//
////////////////////////////////////////////////////////////////////////////////

//---------------------------------------------------------
// spawn a minigun
// the field of fire arc is sticked after you spawned it
// so place it well, or delete it and respawn it with a better angle
//---------------------------------------------------------
public Action:SpawnMinigun( client, args )
{
    if ( !IsAccessGranted( client ) )
    {
        return Plugin_Handled;
    }
    
    new index = CreateEntity( client, "prop_minigun_l4d1", "minigun", MODEL_MINIGUN );
    if ( index != -1 )
    {
        decl Float:position[3], Float:angles[3];
        if ( GetClientAimedLocationData( client, position, angles, NULL_VECTOR ) == -1 )
        {
            RemoveEdict( index );
            ReplyToCommand( client, "[Left FORT Dead] Can't find a location to place, remove entity (%i)", index );
            return Plugin_Handled;
        }
        
        angles[0] = 0.0;
        angles[2] = 0.0;
        DispatchKeyValueVector( index, "Origin", position );
        DispatchKeyValueVector( index, "Angles", angles );
        DispatchKeyValueFloat( index, "MaxPitch",  40.00 );
        DispatchKeyValueFloat( index, "MinPitch", -30.00 );
        DispatchKeyValueFloat( index, "MaxYaw",    90.00 );
        DispatchSpawn( index );
        }

    return Plugin_Handled;
}

//---------------------------------------------------------
// spawn an ammo stack
//---------------------------------------------------------
public Action:SpawnAmmoCache( client, args )
{
    if ( !IsAccessGranted( client ) )
    {
        return Plugin_Handled;
    }

    new index;
    if ( GetRandomInt( 1, 2 ) == 1 )
    {
        index = CreateEntity( client, "weapon_ammo_spawn", "ammo stack", MODEL_AMMOCACHE );
    }
    else
    {
        index = CreateEntity( client, "weapon_ammo_spawn", "ammo stack", MODEL_COFFEECACHE );
    }

    if ( index != -1 )
    {
        decl Float:position[3], Float:ang_eye[3], Float:ang_ent[3], Float:normal[3];
        if ( GetClientAimedLocationData( client, position, ang_eye, normal ) == -1 )
        {
            RemoveEdict( index );
            ReplyToCommand( client, "[Left FORT Dead] Can't find a location to place, remove entity (%i)", index );
            return Plugin_Handled;
        }

        NegateVector( normal );
        GetVectorAngles( normal, ang_ent );
        ang_ent[0] += 90.0;
        
        decl Float:cross[3], Float:vec_eye[3], Float:vec_ent[3];
        GetAngleVectors( ang_eye, vec_eye, NULL_VECTOR, NULL_VECTOR );
        GetAngleVectors( ang_ent, vec_ent, NULL_VECTOR, NULL_VECTOR );
        GetVectorCrossProduct( vec_eye, normal, cross );
        new Float:yaw = GetAngleBetweenVectors( vec_ent, cross, normal );
        RotateYaw( ang_ent, yaw + 90.0 );

        DispatchKeyValueVector( index, "Origin", position );
        DispatchKeyValueVector( index, "Angles", ang_ent );
        DispatchSpawn( index );
    }

    return Plugin_Handled;
}

//---------------------------------------------------------
// spawn an iron door, which is unbreakable
// the door angle will align to wall(if placed on wall)
// and try to stand on floor and under ceil if now far from them
//---------------------------------------------------------
public Action:SpawnIronDoor( client, args )
{
    if ( !IsAccessGranted( client ) )
    {
        return Plugin_Handled;
    }

    new index = CreateEntity( client, "prop_door_rotating", "iron door", MODEL_IRONDOOR );
    if ( index != -1 )
    {
        decl Float:position[3], Float:angles[3], Float:normal[3];
        if ( GetClientAimedLocationData( client, position, angles, normal ) == -1 )
        {
            RemoveEdict( index );
            ReplyToCommand( client, "[Left FORT Dead] Can't find a location to place, remove entity (%i)", index );
            return Plugin_Handled;
        }
        
        decl Float:min[3], Float:max[3];
        GetEntPropVector( index, Prop_Send, "m_vecMins", min );
        GetEntPropVector( index, Prop_Send, "m_vecMaxs", max );
        
        // try to stand on floor and under ceil if close enough
        decl Float:right[3], Float:pos_new[3], Float:ang_new[3];
        GetVectorVectors( normal, right, NULL_VECTOR );

        new Handle:trace;

        pos_new[0] = position[0] + normal[0] * 30.0;
        pos_new[1] = position[1] + normal[1] * 30.0;
        pos_new[2] = position[2];

        new bool:decided = false;

        ang_new[0] = 90.0;
        ang_new[1] = 0.0;
        ang_new[2] = 0.0;
        trace = TR_TraceRayFilterEx( pos_new, ang_new, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayers );
        if ( TR_DidHit( trace ) )
        {
            decl Float:below[3];
            TR_GetEndPosition( below, trace );
            if ( pos_new[2] + min[2] <= below[2] )
            {
                position[2] = below[2] - min[2];
                decided = true;
            }
        }
        CloseHandle( trace );

        if ( !decided )
        {
            ang_new[0] = 270.0;
            trace = TR_TraceRayFilterEx( pos_new, ang_new, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayers );
            if ( TR_DidHit( trace ) )
            {
                decl Float:above[3];
                TR_GetEndPosition( above, trace );
                if ( pos_new[2] + max[2] >= above[2] )
                {
                    position[2] = above[2] - max[2];
                }
            }
            CloseHandle( trace );
        }

        // align angle to wall if placed on wall
        if ( normal[2] < 1.0 && normal[2] > -1.0 )
        {
            GetVectorAngles( right, angles );
        }

        angles[0] = 0.0;
        angles[2] = 0.0;
        position[0] += normal[0] * 2.0;
        position[1] += normal[1] * 2.0;
        DispatchKeyValueVector( index, "Origin", position );
        DispatchKeyValueVector( index, "Angles", angles );
        SetEntProp( index, Prop_Data, "m_spawnflags", 8192 );
        SetEntProp( index, Prop_Data, "m_bForceClosed", 0 );
        SetEntProp( index, Prop_Data, "m_nHardwareType", 1 );
        SetEntPropFloat( index, Prop_Data, "m_flAutoReturnDelay", -1.0 );
        SetEntPropFloat( index, Prop_Data, "m_flSpeed", 200.0 );
        DispatchSpawn( index );
    }

    return Plugin_Handled;
}

//---------------------------------------------------------
// spawn a prop_dynamic entity
//---------------------------------------------------------
public Action:SpawnItem( client, args )
{
    if ( !IsAccessGranted( client ) )
    {
        return Plugin_Handled;
    }

    if ( args < 3 )
    {
        ReplyToCommand( client, "[Left FORT Dead] Usage: leftfortdead_spawnitem <d|p> <i|a> \"filename.mdl\" [1|-1]\n    \
                                    d = dynamic item, p = physics item\n    \
                                    i = spawn in front of you\n    \
                                    a = spawn at where you aim\n    \
                                    1 = place facing toward you\n   \
                                    -1 = place facing against you" );
        return Plugin_Handled;
    }
    
    new String:param[128];
    
    new bool:isPhysics = false;
    GetCmdArg( 1, param, sizeof(param) );
    if ( strcmp( param, "p" ) == 0 )
    {
        isPhysics = true;
    }
    else if ( strcmp( param, "d" ) != 0 )
    {
        ReplyToCommand( client, "[Left FORT Dead] unknown parameter: %s", param );
        return Plugin_Handled;
    }

    new bool:isInFront = false;
    GetCmdArg( 2, param, sizeof(param) );
    if ( strcmp( param, "i" ) == 0 )
    {
        isInFront = true;
    }
    else if ( strcmp( param, "a" ) != 0 )
    {
        ReplyToCommand( client, "[Left FORT Dead] unknown parameter: %s", param );
        return Plugin_Handled;
    }
    
    new String:modelname[128];
    GetCmdArg( 3, modelname, sizeof(modelname) );
    
    new facing = 0;
    if ( args > 3 )
    {
        GetCmdArg( 4, param, sizeof(param) );
        facing = StringToInt( param );
    }

    new index = -1;
    if ( isPhysics )
    {
        index = CreateEntity( client, "prop_physics_override", "physics item", modelname );
    }
    else
    {
        index = CreateEntity( client, "prop_dynamic_override", "dynamic item", modelname );
    }
    
    if ( index != -1 )
    {
        decl Float:min[3], Float:max[3];
        GetEntPropVector( index, Prop_Send, "m_vecMins", min );
        GetEntPropVector( index, Prop_Send, "m_vecMaxs", max );

        decl Float:position[3], Float:ang_eye[3], Float:ang_ent[3], Float:normal[3];
        if ( isInFront )
        {
            new Float:distance = 50.0;
            if ( facing == 0 )
            {
                distance += SquareRoot( (max[0] - min[0]) * (max[0] - min[0]) + (max[1] - min[1]) * (max[1] - min[1]) ) * 0.5;
            }
            else if ( facing > 0 )
            {
                distance += max[0];
            }
            else
            {
                distance -= min[0];
            }
            
            GetClientFrontLocationData( client, position, ang_eye, distance );
            normal[0] = 0.0;
            normal[1] = 0.0;
            normal[2] = 1.0;
        }
        else
        {
            if ( GetClientAimedLocationData( client, position, ang_eye, normal ) == -1 )
            {
                RemoveEdict( index );
                ReplyToCommand( client, "[Left FORT Dead] Can't find a location to place, remove entity (%i)", index );
                return Plugin_Handled;
            }
        }
        
        NegateVector( normal );
        GetVectorAngles( normal, ang_ent );
        ang_ent[0] += 90.0;
        
        // the created entity will face a default direction based on ground normal
        
        if ( facing != 0 )
        {
            // here we will rotate the entity to let it face or back to you
            decl Float:cross[3], Float:vec_eye[3], Float:vec_ent[3];
            GetAngleVectors( ang_eye, vec_eye, NULL_VECTOR, NULL_VECTOR );
            GetAngleVectors( ang_ent, vec_ent, NULL_VECTOR, NULL_VECTOR );
            GetVectorCrossProduct( vec_eye, normal, cross );
            new Float:yaw = GetAngleBetweenVectors( vec_ent, cross, normal );
            if ( facing > 0 )
            {
                RotateYaw( ang_ent, yaw - 90.0 );
            }
            else
            {
                RotateYaw( ang_ent, yaw + 90.0 );
            }
        }
        
        // avoid some model burying under ground/in wall
        // don't forget the normal was negated
        position[0] -= normal[0] * min[2];
        position[1] -= normal[1] * min[2];
        position[2] -= normal[2] * min[2];

        if ( !isPhysics )
        {
            SetEntProp( index, Prop_Data, "m_nSolidType", 6 );
            SetEntProp( index, Prop_Send, "m_nSolidType", 6 );
        }
        DispatchKeyValueVector( index, "Origin", position );
        DispatchKeyValueVector( index, "Angles", ang_ent );
        DispatchSpawn( index );
        
        if ( !isPhysics )
        {
            // we need to make a prop_dynamic entity collide
            // don't know why but the following code work
            AcceptEntityInput( index, "DisableCollision" );
            AcceptEntityInput( index, "EnableCollision" );
        }
    }

    return Plugin_Handled;
}

//---------------------------------------------------------
// rotate the aimed entity
// will recognize a minigun and rotate it properly
//---------------------------------------------------------
public Action:RotateEntity( client, args )
{
    if ( !IsAccessGranted( client ) )
    {
        return Plugin_Handled;
    }
    
    new player = GetPlayerIndex( client );
    
    if ( player == 0 )
    {
        ReplyToCommand( player, "[Left FORT Dead] Cannot spawn entity over rcon/server console" );
        return Plugin_Handled;
    }

    new index = GetClientAimedLocationData( client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR );
    if ( index <= 0 )
    {
        ReplyToCommand( player, "[Left FORT Dead] Nothing picked to rotate" );
        return Plugin_Handled;
    }
    
    new String:param[128];

    new Float:degree;
    if ( args > 0 )
    {
        GetCmdArg( 1, param, sizeof(param) );
        degree = StringToFloat( param );
    }

    GetEdictClassname( index, param, 128 );
    if ( strcmp( param, "prop_minigun" ) == 0 )
    {
        RotateMinigun( player, index, degree );
        return Plugin_Handled;
    }
    
    decl Float:angles[3];
    GetEntPropVector( index, Prop_Data, "m_angRotation", angles );
    RotateYaw( angles, degree );
    
    DispatchKeyValueVector( index, "Angles", angles );

    return Plugin_Handled;
}

//---------------------------------------------------------
// remove the entity you aim at
// anything but player can be removed by this function
//---------------------------------------------------------
public Action:RemoveEntity( client, args )
{
    if ( !IsAccessGranted( client ) )
    {
        return Plugin_Handled;
    }

    new player = GetPlayerIndex( client );
    
    if ( player == 0 )
    {
        ReplyToCommand( player, "[Left FORT Dead] Cannot spawn entity over rcon/server console" );
        return Plugin_Handled;
    }
    
    new index = -1;
    if ( args > 0 )
    {
        new String:param[128];
        GetCmdArg( 1, param, sizeof(param) );
        index = StringToInt( param );
    }
    else
    {
        index = GetClientAimedLocationData( client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR );
    }
    
    if ( index > MaxClients )
    {
        RemoveEdict( index );

        ReplyToCommand( player, "[Left FORT Dead] Entity (index %i) removed", index );
    }
    else if ( index > 0 )
    {
        ReplyToCommand( player, "[Left FORT Dead] Cannot remove player (index %i)", index );
    }
    else
    {
        ReplyToCommand( player, "[Left FORT Dead] Nothing picked to remove" );
    }

    return Plugin_Handled;
}




////////////////////////////////////////////////////////////////////////////////
//
// interior functions
//
////////////////////////////////////////////////////////////////////////////////

//---------------------------------------------------------
// spawn a given entity type and assign it a model
//---------------------------------------------------------
CreateEntity( client, const String:entity_name[], const String:item_name[], const String:model[] = "" )
{
    new player = GetPlayerIndex( client );
    
    if ( player == 0 )
    {
        ReplyToCommand( player, "[Left FORT Dead] Cannot spawn entity over rcon/server console" );
        return -1;
    }

    new index = CreateEntityByName( entity_name );
    if ( index == -1 )
    {
        ReplyToCommand( player, "[Left FORT Dead] Failed to create %s !", item_name );
        return -1;
    }

    if ( strlen( model ) != 0 )
    {
        if ( !IsModelPrecached( model ) )
        {
            PrecacheModel( model );
        }
        SetEntityModel( index, model );
    }

    ReplyToCommand( player, "[Left FORT Dead] Successfully create %s (index %i)", item_name, index );

    return index;
}

//---------------------------------------------------------
// do a specific rotation on the given angles
//---------------------------------------------------------
RotateYaw( Float:angles[3], Float:degree )
{
    decl Float:direction[3], Float:normal[3];
    GetAngleVectors( angles, direction, NULL_VECTOR, normal );
    
    new Float:sin = Sine( degree * 0.01745328 );     // Pi/180
    new Float:cos = Cosine( degree * 0.01745328 );
    new Float:a = normal[0] * sin;
    new Float:b = normal[1] * sin;
    new Float:c = normal[2] * sin;
    new Float:x = direction[2] * b + direction[0] * cos - direction[1] * c;
    new Float:y = direction[0] * c + direction[1] * cos - direction[2] * a;
    new Float:z = direction[1] * a + direction[2] * cos - direction[0] * b;
    direction[0] = x;
    direction[1] = y;
    direction[2] = z;
    
    GetVectorAngles( direction, angles );

    decl Float:up[3];
    GetVectorVectors( direction, NULL_VECTOR, up );

    new Float:roll = GetAngleBetweenVectors( up, normal, direction );
    angles[2] += roll;
}

RotatePitch( Float:angles[3], Float:degree )
{
}

RotateRoll( Float:angles[3], Float:degree )
{
    angles[2] += degree;
}

//---------------------------------------------------------
// specail method to rotate a minigun
// to make sure it still function properly after rotation
//---------------------------------------------------------
RotateMinigun( client, index, Float:degree )
{
    decl Float:origin[3], Float:angles[3];
    GetEntPropVector( index, Prop_Data, "m_vecOrigin", origin );
    GetEntPropVector( index, Prop_Data, "m_angRotation", angles );

    angles[1] += degree;

    // respawn a new one
    new newindex = CreateEntityByName( "prop_minigun" );
    if ( newindex == -1 )
    {
        ReplyToCommand( client, "[Left FORT Dead] Failed to rotate the minigun!" );
        return;
    }

    // delete current minigun
    RemoveEdict( index );
        
    if ( !IsModelPrecached( MODEL_MINIGUN ) )
    {
        PrecacheModel( MODEL_MINIGUN );
    }
    SetEntityModel( newindex, MODEL_MINIGUN );
    DispatchKeyValueFloat( newindex, "MaxPitch",  40.00 );
    DispatchKeyValueFloat( newindex, "MinPitch", -30.00 );
    DispatchKeyValueFloat( newindex, "MaxYaw",    90.00 );
    DispatchKeyValueVector( newindex, "Angles", angles );
    DispatchKeyValueVector( newindex, "Origin", origin );
    
    DispatchSpawn( newindex );
}

//---------------------------------------------------------
// return 0 if it is a server
//---------------------------------------------------------
GetPlayerIndex( client )
{
    if ( client == 0 && !IsDedicatedServer() )
    {
        return 1;
    }
    
    return client;
}

//---------------------------------------------------------
// check if this MOD can be used by specific client
//---------------------------------------------------------
bool:IsAccessGranted( client )
{
    new bool:granted = true;

    // client = 0 means server, server always got access
    if ( client != 0 && GetConVarInt( g_cvar_adminonly ) > 0 )
    {
        if ( !GetAdminFlag( GetUserAdmin( client ), Admin_Generic, Access_Effective ) )
        {
            ReplyToCommand( client, "[Left FORT Dead] Server set only admin can use this command" );
            granted = false;
        }
    }
    
    if ( granted )
    {
        if ( GetConVarInt( g_cvar_enabled ) <= 0 )
        {
            ReplyToCommand( client, "[Left FORT Dead] MOD disabled on server side" );
            granted = false;
        }
    }
    
    return granted;
}

//---------------------------------------------------------
// the filter function for TR_TraceRayFilterEx
//---------------------------------------------------------
public bool:TraceEntityFilterPlayers( entity, contentsMask, any:data )
{
    return entity > MaxClients && entity != data;
}

//---------------------------------------------------------
// get position, angles and normal of aimed location if the parameters are not NULL_VECTOR
// return the index of entity you aimed
//---------------------------------------------------------
GetClientAimedLocationData( client, Float:position[3], Float:angles[3], Float:normal[3] )
{
    new index = -1;
    
    new player = GetPlayerIndex( client );

    decl Float:_origin[3], Float:_angles[3];
    GetClientEyePosition( player, _origin );
    GetClientEyeAngles( player, _angles );

    new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers );
    if( !TR_DidHit( trace ) )
    { 
        ReplyToCommand( player, "[Left FORT Dead] Failed to pick the aimed location" );
        index = -1;
    }
    else
    {
        TR_GetEndPosition( position, trace );
        TR_GetPlaneNormal( trace, normal );
        angles[0] = _angles[0];
        angles[1] = _angles[1];
        angles[2] = _angles[2];

        index = TR_GetEntityIndex( trace );
    }
    CloseHandle( trace );
    
    return index;
}

//---------------------------------------------------------
// get position just in front of you
// and the angles you are facing in horizontal
//---------------------------------------------------------
GetClientFrontLocationData( client, Float:position[3], Float:angles[3], Float:distance = 50.0 )
{
    new player = GetPlayerIndex( client );

    decl Float:_origin[3], Float:_angles[3];
    GetClientAbsOrigin( player, _origin );
    GetClientEyeAngles( player, _angles );

    decl Float:direction[3];
    GetAngleVectors( _angles, direction, NULL_VECTOR, NULL_VECTOR );
    
    position[0] = _origin[0] + direction[0] * distance;
    position[1] = _origin[1] + direction[1] * distance;
    position[2] = _origin[2];
    
    angles[0] = 0.0;
    angles[1] = _angles[1];
    angles[2] = 0.0;
}

//---------------------------------------------------------
// calculate the angle between 2 vectors
// the direction will be used to determine the sign of angle (right hand rule)
// all of the 3 vectors have to be normalized
//---------------------------------------------------------
Float:GetAngleBetweenVectors( const Float:vector1[3], const Float:vector2[3], const Float:direction[3] )
{
    decl Float:vector1_n[3], Float:vector2_n[3], Float:direction_n[3], Float:cross[3];
    NormalizeVector( direction, direction_n );
    NormalizeVector( vector1, vector1_n );
    NormalizeVector( vector2, vector2_n );
    new Float:degree = ArcCosine( GetVectorDotProduct( vector1_n, vector2_n ) ) * 57.29577951;   // 180/Pi
    GetVectorCrossProduct( vector1_n, vector2_n, cross );
    
    if ( GetVectorDotProduct( cross, direction_n ) < 0.0 )
    {
        degree *= -1.0;
    }

    return degree;
}