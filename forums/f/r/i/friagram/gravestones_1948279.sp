#include <sourcemod>
#include <sdktools>                
#include <tf2_stocks>

#define MASK_CUSTOM (CONTENTS_SOLID|CONTENTS_WINDOW|CONTENTS_GRATE)

#define MAX_DISTANCE_CREATE_PROP 1024.0  // max distance to spawn stones beneath players

#define HUDX1         -1.0
#define HUDY1          0.16

#define PLUGIN_NAME     "[TF2] Revenge Gravestones"
#define PLUGIN_AUTHOR   "Friagram"
#define PLUGIN_VERSION  "1.0.4"
#define PLUGIN_DESCRIP  "Drops Gravestones"
#define PLUGIN_CONTACT  "http://steamcommunity.com/groups/poniponiponi"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIP,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

new Handle:sm_gravestones_enabled = INVALID_HANDLE;
new Handle:sm_gravestones_distance = INVALID_HANDLE;
new Handle:sm_gravestones_time = INVALID_HANDLE;
new bool:g_bEnabled;
new Float:g_fDistance;
new Float:g_fTime;

new Handle:g_hHUD;                    // hud synchronizer
new Handle:g_hHUDtimer;               // hud timer

new g_gravestone[MAXPLAYERS+1];       // entities

#define ANNOTATION_HEIGHT     45.0
#define OFFSET_HEIGHT        -2.0     // distance to sink stones into the ground
static const String:g_sGravestoneMDL[][][] = {            // model path       scale    not animated/activated, so should be fine to remove
                                     {"models/props_manor/gravestone_01.mdl", "0.5"},
                                     {"models/props_manor/gravestone_02.mdl", "0.5"},
                                     {"models/props_manor/gravestone_04.mdl", "0.5"},

                                     {"models/props_manor/gravestone_03.mdl", "0.4"},
                                     {"models/props_manor/gravestone_05.mdl", "0.4"},

                                     {"models/props_manor/gravestone_06.mdl", "0.3"},
                                     {"models/props_manor/gravestone_07.mdl", "0.3"},
                                     {"models/props_manor/gravestone_08.mdl", "0.3"}};

static const String:g_sSmallestViolin[][] = {
                                     {"player/taunt_v01.wav"},
                                     {"player/taunt_v02.wav"},
                                     {"player/taunt_v05.wav"},
                                     {"player/taunt_v06.wav"},
                                     {"player/taunt_v07.wav"},
                                     {"misc/taps_02.wav"},
                                     {"misc/taps_03.wav"}};

#define MAX_EPITAPH_LENGTH 96         // maximum length of death quote string
new Handle:g_hEpitaph = INVALID_HANDLE;
new g_EpitaphSize;

public OnPluginStart()
{
	CreateConVar("revengestone_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);

        HookConVarChange(sm_gravestones_enabled = CreateConVar("sm_gravestones_enabled", "1", "Enabled or disable spawning gravestones", FCVAR_PLUGIN, true, 0.0, true, 1.0), ConVarEnabledChanged);
        HookConVarChange(sm_gravestones_distance = CreateConVar("sm_gravestones_distance", "400", "Max distance gravestones will be visible on hud from", FCVAR_PLUGIN, true, 50.0, false, 8000.0), ConVarDistanceChanged);
        HookConVarChange(sm_gravestones_time = CreateConVar("sm_gravestones_time", "600", "Max time gravestones will exist for", FCVAR_PLUGIN, true, 0.0, false, 14400.0), ConVarTimeChanged);

        RegAdminCmd("sm_gravestones_reload", Command_Reloadconfigs, ADMFLAG_RCON, "Reload the Configuration File");

	HookEvent("player_death", event_player_death, EventHookMode_Post);

	g_hHUD = CreateHudSynchronizer();
	g_hEpitaph = CreateArray(MAX_EPITAPH_LENGTH);
}

public OnMapStart()
{
        for (new i=0; i < sizeof(g_sGravestoneMDL); i++)
	{
	        PrecacheModel( g_sGravestoneMDL[i][0], true );
	}

	for (new i=1; i <= MaxClients; i++)
	{
      	      	g_gravestone[i] = INVALID_ENT_REFERENCE;
	}
	
	for (new i=1; i < sizeof(g_sSmallestViolin); i++)
	{
                PrecacheSound(g_sSmallestViolin[i]);
        }

        GetEpitaphs();
        g_hHUDtimer = INVALID_HANDLE;
}

public OnConfigsExecuted()
{
        g_bEnabled =  GetConVarBool(sm_gravestones_enabled);
        g_fDistance =  GetConVarFloat(sm_gravestones_distance);
        g_fTime =  GetConVarFloat(sm_gravestones_time);
	
        if(g_bEnabled)
	{
                g_hHUDtimer = CreateTimer(1.0, Timer_UpdateHUD, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = (StringToInt(newvalue) == 0 ? false : true);
	
	if(g_bEnabled)
	{
        	if(g_hHUDtimer != INVALID_HANDLE)
                {
                        KillTimer(g_hHUDtimer);
                }
                g_hHUDtimer = CreateTimer(1.0, Timer_UpdateHUD, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
        else
        {
                for (new i=1; i <= MaxClients; i++)
                {
                        if(EntRefToEntIndex(g_gravestone[i]) != INVALID_ENT_REFERENCE)
                        {
                                AcceptEntityInput(EntRefToEntIndex(g_gravestone[i]), "Kill");
                        }
                }
        }
}

public ConVarDistanceChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_fDistance = StringToFloat(newvalue);
}

public ConVarTimeChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_fTime = StringToFloat(newvalue);
}

public OnPluginEnd()
{
        for (new i=1; i <= MaxClients; i++)
        {
                if(EntRefToEntIndex(g_gravestone[i]) != INVALID_ENT_REFERENCE)
                {
                        AcceptEntityInput(EntRefToEntIndex(g_gravestone[i]), "Kill");
                }
        }
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled || GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
	{
                return Plugin_Continue;
        }

        new client = GetClientOfUserId(GetEventInt(event, "userid"));

        if(client && IsClientInGame(client))
        {
                if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_KILLERREVENGE)
                {
                        SpawnProp(client);
                }
        }

        return Plugin_Continue;
}

SpawnProp(client)                                            // somewhat borrowed from fort wars
{
	decl Handle:TraceRay;
	decl Float:StartOrigin[3];

        new Float:Angles[3] = {90.0, 0.0, 0.0};     // down

	GetClientEyePosition(client, StartOrigin);
	TraceRay = TR_TraceRayFilterEx(StartOrigin, Angles, MASK_CUSTOM, RayType_Infinite, TraceRayProp);
	if(TR_DidHit(TraceRay)){
		decl Float:Distance;
		decl Float:EndOrigin[3];
		TR_GetEndPosition(EndOrigin, TraceRay);
		Distance = (GetVectorDistance(StartOrigin, EndOrigin));

		if(Distance<MAX_DISTANCE_CREATE_PROP)
                {
			new ent;
			ent = CreateEntityByName("prop_physics_override");
                	if (ent != -1)
                        {
			        decl Float:normal[3], Float:normalAng[3];                   // offset the prop from the ground plane
			        TR_GetPlaneNormal(TraceRay, normal);
			        EndOrigin[0] += normal[0]*(OFFSET_HEIGHT);
			        EndOrigin[1] += normal[1]*(OFFSET_HEIGHT);
			        EndOrigin[2] += normal[2]*(OFFSET_HEIGHT);

                                GetClientEyeAngles(client, Angles);
                                GetVectorAngles(normal, normalAng);

                                Angles[0]  = normalAng[0] -270;            // horizontal is boring

                                if (normalAng[0] != 270)
                                {
			                Angles[1]  = normalAng[1];         // override the horizontal plane
			        }

                                new idx = GetRandomInt(0, sizeof(g_sGravestoneMDL)-1)

                                decl String:tname[35];
                                decl String:eidx[3];

                                GetClientName(client, String:tname, 32);

				new bitstring = BuildBitString(EndOrigin);
                                if(bitstring > 1)
                                {
                                        new Handle:event = CreateEvent("show_annotation");
                                        if (event != INVALID_HANDLE)
				        {


                                                SetEventFloat(event, "worldPosX", EndOrigin[0] + (normal[0] * ANNOTATION_HEIGHT));
					        SetEventFloat(event, "worldPosY", EndOrigin[1] + (normal[1] * ANNOTATION_HEIGHT));
					        SetEventFloat(event, "worldPosZ", EndOrigin[2] + (normal[2] * ANNOTATION_HEIGHT));
					        SetEventFloat(event, "worldNormalX", normal[0]);
					        SetEventFloat(event, "worldNormalY", normal[1]);
					        SetEventFloat(event, "worldNormalZ", normal[2]);
					        SetEventFloat(event, "lifetime", 10.0);
					        SetEventInt(event, "id", RoundFloat(GetGameTime()));   // lol?
					        SetEventString(event, "text", tname);
					        SetEventInt(event, "visibilityBitfield", bitstring);
                                                SetEventString(event, "play_sound", g_sSmallestViolin[GetRandomInt(0,sizeof(g_sSmallestViolin)-1)]);
                                                FireEvent(event);
                                        }
				}

                                ReplaceString(tname, 32, ";", ":");
                                IntToString(GetRandomInt(0,g_EpitaphSize-1), eidx, 3);
                                StrCat(tname, 35, ";");
                                StrCat(tname, 35, eidx);

                	        DispatchKeyValue(ent, "targetname", tname);                             // name the prop so we can track it, even if a player disconnects.
			        DispatchKeyValue(ent, "solid", "0");
                                DispatchKeyValue(ent, "model", g_sGravestoneMDL[idx][0]);
                	        DispatchKeyValue(ent, "disableshadows", "1");                           // lags and looks bad
                	        DispatchKeyValue(ent, "physdamagescale", "0.0");

                                DispatchKeyValueVector(ent, "origin", EndOrigin);
                                DispatchKeyValueVector(ent, "angles", Angles);

                                DispatchSpawn(ent);

                                SetEntPropFloat(ent, Prop_Send, "m_flModelScale", StringToFloat(g_sGravestoneMDL[idx][1]));
                                SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2); // 2 = debris trigger
                                SetEntProp(ent, Prop_Send, "m_usSolidFlags", 0);   // 0 = ignore solid type, call into entity for raytrace

                                AcceptEntityInput(ent, "DisableMotion");

			        if(EntRefToEntIndex(g_gravestone[client]) != INVALID_ENT_REFERENCE)
			        {
                                        AcceptEntityInput(EntRefToEntIndex(g_gravestone[client]), "Kill");
                                }
                                g_gravestone[client] = EntIndexToEntRef(ent);
                                
                                CreateTimer(g_fTime, Timer_RemoveEnt, g_gravestone[client], TIMER_FLAG_NO_MAPCHANGE);
                        }
		}
	}

	CloseHandle(TraceRay);
}


public Action:Timer_RemoveEnt(Handle:timer, any:ref)
{
        new ent = EntRefToEntIndex(ref);
        if (ent != INVALID_ENT_REFERENCE)
        {
                AcceptEntityInput(ent, "Kill");
        }
}

public bool:TraceRayProp(entityhit, mask) {
        if(entityhit == 0)
        {
                return true;
        }
        return false;
}

public Action:Timer_UpdateHUD(Handle:timer)
{
        if(!g_bEnabled)
        {
                g_hHUDtimer = INVALID_HANDLE;
                return Plugin_Stop;
        }

        decl String:buffer[MAX_EPITAPH_LENGTH+32];
        decl String:segment[2][32];
        decl Float:clientpos[3],Float:proppos[3];

        SetHudTextParams(HUDX1, HUDY1, 1.5, 255, 70, 200, 120);
	for (new i=1; i <= MaxClients; i++)
	{
                if (IsClientInGame(i) && !IsFakeClient(i))
		{
			new ent = GetObject(i);
			if (ent != -1)
			{
                                GetEntPropVector(ent, Prop_Send, "m_vecOrigin", proppos);
                                GetEntPropVector(i, Prop_Send, "m_vecOrigin", clientpos);

                                if(GetVectorDistance(clientpos,proppos) < g_fDistance)
                                {
                                        GetEntPropString(ent, Prop_Data, "m_iName", buffer, 36);
                                        ExplodeString(buffer, ";", segment, 2, 32);                  // name;index
                                        GetArrayString(g_hEpitaph, StringToInt(segment[1]), buffer, MAX_EPITAPH_LENGTH+32);
				        ReplaceString(buffer, MAX_EPITAPH_LENGTH, "*", segment[0]);
                                        ShowSyncHudText(i, g_hHUD, buffer);
				}
			}
		}
	}

	return Plugin_Continue;
}

stock GetObject(client)
{
	new ent = TraceToEntity(client);

	if (ent > 0)
	{
		for (new i=1; i <= MaxClients; i++)
		{
                        if(EntRefToEntIndex(g_gravestone[i]) == ent)
                        {
                                return ent;
                        }
                }                
	}

	return -1;
}

public TraceToEntity(client)
{
        decl Float:vecClientEyePos[3];
        decl Float:vecClientEyeAng[3];

	GetClientEyePosition(client, vecClientEyePos);
	GetClientEyeAngles(client, vecClientEyeAng);

	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, DontHitSelf, client);

	if (TR_DidHit(INVALID_HANDLE))
		return (TR_GetEntityIndex(INVALID_HANDLE));

	return (-1);
}

public bool:DontHitSelf(entity, mask, any:client)
{
	return (client != entity);
}

//////////////////////////////////////////////////////////////////////
/////////////                    Files                   /////////////
//////////////////////////////////////////////////////////////////////

public Action:Command_Reloadconfigs(client, args)
{
        new oldsize = g_EpitaphSize;
        GetEpitaphs();

        if(oldsize > g_EpitaphSize)                          // usually people would append lines/correct mistakes
        {                                                    // here they removed or something, so index errors could occur
                for (new i=1; i <= MaxClients; i++)
                {
                        if(EntRefToEntIndex(g_gravestone[i]) != INVALID_ENT_REFERENCE)
                        {
                                AcceptEntityInput(EntRefToEntIndex(g_gravestone[i]), "Kill");
                        }
                }
        }

        ReplyToCommand(client,"[Gravestones]: Reloaded %i old phrases with %i new", oldsize, g_EpitaphSize);

	return Plugin_Handled;
}

stock GetEpitaphs()
{
	new String:file[256];
	BuildPath(Path_SM, file, 256, "configs/gravestones.txt");
	new Handle:fileh = OpenFile(file, "r");

        ClearArray(g_hEpitaph);
        g_EpitaphSize = 0;

	if(fileh == INVALID_HANDLE)
        {
                PushArrayString(g_hEpitaph, "R.I.P. *");              // provide a dummy entry if no file found
                g_EpitaphSize++;
                LogError("[Gravestones]: Could not read %s", file);

                return;
        }

        decl String:buffer[MAX_EPITAPH_LENGTH];
	while (ReadFileLine(fileh, buffer, MAX_EPITAPH_LENGTH))
	{
		TrimString(buffer);
		ReplaceString(buffer, MAX_EPITAPH_LENGTH, "|", "\n");
                PushArrayString(g_hEpitaph, buffer);
                g_EpitaphSize++;

		if (IsEndOfFile(fileh))
			break;
	}
	if(fileh != INVALID_HANDLE){
		CloseHandle(fileh);
	}
	
	if(g_EpitaphSize == 0)
        {
                PushArrayString(g_hEpitaph, "R.I.P. *");              // provide a dummy entry if no file found
                g_EpitaphSize++;
                LogError("[Gravestones]: The file at %s was empty", file);
        }
}

public BuildBitString(Float:position[3])
{
	new bitstring = 1;
	for(new client=1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			decl Float:EyePos[3];
			GetClientEyePosition(client, EyePos);
			if (GetVectorDistance(position, EyePos) < g_fDistance)
			{
                                bitstring |= RoundFloat(Pow(2.0, float(client)));
			}
		}
	}
	return bitstring;
}