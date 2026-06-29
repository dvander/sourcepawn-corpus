/* sm_bender.sp

Description: Bender Theme model changer/Mod

Currnt Version: 1.02

Changelog:

1.0 - Initial Release
1.01- Repaird Headshot and map end sounds not working all the time and reduced volume of pickup Item
1.02- Repaird Linux Servers not working  and reduced volume of jump sound

- sm_bender <1|0>

- cvar sm_bender_on <1|0>
- cvar explode_on   <1|0>

- This Mod Plugin was made for My Friend and Teacher Gary Lack AKA Small Sumo and his Bender models.


*/

#include <sourcemod>
#include <sdktools>

//#pragma semicolon 1

#define PLUGIN_VERSION "1.02"
#define MAX_FILE_LEN 255


// Plugin definitions
public Plugin:myinfo = 
{
	name = "sm_bender",
	author = "TechKnow",
        version = "1.02",
	description = "Bender Theme model changer/Mod", version = PLUGIN_VERSION,
	url = "http://techknowmodels.19.forumer.com/index.php"
};

new Handle:g_hCredit[MAXPLAYERS + 1];
new Handle:g_CvarBender_on = INVALID_HANDLE;
new Handle:Cvar_ExplodeEnable = INVALID_HANDLE;
new String:g_SAS[MAX_FILE_LEN] = "models/player/small_sumo/bender/ct_sas.mdl";
new String:g_GIGN[MAX_FILE_LEN] = "models/player/small_sumo/bender/ct_gign.mdl";
new String:g_GSG9[MAX_FILE_LEN] = "models/player/small_sumo/bender/ct_gsg9.mdl";
new String:g_URBAN[MAX_FILE_LEN] = "models/player/small_sumo/bender/ct_urban.mdl";
new String:g_LEET[MAX_FILE_LEN] = "models/player/small_sumo/bender/t_leet.mdl";
new String:g_GUERILLA[MAX_FILE_LEN] = "models/player/small_sumo/bender/t_guerilla.mdl";
new String:g_PHOENIX[MAX_FILE_LEN] = "models/player/small_sumo/bender/t_phoenix.mdl";
new String:g_ARCTIC[MAX_FILE_LEN] = "models/player/small_sumo/bender/t_arctic.mdl";
new String:g_JumpSound[MAX_FILE_LEN]= "bender/boing.wav";
new String:g_HeartBeat[MAX_FILE_LEN]= "bender/heartbeat.wav";
new String:g_PickupSound[MAX_FILE_LEN]= "bender/pickup.wav";
new String:g_CantseeSound[MAX_FILE_LEN]= "bender/cantsee.wav";
new String:g_IncomingSound[MAX_FILE_LEN]= "bender/incoming.wav";
new String:g_EmptySound[MAX_FILE_LEN]= "bender/crap.wav";
new String:g_PlantSound[MAX_FILE_LEN]= "bender/plant.wav";
new String:g_DefuseSound[MAX_FILE_LEN]= "bender/defuse.wav";
new String:g_HeadshotSound[MAX_FILE_LEN]= "bender/headshot.wav";
new String:g_join[MAX_FILE_LEN]= "bender/rumble.mp3";
new String:g_End[MAX_FILE_LEN]= "bender/end.mp3";
new orange;
new g_HaloSprite;
new g_ExplosionSprite;
new onoff;
new Handle:hGameConf = INVALID_HANDLE;
new Handle:hSetModel;
new bool:Bender = true;

public OnPluginStart()
{
        PrintToServer("---------------|       TechKnows BenderTron Loading      |--------------");
	CreateConVar("sm_bender_version", PLUGIN_VERSION, "bender Version",         FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        g_CvarBender_on = CreateConVar("sm_bender_on", "1", "Set to 1 to enable Bender models");
	Cvar_ExplodeEnable = CreateConVar("explode_on", "1", "1 explosions on 0 is off", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

        RegAdminCmd("sm_bender", Command_SetBender, ADMFLAG_SLAY);

	// Load the gamedata file
	hGameConf = LoadGameConfigFile("bender.games");
	if (hGameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/bender.games.txt not loadable");
	}

        StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	hSetModel = EndPrepSDKCall();

	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
        HookEvent("player_jump",PlayerJumpEvent);
        HookEvent("item_pickup",PlayerPickupEvent);
        HookEvent("grenade_bounce",IncomingEvent);
        HookEvent("player_blind",BlindEvent);
        HookEvent("weapon_fire_on_empty",EmptyEvent);
        HookEvent("player_falldamage",FallEvent);
        HookEvent("bomb_planted",PlantEvent);
        HookEvent("bomb_defused",DefuseEvent);
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);
        HookEvent("round_end", EndEvent);

        AutoExecConfig();

        PrintToServer("---------------|       TechKnows BenderTron Loaded       |--------------");
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
        UnhookEvent("player_jump",PlayerJumpEvent);
        UnhookEvent("item_pickup",PlayerPickupEvent);
        UnhookEvent("grenade_bounce",IncomingEvent);
        UnhookEvent("player_blind",BlindEvent);
        UnhookEvent("weapon_fire_on_empty",EmptyEvent);
        UnhookEvent("player_falldamage",FallEvent);
        UnhookEvent("bomb_planted",PlantEvent);
        UnhookEvent("bomb_defused",DefuseEvent);
        UnhookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);
        UnhookEvent("round_end", EndEvent);
}

public OnMapStart()
{
        decl String:buffer[MAX_FILE_LEN];
        //open precache file and add everything to download table
	new String:file[256]
	BuildPath(Path_SM, file, 255, "configs/bender.ini")
	new Handle:fileh = OpenFile(file, "r")
	while (ReadFileLine(fileh, buffer, sizeof(buffer)))
	{
		new len = strlen(buffer)
		if (buffer[len-1] == '\n')
   			buffer[--len] = '\0'
   			
		if (FileExists(buffer))
		{
			AddFileToDownloadsTable(buffer)
		}
		
		if (IsEndOfFile(fileh))
			break
	}
        PrecacheModel(g_SAS, true);
        PrecacheModel(g_GIGN, true);
        PrecacheModel(g_GSG9, true);
        PrecacheModel(g_URBAN, true);
        PrecacheModel(g_LEET, true);
        PrecacheModel(g_GUERILLA, true);
        PrecacheModel(g_PHOENIX, true);
        PrecacheModel(g_ARCTIC, true);
        PrecacheSound(g_JumpSound, true);
        PrecacheSound(g_HeartBeat, true);
        PrecacheSound(g_IncomingSound, true);
        PrecacheSound(g_CantseeSound, true); 
        PrecacheSound(g_PickupSound, true); 
        PrecacheSound(g_EmptySound, true);
        PrecacheSound(g_PlantSound, true);
        PrecacheSound(g_DefuseSound, true); 
        PrecacheSound(g_HeadshotSound, true);        
        PrecacheSound(g_join, true);
        PrecacheSound(g_End, true);
	orange=PrecacheModel("materials/sprites/fire2.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_ExplosionSprite = PrecacheModel("sprites/sprite_fire01.vmt");
	PrecacheSound( "ambient/explosions/explode_8.wav", true);
}

public OnClientPutInServer(client)
{
	 if(!IsFakeClient(client))
	 {
                g_hCredit[client] = CreateTimer(180.0, TimerAnnounce, client, TIMER_REPEAT);
                PrintToChat((client),"\x01\x04[BM] This Server is running TechKnows BenderTron Plugin! Models By Small Sumo.");
                decl String:buffer[255];
		Format(buffer, sizeof(buffer), "play %s", (g_join), SNDLEVEL_RAIDSIREN);
	        ClientCommand((client), buffer);
         }
}

public EndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
        new timeleft;
	GetMapTimeLeft(timeleft);
	if (timeleft <= 0)
        {
               for(new i = 1; i <= GetMaxClients(); i++)
               if(IsClientInGame(i) && !IsFakeClient(i))
	       {
                    decl String:buffer[255];
		    Format(buffer, sizeof(buffer), "play %s", (g_End), SNDLEVEL_RAIDSIREN);
	            ClientCommand((i), buffer);
               }
         }
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");

	new victimClient = GetClientOfUserId(victimId);

	new killedTeam = GetClientTeam(victimClient);

	new playersConnected = GetMaxClients();

	new lastManId = 0;

	for (new i = 1; i < playersConnected; i++) {
		if(IsClientInGame(i)){
			if(killedTeam==GetClientTeam(i) && IsPlayerAlive(i)) {
				if( lastManId )
					lastManId = -1;
				else
					lastManId = i;
			}
		}
	}
	if(lastManId > 0) {
		new String:clientname[64];
		GetClientName(lastManId, clientname, sizeof(clientname));
		PrintToChatAll("\x01\x04[BM] %s is the last Bender on his team", clientname);
		if(!IsFakeClient(lastManId))
                {
		        EmitSoundToClient(lastManId, g_HeartBeat, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS);
                }
	}
        if (GetConVarBool(Cvar_ExplodeEnable))
	{
	     new id = GetClientOfUserId(GetEventInt(event,"userid"));
             new bool:headshot;
	     headshot = GetEventBool(event, "headshot");

	     if (IsClientInGame(id) && headshot == true)
	     {
	 	  ExplodePlayer(id);
                  for(new i = 1; i <= GetMaxClients(); i++)
                  if(IsClientInGame(i) && !IsFakeClient(i))
	          {
                       decl String:buffer[255];
		       Format(buffer, sizeof(buffer), "play %s", (g_HeadshotSound), SNDLEVEL_RAIDSIREN);
	               ClientCommand((i), buffer);
                  }
	     }
	     headshot = false;
        }
}

stock ExplodePlayer(id)
{
	decl Float:location[3]
	GetClientAbsOrigin(id, location);
			
	Explode1(location);
	Explode2(location);
}

public Explode1(Float:vec1[3])
{
	new color[4]={188,220,255,200};
	Boom("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vec1, 10.0, 500.0, orange, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, color, 10, 0);
  	TE_SendToAll();
}

public Explode2(Float:vec1[3])
{
	vec1[2] += 10;
	Boom("ambient/explosions/explode_8.wav", vec1);
	TE_SetupExplosion(vec1, g_ExplosionSprite, 10.0, 1, 0, 600, 5000);
	TE_SendToAll();
}

public Boom(const String:sound[],const Float:orig[3])
{
	EmitSoundToAll(sound,SOUND_FROM_WORLD,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,orig,NULL_VECTOR,true,0.0);
}

public OnClientDisconnect(client)
{     
	 CloseHandle(g_hCredit[client]);
         (g_hCredit[client]) = INVALID_HANDLE;
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(client && IsClientInGame(client) && !IsFakeClient(client))
        {
	       PrintToChat(client, "\x01\x04[BM]  This Server is running TechKnows BenderTron Plugin! Models By Small Sumo.");
        }
}

public Action:Command_SetBender(client, args)
{
	if (args < 1)
        {
		ReplyToCommand(client, "\x01\x04[BM] Usage: sm_bender <1/0>");
		return Plugin_Handled;
	}
       
	new String:sb[10];
	GetCmdArg(1, sb, sizeof(sb));
        onoff = StringToInt(sb);
        if(onoff == 1)
        {
                Bender = true;
                DoBender();
	}
        if(onoff == 0)
        {
          // Admin Turnoff Bender model /// REMOVE MODEL/////
         Bender = false;
	 for(new i = 1; i <= GetMaxClients(); i++)
	 {
	       if(IsClientInGame(i))
	       {
                       PrintToChat((i),"\x01\x04[BM] Your Bender model has been removed"); 
                       new team;
                       if (GetClientTeam(i) == 3)
	               {
                        // Make player a random ct model 
                          team = 3;
                          set_random_model((i),team);
                       }
                       else if (GetClientTeam(i) == 2)
                       {
                        // Make player random t model
                          team = 2;
                          set_random_model((i),team);
                       }
	       }
        }
        }
        return Plugin_Continue;
}

public DoBender()
{
	 for(new i = 1; i <= GetMaxClients(); i++)
	 {
	       if(IsClientInGame(i))
	       {
                       PrintToChat((i),"\x01\x04[BM] You have been given a Bender model"); 
                       new team;
                       if (GetClientTeam(i) == 3)
	               {
                        // Make player a random Bender ct model 
                          team = 3;
                          set_random_bender((i),team);
                       }
                       else if (GetClientTeam(i) == 2)
                       {
                        // Make player random Bender t model
                          team = 2;
                          set_random_bender((i),team);
                       }
	       }
        }
}

public PlayerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (strcmp(g_JumpSound, ""))
        {
	        new Float:vec[3];
	        GetClientEyePosition(client, vec);
	        EmitAmbientSound(g_JumpSound, vec, client, SNDLEVEL_NORMAL);
        }
}

public PlayerPickupEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (strcmp(g_PickupSound, ""))
        {
	        new Float:vec[3];
	        GetClientEyePosition(client, vec);
	        EmitAmbientSound(g_PickupSound, vec, client, SNDLEVEL_NORMAL);
        }
}

public BlindEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (strcmp(g_CantseeSound, ""))
        {
	        new Float:vec[3];
	        GetClientEyePosition(client, vec);
	        EmitAmbientSound(g_CantseeSound, vec, client, SNDLEVEL_RAIDSIREN);
        }
}

public IncomingEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (strcmp(g_IncomingSound, ""))
        {
	        new Float:vec[3];
	        GetClientEyePosition(client, vec);
	        EmitAmbientSound(g_IncomingSound, vec, client, SNDLEVEL_RAIDSIREN);
        }
}

public EmptyEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (strcmp(g_EmptySound, ""))
        {
	        new Float:vec[3];
	        GetClientEyePosition(client, vec);
	        EmitAmbientSound(g_EmptySound, vec, client, SNDLEVEL_RAIDSIREN);
        }
}

public FallEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (strcmp(g_EmptySound, ""))
        {
	        new Float:vec[3];
	        GetClientEyePosition(client, vec);
	        EmitAmbientSound(g_EmptySound, vec, client, SNDLEVEL_RAIDSIREN);
        }
}

public PlantEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (strcmp(g_PlantSound, ""))
        {
	        new Float:vec[3];
	        GetClientEyePosition(client, vec);
	        EmitAmbientSound(g_PlantSound, vec, client, SNDLEVEL_RAIDSIREN);
        }
}

public DefuseEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (strcmp(g_DefuseSound, ""))
        {
	        new Float:vec[3];
	        GetClientEyePosition(client, vec);
	        EmitAmbientSound(g_DefuseSound, vec, client, SNDLEVEL_RAIDSIREN);
        }
}



public Action:EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{       
        if (!GetConVarBool(g_CvarBender_on) || (Bender == false))
	{
		return Plugin_Continue;
	}
	// get the client
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
        new team;
        if (GetClientTeam(client) == 3)
	{
                // Make player a random Bender ct model 
                team = 3;
                set_random_bender((client),team);
        }
        else if (GetClientTeam(client) == 2)
        {
                // Make player random Bender t model
                team = 2;
                set_random_bender((client),team);
        }
        return Plugin_Continue;
}

static const String:ctmodels[4][] = {"models/player/ct_urban.mdl","models/player/ct_gsg9.mdl","models/player/ct_sas.mdl","models/player/ct_gign.mdl"}
static const String:tmodels[4][] = {"models/player/t_phoenix.mdl","models/player/t_leet.mdl","models/player/t_arctic.mdl","models/player/t_guerilla.mdl"}


static const String:ctbender[4][] = {"models/player/small_sumo/bender/ct_urban.mdl","models/player/small_sumo/bender/ct_gsg9.mdl","models/player/small_sumo/bender/ct_sas.mdl","models/player/small_sumo/bender/ct_gign.mdl"}
static const String:tbender[4][] = {"models/player/small_sumo/bender/t_phoenix.mdl","models/player/small_sumo/bender/t_leet.mdl","models/player/small_sumo/bender/t_arctic.mdl","models/player/small_sumo/bender/t_guerilla.mdl"}


stock set_random_bender(client,team)
{
	new random=GetRandomInt(0, 3)
	
	if (team==2) //t
	{
		SDKCall(hSetModel,client,tbender[random]);
	}
	else if (team==3) //ct	
	{
		SDKCall(hSetModel,client,ctbender[random]);
	}	
}

stock set_random_model(client,team)
{
	new random=GetRandomInt(0, 3)
	
	if (team==2) //t
	{
		SDKCall(hSetModel,client,tmodels[random]);
	}
	else if (team==3) //ct	
	{
		SDKCall(hSetModel,client,ctmodels[random]);
	}	
}

