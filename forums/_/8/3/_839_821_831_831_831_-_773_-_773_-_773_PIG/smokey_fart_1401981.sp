#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

#define TEAM_T 2
#define TEAM_CT 3

#define fart		"smokeyfart/smokeyfart.mp3"

new Handle:cfg_smoke_enable = INVALID_HANDLE;
new Handle:cfg_smoke_terrorist = INVALID_HANDLE;
new Handle:cfg_smoke_counter = INVALID_HANDLE;
new Handle:cfg_smoke_times = INVALID_HANDLE;
new Handle:cfg_smoke_delay = INVALID_HANDLE;
new Handle:cfg_smoke_fadestart = INVALID_HANDLE;
new Handle:cfg_smoke_fadeend = INVALID_HANDLE;
new Handle:cfg_smoke_sound = INVALID_HANDLE;

new g_SmokeCount[MAXPLAYERS+2] = {0,...};
new bool:g_bSmokeTimeout[MAXPLAYERS+1];
new bool:v_fartsound;
new bool:g_bEnable_Smoke = true;

public Plugin:myinfo = 
{
		name = "Smokey Farts",
		author = "MR.PIG and Silvers",
		description = "Smokey Fart people",
		version = PLUGIN_VERSION,
		url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_poof_version", PLUGIN_VERSION, "Poof", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	cfg_smoke_enable = 		CreateConVar("sm_enable_smoke", "1", "Enables the smoke?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cfg_smoke_terrorist = 	CreateConVar("sm_smoke_terrorist", "1", "Terrorists can smoke?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cfg_smoke_counter = 	CreateConVar("sm_smoke_counter", "0", "Counter Terrorists can smoke?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cfg_smoke_times = 		CreateConVar("sm_smoke_times", "5", "How many times can you smoke per round?", FCVAR_PLUGIN, true, 0.00, true, 20.00);
	cfg_smoke_delay =		CreateConVar("sm_smoke_delay", "5.0", "How long after a smoke can you poof again?.", FCVAR_PLUGIN, true, 1.00, true, 60.00);
	cfg_smoke_fadestart =	CreateConVar("sm_smoke_fadestart", "10.0", "Fadestart is how many seconds after emission to start fading out.", FCVAR_PLUGIN, true, 1.00, true, 30.00);
	cfg_smoke_fadeend =		CreateConVar("sm_smoke_fadeend", "15.0", "Fadeend is how many seconds after emission the smoke completely clears.", FCVAR_PLUGIN, true, 1.00, true, 30.00);
	cfg_smoke_sound = 		CreateConVar("sm_smoke_sound", "1", "Enable fart sound?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_bEnable_Smoke = GetConVarBool(cfg_smoke_enable);
	HookConVarChange(cfg_smoke_enable, Cfg_OnChangeenable);
	if(g_bEnable_Smoke)
	{
		HookEvent("player_spawn", Event_OnPlayerspawn);
	}
	RegConsoleCmd("sm_smoke", Command_Say);	

	AutoExecConfig(true, "smokey_fart");
	
	LoadResources();
}

public OnMapStart()
{
	LoadResources();
}

LoadResources()
{
	v_fartsound = GetConVarBool(cfg_smoke_sound);
	
	if(v_fartsound)
	{
		PrecacheSound(fart, true);
		
		AddFolderToDownloadsTable("sound/smokeyfart");
	}
}

public Action:Event_OnPlayerspawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnable_Smoke)
		return;

	new cvarSmokeTimes = GetConVarInt(cfg_smoke_times);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	new cvarTSmoke = GetConVarInt(cfg_smoke_terrorist);
	new cvarCTSmoke = GetConVarInt(cfg_smoke_counter);
	g_SmokeCount[client] = 0;
	new team = GetClientTeam(client);

	if((team == TEAM_T || team == TEAM_CT) && (cvarTSmoke == 1 || cvarCTSmoke == 1))
	{
		PrintToChat(client, "Say !smoke to escape from the seeker!");
		PrintToChat(client, "You have %d smokey farts!", (cvarSmokeTimes));
	}
}

public Action:Command_Smoke(client, args)
{
	CommandSmoke(client);
	return Plugin_Handled;
}

public Action:Command_Say(client, args)
{
	CommandSmoke(client);
	return Plugin_Handled;
}

bool:CommandSmoke(client)
{
	if((!g_bEnable_Smoke || !GetConVarBool(cfg_smoke_enable) || !IsPlayerAlive(client)))
		return false;
	
	if(g_bSmokeTimeout[client] == true)
	{
		PrintToChat(client, "There is a %.0f second smokey fart delay", (GetConVarFloat(cfg_smoke_delay)));
		return false;
	}
	new cvarTSmoke = GetConVarInt(cfg_smoke_terrorist);
	new cvarCTSmoke = GetConVarInt(cfg_smoke_counter);
	new cvarSmokeTimes = GetConVarInt(cfg_smoke_times);
	if(!IsFakeClient(client) && (GetClientTeam(client) == TEAM_T && cvarTSmoke == 1) || (GetClientTeam(client) == TEAM_CT && cvarCTSmoke == 1))
		{
		if(g_SmokeCount[client] < cvarSmokeTimes)
			{
				CreateTimer(GetConVarFloat(cfg_smoke_delay), tmrTimeout, GetClientUserId(client));                   
				g_bSmokeTimeout[client] = true;
				new Float:vec[3];
				GetClientAbsOrigin(client, Float:vec);
				new Float:fadestart = GetConVarFloat(cfg_smoke_fadestart);
				new Float:fadeend = GetConVarFloat(cfg_smoke_fadeend);

				new SmokeIndex = CreateEntityByName("env_particlesmokegrenade");
				if (SmokeIndex != -1)
				{
					SetEntProp(SmokeIndex, Prop_Send, "m_CurrentStage", 1);
					SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeStartTime", fadestart);
					SetEntPropFloat(SmokeIndex, Prop_Send, "m_FadeEndTime", fadeend);
					DispatchSpawn(SmokeIndex);
					ActivateEntity(SmokeIndex);
					TeleportEntity(SmokeIndex, vec, NULL_VECTOR, NULL_VECTOR);
					
					g_SmokeCount[client]++;
					
					if(v_fartsound)
						{
						EmitSoundToAll(fart, client, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
						}	
					PrintToChat(client, "%d smokey farts left", (cvarSmokeTimes-g_SmokeCount[client]));
					return true;
				}
			}
		PrintToChat(client, "Smokey fart limit exceeded", cvarSmokeTimes);   
		return false;
	}
	PrintToChat(client, "You are not allowed to release a smokey poof");
	return true;
}  

public Cfg_OnChangeenable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StrEqual(oldValue, newValue))
		return;

	if(StrEqual(newValue, "0"))
	{
		UnhookEvent("player_spawn", Event_OnPlayerspawn);
		g_bEnable_Smoke = false;
	}

	if(StrEqual(newValue, "1"))
	{
		HookEvent("player_spawn", Event_OnPlayerspawn);
		new client = GetClientUserId(client);
		g_SmokeCount[client] = 0;
		g_bEnable_Smoke = true;
	}
}
public Action:tmrTimeout(Handle:timer, any:client)
{
	client = GetClientOfUserId(client)
    	if(client && IsClientInGame(client))
    		g_bSmokeTimeout[client] = false;
}  

stock AddFolderToDownloadsTable(const String:sDirectory[])
{
	decl String:sFile[64], String:sPath[512];
	new FileType:iType, Handle:hDir = OpenDirectory(sDirectory);
	while(ReadDirEntry(hDir, sFile, sizeof(sFile), iType))     
	{
		if(iType == FileType_File)
		{
			Format(sPath, sizeof(sPath), "%s/%s", sDirectory, sFile);
			AddFileToDownloadsTable(sPath);
		}
	}
}