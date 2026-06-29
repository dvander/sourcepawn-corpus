#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

new Handle:g_hEnabled;
new Handle:g_hNumberSounds;
new Handle:g_hFilePrefix = INVALID_HANDLE;

new bool:g_bEnabled;
new g_iNumberSounds;
new String:g_iFilePrefix[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "Shred Alert Alternate Sounds",
	author = "frog",
	description = "Plays a random sound in place of the default Shred Alert sound",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	CreateConVar("sm_shredalternate_version", PLUGIN_VERSION, "Shred Alternate Sound Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);

	g_hEnabled = CreateConVar("sm_shredalternate_enabled", "1", "0 = Disable plugin, 1 = Enable plugin");
	HookConVarChange(g_hEnabled, ConVarEnabledChanged);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	g_hNumberSounds = CreateConVar("sm_shredalternate_numbersounds", "26", "The number of alternate shred sounds");
	HookConVarChange(g_hNumberSounds, ConVarNumberSoundsChanged);
	g_iNumberSounds = GetConVarInt(g_hNumberSounds);
	
	g_hFilePrefix = CreateConVar("sm_shredalternate_fileprefix", "shred", "Filename prefix for alternate shred alert sounds");
	HookConVarChange(g_hFilePrefix, ConVarFilePrefixChanged);
	GetConVarString(g_hFilePrefix, g_iFilePrefix, sizeof(g_iFilePrefix));

	AutoExecConfig(true, "plugin.shredalternate");
	
	AddNormalSoundHook(SHook);
}

public OnMapStart()
{
	new String:sound[70];
	for (new x = 1 ; x <= g_iNumberSounds ; x++) 
	{
		Format(sound, sizeof(sound), "sound/shredalternate/%s%i.mp3",g_iFilePrefix,x);
		AddFileToDownloadsTable(sound);
		Format(sound, sizeof(sound), "shredalternate/%s%i.mp3",g_iFilePrefix,x);
		PrecacheSound(sound, true);
	}
}

public Action:SHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags) 
{
	if(g_bEnabled)
	{
		if (StrContains(sound, "brutal_legend_taunt", false) > -1 )
		{
			new rand = GetRandomInt(1, g_iNumberSounds);
			Format(sound, sizeof(sound), "shredalternate/%s%i.mp3",g_iFilePrefix,rand);
			EmitSoundToClient(Ent, sound);
			return Plugin_Changed;
    		}
    	}
	return Plugin_Continue;
} 


public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = (StringToInt(newvalue) != 0);
}

public ConVarNumberSoundsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iNumberSounds = StringToInt(newvalue);
}

public ConVarFilePrefixChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, g_iFilePrefix, sizeof(g_iFilePrefix));
	
	new String:sound[70];
	for (new x = 1 ; x <= g_iNumberSounds ; x++) 
	{
		Format(sound, sizeof(sound), "shredalternate/%s%i.mp3",g_iFilePrefix,x);
		PrecacheSound(sound, true);
	}
}
