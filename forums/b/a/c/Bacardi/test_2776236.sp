


// If this error appear:
// Exception reported: Entity Outputs are disabled
// - Try enable below macro variable to 1, to use SDKHook StartTouchPost instead (Not sure does this help)
#define TRIGGER_USE_SDKHOOK_TOUCH 1

// Change game_end delay - default value, when save map trigger, from below macro variable
#define GAME_END_DELAY_DEFAULT 0.0 // 10.0 seconds

// Default Model path to get hitbox size for trigger entity
#define MODEL_PATH_DEFAULT "models/Gibs/wood_gib01a.mdl" // HL2:DM
int modelindex = 0;	// This is for check, is model precached


// Default sprite when save new maptrigger
#define SPRITE_PATH_DEFAULT "sprites/custom/cautionsign_oriented.vmt"

// Default sprite origin offset when save new maptrigger
float sprite_offset[] = {0.0, 0.0, 36.0};

// Change this, do you want laserboxes to show forever by default -> when save new trigger
#define SAVE_SHOWLASERSFOREVER_DEFAULT 1

// Enable debug messages (unfinish)
#define DEBUG_ENABLED 0







#if TRIGGER_USE_SDKHOOK_TOUCH
	#include <sdkhooks>
#endif

#include <regex>
#include <sdktools>



// Global KeyValues handle, where we save/load/import/export and handle all data
KeyValues kvMapTriggers;

// Global variable to store file path
char kvMapTriggersFile[PLATFORM_MAX_PATH];




public void OnPluginStart()
{
	RegAdminCmd("sm_pointtrigger_show", showtriggers, ADMFLAG_CHANGEMAP, "Show plugin map triggers");
	RegAdminCmd("sm_pointtrigger", pointtrigger, ADMFLAG_CHANGEMAP, "Show plugin map triggers");
}


public void OnConfigsExecuted()
{
	if(kvMapTriggers != null)
		delete kvMapTriggers;

	kvMapTriggers = new KeyValues("triggers");

	BuildPath(Path_SM, kvMapTriggersFile, sizeof(kvMapTriggersFile), "configs/maptriggers", kvMapTriggersFile);

	if(!DirExists(kvMapTriggersFile))
	{
		#if DEBUG_ENABLED
			LogAction(-1, -1, "DEBUG: Dir '%s' does not exist, plugin try to create one", kvMapTriggersFile);
		#endif

		// o=rwx,g=rwx,u=rwx
		int mode = FPERM_O_READ|FPERM_O_WRITE|FPERM_O_EXEC|FPERM_G_READ|FPERM_G_WRITE|FPERM_G_EXEC|FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC;

		if(!CreateDirectory(kvMapTriggersFile, mode))
		{
			SetFailState("Failed CreateDirectory '%s', mode %i", kvMapTriggersFile, mode)
		}
		else
		{
			#if DEBUG_ENABLED
				LogAction(-1, -1, "DEBUG: Dir '%s' is now created", kvMapTriggersFile);
			#endif
		}
	}

	GetCurrentMap(kvMapTriggersFile, sizeof(kvMapTriggersFile));
	BuildPath(Path_SM, kvMapTriggersFile, sizeof(kvMapTriggersFile), "configs/maptriggers/%s.txt", kvMapTriggersFile);

	if(!FileExists(kvMapTriggersFile))
	{
		LogAction(-1, -1, "MapTriggers: map config file not exist '%s'", kvMapTriggersFile);
		return;
	}

	if(!kvMapTriggers.ImportFromFile(kvMapTriggersFile))
	{
		SetFailState("MapTriggers: Failed to import KeyValues file '%s'", kvMapTriggersFile);
	}

	#if DEBUG_ENABLED
		LogAction(-1, -1, "DEBUG: Maptriggers file '%s' loaded", kvMapTriggersFile);
	#endif

	modelindex = PrecacheModel(MODEL_PATH_DEFAULT);

	CreateTriggers();
}

/*
public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if(!client || !IsClientInGame(client) || !StrEqual(command, "say_team"))
		return;

	if(!StrEqual(sArgs, "save", true) && !StrEqual(sArgs, "showtriggers", true))
		return;

	if(!CheckCommandAccess(client, "sm_say_team_triggers", ADMFLAG_CHANGEMAP))
	{
		PrintToChat(client, "[SM] You have no access to this chat command");
		return;
	}
}
*/

public Action showtriggers(int client, int args)
{

	kvMapTriggers.Rewind();

	if(!kvMapTriggers.GotoFirstSubKey())
	{
		PrintToChat(client, "[SM] No maptriggers found.");
		return Plugin_Handled;
	}

	char sectioname[PLATFORM_MAX_PATH];

	float origin[3], angles[3], m_vecMins[3], m_vecMaxs[3];
	float seconds = 1.0;

	do
	{
		sectioname[0] = '\0';
		origin = 	view_as<float>({0.0,0.0,0.0});
		angles = 	view_as<float>({0.0,0.0,0.0});
		m_vecMins =	view_as<float>({0.0,0.0,0.0});
		m_vecMaxs =	view_as<float>({0.0,0.0,0.0});

		if(!kvMapTriggers.GetSectionName(sectioname, sizeof(sectioname)))
			continue;

		if(!stringtovector(sectioname, origin))
			continue;

		if(kvMapTriggers.JumpToKey("trigger_once"))
		{
			//kvMapTriggers.GetVector("origin", origin);
			kvMapTriggers.GetVector("angles", angles);
			kvMapTriggers.GetVector("m_vecMins", m_vecMins);
			kvMapTriggers.GetVector("m_vecMaxs", m_vecMaxs);
			kvMapTriggers.GoBack();

			// Do orange box
			CreateBox(origin, angles, m_vecMins, m_vecMaxs, {255,128,0,255}, seconds);
			seconds += 0.1;
		}
	}
	while(kvMapTriggers.GotoNextKey())

	PrintToChat(client, "[SM] Drawing maptriggers laser boxes...");

	return Plugin_Handled;
}


public Action pointtrigger(int client, int args)
{
	// Get client position and YAW-rotation angle

	float origin[3], angles[3];
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, angles);
	angles[0] = 0.0;
	angles[2] = 0.0;


	char key[PLATFORM_MAX_PATH];
	Format(key, sizeof(key), "%f %f %f",
								origin[0],
								origin[1],
								origin[2]);

	kvMapTriggers.Rewind();
	kvMapTriggers.JumpToKey(key, true);

	char date[256];
	FormatTime(date, sizeof(date), "%Y.%m.%d %T");

	kvMapTriggers.SetString("date", date);

	// Get client collision box dimension
	// When player stand it is [{-16.0, -16.0, 0.0}, {16.0, 16.0, 72.0}]

	float m_vecMins[3], m_vecMaxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecMins", m_vecMins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", m_vecMaxs);

	kvMapTriggers.JumpToKey("trigger_once", true);

	kvMapTriggers.SetVector("angles", angles);
	kvMapTriggers.SetVector("m_vecMins", m_vecMins);
	kvMapTriggers.SetVector("m_vecMaxs", m_vecMaxs);
	kvMapTriggers.SetNum("showlasersforever", SAVE_SHOWLASERSFOREVER_DEFAULT);

	int color[4] = {255,0,0,255};

	SetColor_4(kvMapTriggers, "lasersforevercolor", color, sizeof(color));

	kvMapTriggers.SetString("playsound_activator", "buttons/button3.wav");
	kvMapTriggers.SetString("playsound_to_all", "ambient/voices/f_scream1.wav");
	kvMapTriggers.SetString("emitsound_to_all", "combined/trainyard/trainyard_ba_goodluck01_cc.wav");

	kvMapTriggers.GoBack();


	kvMapTriggers.JumpToKey("env_sprite_oriented", true);
	kvMapTriggers.SetString("model", SPRITE_PATH_DEFAULT);
	kvMapTriggers.SetNum("rendermode", 2);
	kvMapTriggers.SetFloat("scale", 0.128);
	kvMapTriggers.SetVector("angles", angles);

	float sprite_origin[3];
	AddVectors(sprite_offset, origin, sprite_origin);

	kvMapTriggers.SetVector("origin", sprite_origin);
	kvMapTriggers.SetString("rendercolor", "255 255 255");
	kvMapTriggers.SetNum("renderamt", 255);
	kvMapTriggers.GoBack();



	kvMapTriggers.JumpToKey("game_end", true);
	kvMapTriggers.SetFloat("delay", GAME_END_DELAY_DEFAULT);
	kvMapTriggers.GoBack();

	kvMapTriggers.JumpToKey("servercommands", true);
	kvMapTriggers.SetString("0", "say Hello World");
	kvMapTriggers.SetString("1", "say You touch trigger");
	kvMapTriggers.SetString("2", "sm_gravity #activator 0.1; say This player can now moonwalk!");

	kvMapTriggers.Rewind();

	if(!kvMapTriggers.ExportToFile(kvMapTriggersFile))
	{
		LogError("KeyValues error: ExportToFile failed '%s'", kvMapTriggersFile);
		PrintToChat(client, "[SM] Failed to expport KeyValues into file!");
		return Plugin_Handled;
	}

	PrintToChat(client, "[SM] New maptrigger saved '%s'", date);

	if(!stringtovector(key, origin))
		return Plugin_Handled;

	// Do green box
	CreateBox(origin, angles, m_vecMins, m_vecMaxs, {0,255,0,255}, 0.0);

	return Plugin_Handled;
}


void CreateTriggers()
{
	kvMapTriggers.Rewind();

	if(!kvMapTriggers.GotoFirstSubKey())
		return;

	char sectioname[PLATFORM_MAX_PATH];
	//char model[PLATFORM_MAX_PATH];
	char buffer[PLATFORM_MAX_PATH];

	float origin[3], angles[3], m_vecMins[3], m_vecMaxs[3];
	int entity;

	int rendermode = 2; // 0 = Normal, 1 = Color, 2 = Texture, 3 = Glow, 4 = Solid, 5, 6, 7, 8 = Don't render
	float scale = 1.0;
	char color[] = "255 255 255";
	int renderamt = 255;

	do
	{
		sectioname[0] = '\0';

		origin = 	view_as<float>({0.0,0.0,0.0});
		angles = 	view_as<float>({0.0,0.0,0.0});
		m_vecMins =	view_as<float>({0.0,0.0,0.0});
		m_vecMaxs =	view_as<float>({0.0,0.0,0.0});
		entity = -1;

		buffer[0] = '\0';
		color[0] = '\0';

		rendermode = 2;
		scale = 1.0;
		renderamt = 255;

		if(!kvMapTriggers.GetSectionName(sectioname, sizeof(sectioname)))
			continue;

		if(!stringtovector(sectioname, origin))
			continue;

		if(kvMapTriggers.JumpToKey("trigger_once"))
		{
			kvMapTriggers.GetVector("angles", angles);
			kvMapTriggers.GetVector("m_vecMins", m_vecMins);
			kvMapTriggers.GetVector("m_vecMaxs", m_vecMaxs);

			kvMapTriggers.GetString("playsound_activator", buffer, sizeof(buffer), "null");

			if(!StrEqual(buffer, "null", false) && strlen(buffer) > 5)
			{
				//PrintToServer("playsound_activator %s", buffer);
				PrecacheSound(buffer);
				Format(buffer, sizeof(buffer), "sound/%s", buffer);
				AddFileToDownloadsTable(buffer);
			}


			kvMapTriggers.GetString("playsound_to_all", buffer, sizeof(buffer), "null");

			if(!StrEqual(buffer, "null", false) && strlen(buffer) > 5)
			{
				//PrintToServer("playsound_to_all %s", buffer);
				PrecacheSound(buffer);
				Format(buffer, sizeof(buffer), "sound/%s", buffer);
				AddFileToDownloadsTable(buffer);
			}

			kvMapTriggers.GetString("emitsound_to_all", buffer, sizeof(buffer), "null");

			if(!StrEqual(buffer, "null", false) && strlen(buffer) > 5)
			{
				//PrintToServer("emitsound_to_all %s", buffer);
				PrecacheSound(buffer);
				Format(buffer, sizeof(buffer), "sound/%s", buffer);
				AddFileToDownloadsTable(buffer);
			}

			kvMapTriggers.GoBack();

			entity = CreateEntityByName("trigger_once");

			if(entity != -1)
			{

				if(modelindex)
					SetEntityModel(entity, MODEL_PATH_DEFAULT);

				DispatchKeyValue(entity, "spawnflags", "1");
				DispatchKeyValue(entity, "StartDisabled", "0");
				TeleportEntity(entity, origin, angles, NULL_VECTOR);
				DispatchSpawn(entity);

				SetEntPropVector(entity, Prop_Data, "m_vecMins", m_vecMins);
				SetEntPropVector(entity, Prop_Data, "m_vecMaxs", m_vecMaxs);
				SetEntProp(entity, Prop_Data, "m_nSolidType", 2); // SOLID_BBOX //  [ANY] Trigger Multiple Commands (1.5)

				#if TRIGGER_USE_SDKHOOK_TOUCH
					SDKHook(entity, SDKHook_StartTouchPost, StartTouchPost);
				#else
					HookSingleEntityOutput(entity, "OnStartTouch", OnStartTouch);
				#endif

			}
		}

		if(kvMapTriggers.JumpToKey("env_sprite_oriented"))
		{
			kvMapTriggers.GetString("model", buffer, sizeof(buffer), SPRITE_PATH_DEFAULT);
			PrecacheGeneric(buffer);

			Format(buffer, sizeof(buffer), "materials/%s", buffer);
			AddFileToDownloadsTable(buffer);

			KeyValues basetexture = new KeyValues("sprite");

			if(basetexture.ImportFromFile(buffer))
			{
				basetexture.Rewind();

				basetexture.GetString("$basetexture", buffer, sizeof(buffer));

				Format(buffer, sizeof(buffer), "materials/%s.vtf", buffer);
				AddFileToDownloadsTable(buffer);
			}
			
			delete basetexture;

			rendermode = kvMapTriggers.GetNum("rendermode", 2);
			scale = kvMapTriggers.GetFloat("scale", 0.128);
			kvMapTriggers.GetVector("angles", angles);
			kvMapTriggers.GetVector("origin", origin);
			kvMapTriggers.GetString("rendercolor", color, sizeof(color), "255 255 255");
			renderamt = kvMapTriggers.GetNum("renderamt", 255);


			entity = CreateEntityByName("env_sprite_oriented");

			if(entity != -1)
			{

				kvMapTriggers.GetString("model", buffer, sizeof(buffer), SPRITE_PATH_DEFAULT);

				DispatchKeyValue(entity, "model", buffer);
				DispatchKeyValue(entity, "spawnflags", "1");
				
				Format(buffer, sizeof(buffer), "%i", rendermode);
				DispatchKeyValue(entity, "rendermode", buffer);
				
				DispatchKeyValueFloat(entity, "scale", scale);
				DispatchKeyValue(entity, "rendercolor", color);

				Format(buffer, sizeof(buffer), "%i", renderamt);
				DispatchKeyValue(entity, "renderamt", buffer);

				TeleportEntity(entity, origin, angles, NULL_VECTOR);
				DispatchSpawn(entity);
			}
			kvMapTriggers.GoBack();
		}
	}
	while(kvMapTriggers.GotoNextKey())
}

public void StartTouchPost(int entity, int other)
{
	//PrintToServer("SDKHook StartTouchPost %i %i", entity, other);
	// Pass only client indexs
	if(other <= 0 || other > MaxClients)
		return;

	OnStartTouch("OnStartTouch", entity, other, 0.0);
}

public void OnStartTouch(const char[] output, int caller, int activator, float delay)
{
	float m_vecAbsOrigin[3];
	GetEntPropVector(caller, Prop_Data, "m_vecAbsOrigin", m_vecAbsOrigin);

	char buffer[PLATFORM_MAX_PATH];
	Format(buffer, sizeof(buffer), "%f %f %f",
							m_vecAbsOrigin[0],
							m_vecAbsOrigin[1],
							m_vecAbsOrigin[2]);

	kvMapTriggers.Rewind();

	if(!kvMapTriggers.JumpToKey(buffer))
	{
		return;
	}

	float game_end_delay = 0.0;

	game_end_delay = kvMapTriggers.GetFloat("game_end/delay", 0.0);

	if(game_end_delay > 0.0)
	{
		int entity = FindEntityByClassname(-1, "game_end");

		if(entity == -1)
		{
			entity = CreateEntityByName("game_end");
		}

		if(entity != -1)
		{
			char input[256];
			Format(input, sizeof(input), "!self,EndGame,,%0.2f,-1", game_end_delay);

			DispatchKeyValue(entity, "OnUser1", input);
			AcceptEntityInput(entity, "FireUser1", entity);

			PrintToChatAll("[SM] Player %N touch map trigger, game will end in %0.0f seconds", activator, game_end_delay);
		}
		else
		{
			LogError("maptriggers error: Couldn't create entity 'game_end' with delay %0.2f", game_end_delay);
		}
	}

	buffer[0] = '\0';
	kvMapTriggers.GetString("trigger_once/playsound_activator", buffer, sizeof(buffer), "null");

	if(!StrEqual(buffer, "null", false) && strlen(buffer) > 5)
	{
		ClientCommand(activator, "play \"%s\"", buffer);
	}
	else
	{
		kvMapTriggers.GetString("trigger_once/playsound_to_all", buffer, sizeof(buffer), "null");

		if(!StrEqual(buffer, "null", false) && strlen(buffer) > 5)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
					ClientCommand(i, "play \"%s\"", buffer);
			}
		}
	}

	kvMapTriggers.GetString("trigger_once/emitsound_to_all", buffer, sizeof(buffer), "null");

	if(!StrEqual(buffer, "null", false) && strlen(buffer) > 5)
	{
		//PrintToServer("trigger_once/emitsound_to_all %s", buffer);
		EmitSoundToAll(buffer, activator, SNDCHAN_STATIC);
	}


	if(!kvMapTriggers.JumpToKey("servercommands") || !kvMapTriggers.GotoFirstSubKey(false))
	{
		return;
	}

	char consoleinput[256];
	float interval = -1.0;
	float delay_next_consoleinput = 0.0;

	do
	{
		consoleinput[0] = '\0';
		interval += 1.0;

		kvMapTriggers.GetString(NULL_STRING, consoleinput, sizeof(consoleinput), "");

		if(StrContains(consoleinput, "delay_next_consoleinput ", false) == 0)
		{
			delay_next_consoleinput = StringToFloat(consoleinput[24]);

			if(delay_next_consoleinput > 0.0)
			{
				// In loop, when we are setting next consoleinput delay, decrease time 1 second, removing this loop time.
				interval -= 1.0;

				// In next coming loop, time is increased by 1 second. Need decrease time by 1 second and use delay time instead.
				interval -= 1.0;

				// If consoleinput delay is set first in row, don't set time below -1.0
				if(interval < -1.0)
					interval = -1.0;

				interval += delay_next_consoleinput;
			}
			continue
		}
		else if(strlen(consoleinput) <= 1)
		{
			continue;
		}

		//PrintToServer("interval %f, delay_next_consoleinput %f", interval, delay_next_consoleinput);

		DataPack pack;
		CreateDataTimer(interval, servercommands, pack);
		pack.WriteCell(GetClientUserId(activator));
		pack.WriteString(consoleinput);
	}
	while(kvMapTriggers.GotoNextKey(false));
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
		return;

	kvMapTriggers.Rewind();

	if(!kvMapTriggers.GotoFirstSubKey())
		return;

	char sectioname[PLATFORM_MAX_PATH];

	float origin[3], angles[3], m_vecMins[3], m_vecMaxs[3];
	float seconds = 1.0;
	bool showlasersforever = false;
	int color[4];

	do
	{
		sectioname[0] = '\0';
		origin = 	view_as<float>({0.0,0.0,0.0});
		angles = 	view_as<float>({0.0,0.0,0.0});
		m_vecMins =	view_as<float>({0.0,0.0,0.0});
		m_vecMaxs =	view_as<float>({0.0,0.0,0.0});
		showlasersforever = false;
		color = {255,0,0,255};

		if(!kvMapTriggers.GetSectionName(sectioname, sizeof(sectioname)))
			continue;

		if(!stringtovector(sectioname, origin))
			continue;

		if(kvMapTriggers.JumpToKey("trigger_once"))
		{
			kvMapTriggers.GetVector("angles", angles);
			kvMapTriggers.GetVector("m_vecMins", m_vecMins);
			kvMapTriggers.GetVector("m_vecMaxs", m_vecMaxs);
			showlasersforever = kvMapTriggers.GetNum("showlasersforever", 0) != 0;

			GetColor_4(kvMapTriggers, "lasersforevercolor", color, sizeof(color));

			kvMapTriggers.GoBack();

			// Dont draw temporary box to client when spawn on server
			if(!showlasersforever)
				continue;

			CreateBoxToUserID(GetClientUserId(client), origin, angles, m_vecMins, m_vecMaxs, color, seconds, showlasersforever);
			seconds += 0.1;
		}
	}
	while(kvMapTriggers.GotoNextKey())
}

void CreateBox(float origin[3], float angles[3], float m_vecMins[3], float m_vecMaxs[3], int color[4] = {255, 0, 0, 255}, float seconds = 1.0, bool showlasersforever = false)
{
	// There is limitation to draw multiple sprites in same frame
	// Creating random timers we can draw more sprites
	DataPack pack;
	CreateDataTimer(seconds, delay, pack);
	WriteVector(pack, origin);
	WriteVector(pack, angles);
	WriteVector(pack, m_vecMins);
	WriteVector(pack, m_vecMaxs);
	pack.WriteCell(color[0]);
	pack.WriteCell(color[1]);
	pack.WriteCell(color[2]);
	pack.WriteCell(color[3]);
	pack.WriteCell(showlasersforever);
	pack.WriteCell(-1);
}

void CreateBoxToUserID(int userid, float origin[3], float angles[3], float m_vecMins[3], float m_vecMaxs[3], int color[4] = {255, 0, 0, 255}, float seconds = 1.0, bool showlasersforever = false)
{
	// There is limitation to draw multiple sprites in same frame
	// Creating random timers we can draw more sprites
	DataPack pack;
	CreateDataTimer(seconds, delay, pack);
	WriteVector(pack, origin);
	WriteVector(pack, angles);
	WriteVector(pack, m_vecMins);
	WriteVector(pack, m_vecMaxs);
	pack.WriteCell(color[0]);
	pack.WriteCell(color[1]);
	pack.WriteCell(color[2]);
	pack.WriteCell(color[3]);
	pack.WriteCell(showlasersforever);
	pack.WriteCell(userid);
}

public Action delay(Handle timer, DataPack pack)
{
	float
	origin[3],
	angles[3],
	m_vecMins[3],
	m_vecMaxs[3];
	int color[4];
	float duration = 25.6;
	int userid = -1;

	pack.Reset();
	ReadVector(pack, origin);
	ReadVector(pack, angles);
	ReadVector(pack, m_vecMins);
	ReadVector(pack, m_vecMaxs);
	color[0] = pack.ReadCell();
	color[1] = pack.ReadCell();
	color[2] = pack.ReadCell();
	color[3] = pack.ReadCell();

	if(pack.ReadCell() != 0)
		duration = 0.0;

	userid = pack.ReadCell();

	if(userid != -1)
	{
		userid = GetClientOfUserId(userid);

		if(!userid || !IsClientInGame(userid))
			return Plugin_Continue;
	}

	int client = userid;



	// looks odd but works

	// Make other points
	float
	pos1[3],
	pos2[3],
	pos3[3],
	pos4[3],
	pos5[3],
	pos6[3];

	pos1 = m_vecMins;
	pos2 = m_vecMins;
	pos3 = m_vecMins
	pos4 = m_vecMaxs;
	pos5 = m_vecMaxs;
	pos6 = m_vecMaxs;

	pos1[0] = m_vecMaxs[0];
	pos2[1] = m_vecMaxs[1];
	pos3[2] = m_vecMaxs[2];
	pos4[0] = m_vecMins[0];
	pos5[1] = m_vecMins[1];
	pos6[2] = m_vecMins[2];


	// Normalize (scale)
	float
	smins,
	smax,
	s1,
	s2,
	s3,
	s4,
	s5,
	s6;


	smins = NormalizeVector(m_vecMins, m_vecMins);
	smax = NormalizeVector(m_vecMaxs, m_vecMaxs);
	s1 = NormalizeVector(pos1, pos1);
	s2 = NormalizeVector(pos2, pos2);
	s3 = NormalizeVector(pos3, pos3);
	s4 = NormalizeVector(pos4, pos4);
	s5 = NormalizeVector(pos5, pos5);
	s6 = NormalizeVector(pos6, pos6);


	// Get angles of points
	float
	angmins[3],
	angmax[3],
	ang1[3],
	ang2[3],
	ang3[3],
	ang4[3],
	ang5[3],
	ang6[3];

	GetVectorAngles(m_vecMins, angmins);
	GetVectorAngles(m_vecMaxs, angmax);
	GetVectorAngles(pos1, ang1);
	GetVectorAngles(pos2, ang2);
	GetVectorAngles(pos3, ang3);
	GetVectorAngles(pos4, ang4);
	GetVectorAngles(pos5, ang5);
	GetVectorAngles(pos6, ang6);

	// Add angles
	AddVectors(angmins, angles, angmins);
	AddVectors(angmax, angles, angmax);
	AddVectors(ang1, angles, ang1);
	AddVectors(ang2, angles, ang2);
	AddVectors(ang3, angles, ang3);
	AddVectors(ang4, angles, ang4);
	AddVectors(ang5, angles, ang5);
	AddVectors(ang6, angles, ang6);

	// Convert back to vectors
	GetAngleVectors(angmins, m_vecMins, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(angmax, m_vecMaxs, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang1, pos1, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang2, pos2, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang3, pos3, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang4, pos4, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang5, pos5, NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang6, pos6, NULL_VECTOR, NULL_VECTOR);

	// scale back
	ScaleVector(m_vecMins, smins);
	ScaleVector(m_vecMaxs, smax);
	ScaleVector(pos1, s1);
	ScaleVector(pos2, s2);
	ScaleVector(pos3, s3);
	ScaleVector(pos4, s4);
	ScaleVector(pos5, s5);
	ScaleVector(pos6, s6);


	// Add position
	AddVectors(m_vecMins, origin, m_vecMins);
	AddVectors(m_vecMaxs, origin, m_vecMaxs);
	AddVectors(pos1, origin, pos1);
	AddVectors(pos2, origin, pos2);
	AddVectors(pos3, origin, pos3);
	AddVectors(pos4, origin, pos4);
	AddVectors(pos5, origin, pos5);
	AddVectors(pos6, origin, pos6);



	int index = PrecacheModel("sprites/laser.vmt");

	TE_SetupBeamPoints(m_vecMins, pos1, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(0.1):TE_SendToClient(client, 0.1);
	TE_SetupBeamPoints(m_vecMins, pos2, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(0.2):TE_SendToClient(client, 0.2);
	TE_SetupBeamPoints(m_vecMins, pos3, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(0.3):TE_SendToClient(client, 0.3);

	TE_SetupBeamPoints(m_vecMaxs, pos4, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(0.4):TE_SendToClient(client, 0.4);
	TE_SetupBeamPoints(m_vecMaxs, pos5, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(0.5):TE_SendToClient(client, 0.5);
	TE_SetupBeamPoints(m_vecMaxs, pos6, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(0.6):TE_SendToClient(client, 0.6);

	TE_SetupBeamPoints(pos2, pos4, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(0.7):TE_SendToClient(client, 0.7);
	TE_SetupBeamPoints(pos1, pos5, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(0.8):TE_SendToClient(client, 0.8);
	TE_SetupBeamPoints(pos1, pos6, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(0.9):TE_SendToClient(client, 0.9);
	TE_SetupBeamPoints(pos2, pos6, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(1.0):TE_SendToClient(client, 1.0);
	TE_SetupBeamPoints(pos4, pos3, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(1.1):TE_SendToClient(client, 1.1);
	TE_SetupBeamPoints(pos5, pos3, index, 0, 0, 0, duration, 2.0, 2.0, 0, 0.0, color, 0);
	client == -1 ? TE_SendToAll(1.2):TE_SendToClient(client, 1.2);

	return Plugin_Continue;
}



public Action servercommands(Handle timer, DataPack pack)
{
	pack.Reset();
	char consoleinput[256];
	char activatoruserid[20];

	Format(activatoruserid, sizeof(activatoruserid), "#%i", pack.ReadCell());

	pack.ReadString(consoleinput, sizeof(consoleinput));

	if(ReplaceString(consoleinput, sizeof(consoleinput), "#activator", activatoruserid, false))
	{
		LogAction(-1, -1, "maptrigger servercommands: We replace '#activator' to #userid in input - %s", consoleinput);
	}

	ServerCommand("%s", consoleinput);

	return Plugin_Continue;
}


bool stringtovector(const char[] string, float vec[3])
{
	char buffer[30];

	// reset float input
	vec[0] = 0.0;
	vec[1] = 0.0;
	vec[2] = 0.0;


	char error[256];
	RegexError errcode = REGEX_ERROR_NONE;

	Regex regex_match_3float = new Regex("(-?\\d+\\.?\\d+) (-?\\d+\\.?\\d+) (-?\\d+\\.?\\d+)",
									_,
									error, sizeof(error), errcode);

	if(errcode != REGEX_ERROR_NONE)
	{
		LogError("Regex errcode: %s", error);

		delete regex_match_3float;
		return false;
	}


	int matches = regex_match_3float.Match(string);

	// -1 = no match
	// 1 = match, a whole string (index 0)
	// 4 = match, with substrings () (index 1 - 3)
	if(matches == 4)
	{
		for(int x = 1; x < matches; x++)
		{
			regex_match_3float.GetSubString(x, buffer, sizeof(buffer));
			vec[x-1] = StringToFloat(buffer);
		}

		delete regex_match_3float;
		return true;
	}

	delete regex_match_3float;
	return false;
}


void WriteVector(DataPack pack, float vec[3])
{
	pack.WriteFloat(vec[0]);
	pack.WriteFloat(vec[1]);
	pack.WriteFloat(vec[2]);
}

void ReadVector(DataPack pack, float vec[3])
{
	vec[0] = pack.ReadFloat();
	vec[1] = pack.ReadFloat();
	vec[2] = pack.ReadFloat();
}

void SetColor_4(KeyValues kv, const char[] key, int[] color, int colorsize)
{
	char value[] = "255 000 000 255 ";
	value[0] = '\0';

	for(int x = 0; x < colorsize; x++)
		Format(value, sizeof(value),"%s%03i ", value, color[x]);

	int index = strlen(value) - 1;

	if(index > 0 && IsCharSpace(value[index]))
		value[index] = '\0';

	kv.SetString(key, value);
}

void GetColor_4(KeyValues kv, const char[] key, int[] color, int colorsize)
{
	char value[] = "111 111 111 255";
	kv.GetString(key, value, sizeof(value), "255 000 000 255");

	int buffersize = 4;
	char[][] buffers = new char[buffersize][4];

	ExplodeString(value, " ", buffers, buffersize, 4);

	for(int x = 0; x < colorsize && x < buffersize; x++)
	{
		color[x] = StringToInt(buffers[x]);
	}
}