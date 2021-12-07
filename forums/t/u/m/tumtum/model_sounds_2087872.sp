#include <sourcemod>
#include <sdktools>

// Version
#define VERSION "1.0"

// Default Handles
new Handle:modelvolume;

// Model Sound Enable
new Handle:model1 = INVALID_HANDLE;
new Handle:model2 = INVALID_HANDLE;
new Handle:model3 = INVALID_HANDLE;
new Handle:model4 = INVALID_HANDLE;
new Handle:model5 = INVALID_HANDLE;
new Handle:model6 = INVALID_HANDLE;

// Model Sound Duration
new Handle:model1snd = INVALID_HANDLE;
new Handle:model2snd = INVALID_HANDLE;
new Handle:model3snd = INVALID_HANDLE;
new Handle:model4snd = INVALID_HANDLE;
new Handle:model5snd = INVALID_HANDLE;
new Handle:model6snd = INVALID_HANDLE;

// Model Sound Path
new Handle:model1sndpath = INVALID_HANDLE;
new Handle:model2sndpath = INVALID_HANDLE;
new Handle:model3sndpath = INVALID_HANDLE;
new Handle:model4sndpath = INVALID_HANDLE;
new Handle:model5sndpath = INVALID_HANDLE;
new Handle:model6sndpath = INVALID_HANDLE;

// Model Custom Path
new Handle:model1path = INVALID_HANDLE;
new Handle:model2path = INVALID_HANDLE;
new Handle:model3path = INVALID_HANDLE;
new Handle:model4path = INVALID_HANDLE;
new Handle:model5path = INVALID_HANDLE;
new Handle:model6path = INVALID_HANDLE;

// Teams
new Handle:modelTsndpath = INVALID_HANDLE;
new Handle:modelCTsndpath = INVALID_HANDLE;

// Team Sound Enable
new Handle:modelT = INVALID_HANDLE;
new Handle:modelCT = INVALID_HANDLE;

// Team Sound Duration
new Handle:modelTsnd = INVALID_HANDLE;
new Handle:modelCTsnd = INVALID_HANDLE;

// Info
public Plugin:myinfo =
{
    name = "Model Sounds",
    author = "TummieTum (TumTum)",
    description = "Custom Model Sounds",
    version = VERSION,
    url = "http://www.Team-Secretforce.com/"
};

public OnPluginStart()
{
	// Model Sound Enable or Disable
	model1 = CreateConVar("modelsnd_m1", "0", "Enable Model 1 Sounds (Default Disabled)");
	model2 = CreateConVar("modelsnd_m2", "0", "Enable Model 2 Sounds (Default Disabled)");
	model3 = CreateConVar("modelsnd_m3", "0", "Enable Model 3 Sounds (Default Disabled)");
	model4 = CreateConVar("modelsnd_m4", "0", "Enable Model 4 Sounds (Default Disabled)");
	model5 = CreateConVar("modelsnd_m5", "0", "Enable Model 5 Sounds (Default Disabled)");
	model6 = CreateConVar("modelsnd_m6", "0", "Enable Model 6 Sounds (Default Disabled)");
	
	// Team Sound Enable or Disable
	modelT = CreateConVar("modelsnd_t", "0", "Enable Team Sound for T");
	modelCT = CreateConVar("modelsnd_ct", "0", "Enable Team Sound for CT");
	
	// Duration Model Sound
	model1snd = CreateConVar("modelsnd_m1_duration", "50.0", "Sound/Timer Duration Model 1");
	model2snd = CreateConVar("modelsnd_m2_duration", "50.0", "Sound/Timer Duration Model 2");
	model3snd = CreateConVar("modelsnd_m3_duration", "50.0", "Sound/Timer Duration Model 3");
	model4snd = CreateConVar("modelsnd_m4_duration", "50.0", "Sound/Timer Duration Model 4");
	model5snd = CreateConVar("modelsnd_m5_duration", "50.0", "Sound/Timer Duration Model 5");
	model6snd = CreateConVar("modelsnd_m6_duration", "50.0", "Sound/Timer Duration Model 6");
	
	// Team Duration
	modelTsnd = CreateConVar("modelsnd_T_duration", "50.0", "Sound/Timer Duration T");
	modelCTsnd = CreateConVar("modelsnd_CT_duration", "50.0", "Sound/Timer Duration CT");
	
	// Model Paths
	model1path = CreateConVar("modelsnd_m1_path", "models/player/xxxx/model.mdl", "Model 1 Path");
	model2path = CreateConVar("modelsnd_m2_path", "models/player/xxxx/model.mdl", "Model 2 Path");
	model3path = CreateConVar("modelsnd_m3_path", "models/player/xxxx/model.mdl", "Model 3 Path");
	model4path = CreateConVar("modelsnd_m4_path", "models/player/xxxx/model.mdl", "Model 4 Path");
	model5path = CreateConVar("modelsnd_m5_path", "models/player/xxxx/model.mdl", "Model 5 Path");
	model6path = CreateConVar("modelsnd_m6_path", "models/player/xxxx/model.mdl", "Model 6 Path");
	
	// Sound Paths
	model1sndpath = CreateConVar("modelsnd_m1_sndpath", "music/xxx/sound.mp3", "Model 1 Sound Path (without sound/)");
	model2sndpath = CreateConVar("modelsnd_m2_sndpath", "music/xxx/sound.mp3", "Model 2 Sound Path (without sound/)");
	model3sndpath = CreateConVar("modelsnd_m3_sndpath", "music/xxx/sound.mp3", "Model 3 Sound Path (without sound/)");
	model4sndpath = CreateConVar("modelsnd_m4_sndpath", "music/xxx/sound.mp3", "Model 4 Sound Path (without sound/)");
	model5sndpath = CreateConVar("modelsnd_m5_sndpath", "music/xxx/sound.mp3", "Model 5 Sound Path (without sound/)");
	model6sndpath = CreateConVar("modelsnd_m6_sndpath", "music/xxx/sound.mp3", "Model 6 Sound Path (without sound/)");
	
	// Team Sounds
	modelTsndpath = CreateConVar("modelsnd_T_sndpath", "music/xxx/sound.mp3", "T Sound Path (without sound/)");
	modelCTsndpath = CreateConVar("modelsnd_CT_sndpath", "music/xxx/sound.mp3", "CT Sound Path (without sound/)");
	
	// Volume
	modelvolume = CreateConVar("modelsnd_volume", "1.0", "(1.0 = Max volume | 0.0001 = Not audible)", FCVAR_PLUGIN);
	
	// Version
	CreateConVar("sm_modelsounds_version", VERSION, "Plugin Info", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	// Exec Config
	AutoExecConfig(true, "Model_Sounds_Config");
}

public OnMapStart()
{
	// Download and Cache Sounds
	decl String:sSndPath[PLATFORM_MAX_PATH];
	
	if (GetConVarInt(model1) == 1) {
	GetConVarString(model1sndpath, sSndPath, sizeof(sSndPath));
	PrecacheSound(sSndPath);
	Format(sSndPath, sizeof(sSndPath), "sound/%s", sSndPath);
	AddFileToDownloadsTable(sSndPath);
	}
	
	if (GetConVarInt(model2) == 1) {
	GetConVarString(model2sndpath, sSndPath, sizeof(sSndPath));
	PrecacheSound(sSndPath);
	Format(sSndPath, sizeof(sSndPath), "sound/%s", sSndPath);
	AddFileToDownloadsTable(sSndPath);
	}
	
	if (GetConVarInt(model3) == 1) {
	GetConVarString(model3sndpath, sSndPath, sizeof(sSndPath));
	PrecacheSound(sSndPath);
	Format(sSndPath, sizeof(sSndPath), "sound/%s", sSndPath);
	AddFileToDownloadsTable(sSndPath);
	}
	
	if (GetConVarInt(model4) == 1) {
	GetConVarString(model4sndpath, sSndPath, sizeof(sSndPath));
	PrecacheSound(sSndPath);
	Format(sSndPath, sizeof(sSndPath), "sound/%s", sSndPath);
	AddFileToDownloadsTable(sSndPath);
	}
	
	if (GetConVarInt(model5) == 1) {
	GetConVarString(model5sndpath, sSndPath, sizeof(sSndPath));
	PrecacheSound(sSndPath);
	Format(sSndPath, sizeof(sSndPath), "sound/%s", sSndPath);
	AddFileToDownloadsTable(sSndPath);
	}
	
	if (GetConVarInt(model6) == 1) {
	GetConVarString(model6sndpath, sSndPath, sizeof(sSndPath));
	PrecacheSound(sSndPath);
	Format(sSndPath, sizeof(sSndPath), "sound/%s", sSndPath);
	AddFileToDownloadsTable(sSndPath);
	}
	
	// Download and Cache Sound Teams
	if (GetConVarInt(modelT) == 1) {
	GetConVarString(modelTsndpath, sSndPath, sizeof(sSndPath));
	PrecacheSound(sSndPath);
	Format(sSndPath, sizeof(sSndPath), "sound/%s", sSndPath);
	AddFileToDownloadsTable(sSndPath);
	}
	
	if (GetConVarInt(modelCT) == 1) {
	GetConVarString(modelCTsndpath, sSndPath, sizeof(sSndPath));
	PrecacheSound(sSndPath);
	Format(sSndPath, sizeof(sSndPath), "sound/%s", sSndPath);
	AddFileToDownloadsTable(sSndPath);
	}
	
	// Create Timers including disable or enable options
	if (GetConVarInt(model1) == 1) {
	CreateTimer(GetConVarFloat(model1snd), Model1, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (GetConVarInt(model2) == 1) {
	CreateTimer(GetConVarFloat(model2snd), Model2, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (GetConVarInt(model3) == 1) {
	CreateTimer(GetConVarFloat(model3snd), Model3, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (GetConVarInt(model4) == 1) {
	CreateTimer(GetConVarFloat(model4snd), Model4, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (GetConVarInt(model5) == 1) {
	CreateTimer(GetConVarFloat(model5snd), Model5, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (GetConVarInt(model6) == 1) {
	CreateTimer(GetConVarFloat(model6snd), Model6, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Timer Teams
	if (GetConVarInt(modelT) == 1) {
	CreateTimer(GetConVarFloat(modelTsnd), TeamT, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (GetConVarInt(modelCT) == 1) {
	CreateTimer(GetConVarFloat(modelCTsnd), TeamCT, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:TeamCT(Handle:timer)
{
	decl String:sSndPathCT[PLATFORM_MAX_PATH];
	GetConVarString(modelCTsndpath, sSndPathCT, sizeof(sSndPathCT));
    	for(new client = 1; client <= MaxClients; client++)
    	{
		if(IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client))
		{
			decl Float:iVecg[3];
			GetClientAbsOrigin( client, Float:iVecg );
			EmitSoundToAll(sSndPathCT, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(modelvolume), SNDPITCH_NORMAL, -1, iVecg);

		}
   	}
}

public Action:TeamT(Handle:timer)
{
	decl String:sSndPathT[PLATFORM_MAX_PATH];
	GetConVarString(modelTsndpath, sSndPathT, sizeof(sSndPathT));
    	for(new client = 1; client <= MaxClients; client++)
    	{
		if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			decl Float:iVecg[3];
			GetClientAbsOrigin( client, Float:iVecg );
			EmitSoundToAll(sSndPathT, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(modelvolume), SNDPITCH_NORMAL, -1, iVecg);

		}
   	}
}

public Action:Model1(Handle:timer)
{
	decl String:model[PLATFORM_MAX_PATH], String:sModel1path[PLATFORM_MAX_PATH], String:sSndPath1[PLATFORM_MAX_PATH];
	
	GetConVarString(model1path, sModel1path, sizeof(sModel1path));
	GetConVarString(model1sndpath, sSndPath1, sizeof(sSndPath1));
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetClientModel(client, model, sizeof(model))

			if (StrEqual(model, sModel1path))
			{
				decl Float:iVecg[3];
				GetClientAbsOrigin( client, iVecg );
				EmitSoundToAll(sSndPath1, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(modelvolume), SNDPITCH_NORMAL, -1, iVecg);
			}
		}
	}
}

public Action:Model2(Handle:timer)
{
	decl String:model[PLATFORM_MAX_PATH], String:sModel2path[PLATFORM_MAX_PATH], String:sSndPath2[PLATFORM_MAX_PATH];
	
	GetConVarString(model2path, sModel2path, sizeof(sModel2path));
	GetConVarString(model2sndpath, sSndPath2, sizeof(sSndPath2));
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetClientModel(client, model, sizeof(model))

			if (StrEqual(model, sModel2path))
			{
				decl Float:iVecg[3];
				GetClientAbsOrigin( client, iVecg );
				EmitSoundToAll(sSndPath2, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(modelvolume), SNDPITCH_NORMAL, -1, iVecg);
			}
		}
	}
}

public Action:Model3(Handle:timer)
{
	decl String:model[PLATFORM_MAX_PATH], String:sModel3path[PLATFORM_MAX_PATH], String:sSndPath3[PLATFORM_MAX_PATH];
	
	GetConVarString(model3path, sModel3path, sizeof(sModel3path));
	GetConVarString(model3sndpath, sSndPath3, sizeof(sSndPath3));
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetClientModel(client, model, sizeof(model))

			if (StrEqual(model, sModel3path))
			{
				decl Float:iVecg[3];
				GetClientAbsOrigin( client, iVecg );
				EmitSoundToAll(sSndPath3, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(modelvolume), SNDPITCH_NORMAL, -1, iVecg);
			}
		}
	}
}

public Action:Model4(Handle:timer)
{
	decl String:model[PLATFORM_MAX_PATH], String:sModel4path[PLATFORM_MAX_PATH], String:sSndPath4[PLATFORM_MAX_PATH];
	
	GetConVarString(model4path, sModel4path, sizeof(sModel4path));
	GetConVarString(model4sndpath, sSndPath4, sizeof(sSndPath4));
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetClientModel(client, model, sizeof(model))

			if (StrEqual(model, sModel4path))
			{
				decl Float:iVecg[3];
				GetClientAbsOrigin( client, iVecg );
				EmitSoundToAll(sSndPath4, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(modelvolume), SNDPITCH_NORMAL, -1, iVecg);
			}
		}
	}
}

public Action:Model5(Handle:timer)
{
	decl String:model[PLATFORM_MAX_PATH], String:sModel5path[PLATFORM_MAX_PATH], String:sSndPath5[PLATFORM_MAX_PATH];
	
	GetConVarString(model5path, sModel5path, sizeof(sModel5path));
	GetConVarString(model5sndpath, sSndPath5, sizeof(sSndPath5));
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetClientModel(client, model, sizeof(model))

			if (StrEqual(model, sModel5path))
			{
				decl Float:iVecg[3];
				GetClientAbsOrigin( client, iVecg );
				EmitSoundToAll(sSndPath5, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(modelvolume), SNDPITCH_NORMAL, -1, iVecg);
			}
		}
	}
}

public Action:Model6(Handle:timer)
{
	decl String:model[PLATFORM_MAX_PATH], String:sModel6path[PLATFORM_MAX_PATH], String:sSndPath6[PLATFORM_MAX_PATH];
	
	GetConVarString(model6path, sModel6path, sizeof(sModel6path));
	GetConVarString(model6sndpath, sSndPath6, sizeof(sSndPath6));
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetClientModel(client, model, sizeof(model))

			if (StrEqual(model, sModel6path))
			{
				decl Float:iVecg[3];
				GetClientAbsOrigin( client, iVecg );
				EmitSoundToAll(sSndPath6, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(modelvolume), SNDPITCH_NORMAL, -1, iVecg);
			}
		}
	}
}